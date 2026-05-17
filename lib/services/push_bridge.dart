import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads cold-start push URLs that SceneDelegate captured before any Dart
/// code was alive.
class PushBridge {
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
