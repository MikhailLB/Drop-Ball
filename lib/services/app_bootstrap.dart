import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'browser_http.dart';
import 'local_store.dart';

/// Heavy first-launch bootstrap. Pulled out of `main()` so we can
/// render the branded splash before paying the cold-start cost of
/// Firebase, App Check, device probing and SharedPreferences.
Future<void> appBootstrap(LocalStore store) async {
  await Future.wait([
    _safeFirebase(),
    browserHttp.bootstrap(),
    store.bootstrap(),
  ]);
}

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
