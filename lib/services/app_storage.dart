import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _avatarPathKey = 'gr.avatar_path';
  static const _displayNameKey = 'gr.display_name';

  late SharedPreferences _plain;

  Future<void> bootstrap() async {
    _plain = await SharedPreferences.getInstance();
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
}
