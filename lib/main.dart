import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'root_app.dart';
import 'flow/cfg/route_vault.dart';
import 'flow/cfg/signal_data.dart';
import 'flow/infra/attribution_beacon.dart';
import 'flow/infra/data_vault.dart';
import 'flow/infra/http_shield.dart';
import 'flow/infra/net_probe.dart';
import 'flow/infra/notify_relay.dart';
import 'flow/infra/route_dispatch.dart';

// ORDER MATTERS:
//   1. WidgetsFlutterBinding.ensureInitialized()
//   2. Firebase.initializeApp() + FirebaseAppCheck.activate()
//   3. httpShield.warmup() + DataVault.init() in parallel
//   4. runApp(NeonFlowApp(...))
//
// Firebase must be initialized ONCE here — re-calling raises [core/duplicate-app].

Future<void> _bootFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (err) {
    debugPrint('[DB.BOOT] Firebase init skipped: $err');
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (err) {
    debugPrint('[DB.BOOT] AppCheck skipped: $err');
  }
}

Future<void> main() async {
  final sw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final firebaseFuture = _bootFirebase();
  final agentFuture    = httpShield.warmup();
  final vault          = DataVault();
  final vaultFuture    = vault.init().catchError((err) {
    debugPrint('[DB.BOOT] vault init failed: $err');
  });

  await firebaseFuture;
  debugPrint('[DB.BOOT] firebase ready ${sw.elapsedMilliseconds}ms');
  await Future.wait([agentFuture, vaultFuture]);
  debugPrint('[DB.BOOT] agent+vault ready ${sw.elapsedMilliseconds}ms');

  final probe    = NetProbe();
  final signal   = AttributionBeacon();
  final dispatch = RouteDispatch(vault);
  final pulse    = NotifyRelay(vault);

  // Pre-fire push bootstrap in parallel with first frame render
  unawaited(pulse.bootstrap().catchError((err) {
    debugPrint('[DB.BOOT] pulse pre-fire: $err');
  }));

  // Gate enabled when at least one credential is provisioned.
  // With empty byte arrays (before keys are filled) this returns false
  // and the app shows the Drop Ball game directly — no crash.
  final gateEnabled =
      routeEndpointUrl().isNotEmpty || appsflyerKey().isNotEmpty;

  debugPrint('[DB.BOOT] gateEnabled=$gateEnabled  ${sw.elapsedMilliseconds}ms');

  runApp(NeonFlowApp(
    vault: vault,
    probe: probe,
    signal: signal,
    dispatch: dispatch,
    pulse: pulse,
    gateEnabled: gateEnabled,
  ));
}
