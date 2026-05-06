import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads cold-start push URLs that SceneDelegate captured before any Dart
/// code was alive.
///
/// On iOS 13+ scene-based Flutter apps, a notification tap that launches the
/// app from killed state is delivered to the SceneDelegate via
/// `connectionOptions.notificationResponse` — NOT to the AppDelegate's
/// `launchOptions[remoteNotification]`. Firebase Messaging's swizzle only
/// reads `launchOptions`, so `getInitialMessage()` returns null for cold-start
/// taps. This is firebase/flutterfire#8896, unfixed upstream.
///
/// `SceneDelegate.swift` works around this by extracting the URL from
/// `notificationResponse.notification.request.content.userInfo` and writing
/// it into `UserDefaults.standard` under `flutter.gr_native_cold_start_url`.
/// The `flutter.` prefix matches the namespace the Flutter `shared_preferences`
/// plugin uses on iOS, so a Swift `UserDefaults.set(_:forKey:)` is exactly
/// equivalent to a Dart `SharedPreferences.setString(...)`. No MethodChannel
/// registration timing race possible.
class NativePushBridge {
  static const String _key = 'gr_native_cold_start_url';

  /// Returns the URL captured by [SceneDelegate] on cold-start tap (if any)
  /// and atomically clears it from UserDefaults so it isn't replayed on the
  /// next launch. Safe to call on any platform — returns null on non-iOS.
  static Future<String?> consumeColdStartUrl() async {
    if (!Platform.isIOS) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) {
        debugPrint('[GR.NATIVE] consumeColdStartUrl -> null');
        return null;
      }
      await prefs.remove(_key);
      debugPrint('[GR.NATIVE] consumeColdStartUrl -> $raw');
      return raw.trim();
    } catch (err) {
      debugPrint('[GR.NATIVE] consumeColdStartUrl failed: $err');
      return null;
    }
  }
}
