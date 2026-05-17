import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'web_client.dart';
import 'app_storage.dart';

Future<void> runStartup(AppStorage store) async {
  await Future.wait([
    _safeFirebase(),
    webClient.bootstrap(),
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
