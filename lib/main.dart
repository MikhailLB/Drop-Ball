import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/attribution_gateway.dart';
import 'services/browser_http.dart';
import 'services/cloud_push_client.dart';
import 'services/config_api.dart';
import 'services/local_store.dart';
import 'services/network_monitor.dart';

Future<void> _safeFirebase() async {
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (_) {}
}

Future<void> _configureChrome() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _safeFirebase();
  await _configureChrome();
  await browserHttp.bootstrap();

  final store = LocalStore();
  await store.bootstrap();

  final net = NetworkMonitor();
  final attribution = AttributionGateway();
  final config = ConfigApi(store);
  final push = CloudPushClient(store);

  runApp(GravityRushApp(
    store: store,
    net: net,
    attribution: attribution,
    config: config,
    push: push,
  ));
}
