import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads the cold-start push URL that SceneDelegate captured before Dart
/// code was alive.
///
/// On iOS scene-based apps, tapping a push while the app is killed routes
/// through SceneDelegate.scene(_:willConnectTo:options:) — NOT through
/// Firebase's swizzled AppDelegate path. SceneDelegate writes the URL to
/// UserDefaults under `flutter.db_flow_tap_url`. The `flutter.` prefix is
/// required: SharedPreferences on iOS namespaces keys with it automatically.
class ColdTapReader {
  static const String _key = 'db_flow_tap_url';

  /// Returns and clears the URL left by SceneDelegate on cold-start tap.
  /// Returns null on non-iOS or when no URL is stored.
  static Future<String?> consumeTapUrl() async {
    if (!Platform.isIOS) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) {
        debugPrint('[DB.NATIVE] consumeTapUrl -> null');
        return null;
      }
      await prefs.remove(_key);
      debugPrint('[DB.NATIVE] consumeTapUrl -> "$raw"');
      return raw.trim();
    } catch (err) {
      debugPrint('[DB.NATIVE] consumeTapUrl failed: $err');
      return null;
    }
  }
}
