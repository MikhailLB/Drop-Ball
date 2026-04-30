import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/runtime_mode.dart';

class LocalStore {
  static const _runtimeModeKey = 'gr.runtime_mode';
  static const _urlSecretKey = 'gr.cached_target';
  static const _urlExpireKey = 'gr.target_ttl';
  static const _pushCooldownKey = 'gr.push_cooldown_until';
  static const _pushConsentKey = 'gr.push_consent';
  static const _pushTargetKey = 'gr.push_target';
  static const _avatarPathKey = 'gr.avatar_path';
  static const _displayNameKey = 'gr.display_name';

  late SharedPreferences _plain;
  final FlutterSecureStorage _vault = const FlutterSecureStorage();

  Future<void> bootstrap() async {
    _plain = await SharedPreferences.getInstance();
  }

  RuntimeMode readRuntimeMode() =>
      RuntimeMode.parse(_plain.getString(_runtimeModeKey));

  Future<void> writeRuntimeMode(RuntimeMode mode) async {
    await _plain.setString(_runtimeModeKey, mode.toStoreString());
  }

  Future<String?> readCachedTarget() => _vault.read(key: _urlSecretKey);

  Future<void> writeCachedTarget(String url) =>
      _vault.write(key: _urlSecretKey, value: url);

  int? _readExpire() => _plain.getInt(_urlExpireKey);

  Future<void> writeTargetExpire(int epochSeconds) async {
    await _plain.setInt(_urlExpireKey, epochSeconds);
  }

  bool isCachedTargetStale() {
    final expires = _readExpire();
    if (expires == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expires;
  }

  bool readPushConsent() => _plain.getBool(_pushConsentKey) ?? false;

  Future<void> writePushConsent(bool allowed) async {
    await _plain.setBool(_pushConsentKey, allowed);
  }

  int? readPushCooldown() => _plain.getInt(_pushCooldownKey);

  Future<void> writePushCooldown(int epochSeconds) async {
    await _plain.setInt(_pushCooldownKey, epochSeconds);
  }

  bool needsPushPrompt() {
    if (readPushConsent()) return false;
    final cooldown = readPushCooldown();
    if (cooldown == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= cooldown;
  }

  Future<String?> peekPushTarget() => _vault.read(key: _pushTargetKey);

  Future<void> writePushTarget(String? url) async {
    if (url == null) {
      await _vault.delete(key: _pushTargetKey);
    } else {
      await _vault.write(key: _pushTargetKey, value: url);
    }
  }

  String? readAvatarPath() => _plain.getString(_avatarPathKey);

  Future<void> writeAvatarPath(String? path) async {
    if (path == null) {
      await _plain.remove(_avatarPathKey);
    } else {
      await _plain.setString(_avatarPathKey, path);
    }
  }

  String readDisplayName() => _plain.getString(_displayNameKey) ?? 'Player';

  Future<void> writeDisplayName(String name) async {
    await _plain.setString(_displayNameKey, name);
  }

  Future<String?> takePushTarget() async {
    final url = await _vault.read(key: _pushTargetKey);
    if (url != null) {
      await _vault.delete(key: _pushTargetKey);
    }
    return url;
  }
}
