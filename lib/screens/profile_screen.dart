import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight profile screen. Lets the player pick an avatar from the
/// system Photo Library and edit a display name. The avatar file is
/// copied to the app's Documents directory so it survives the picker's
/// temp-cache cleanup, and its path is persisted in SharedPreferences.
///
/// On iOS the picker uses PHPicker under the hood, so no runtime
/// permission prompt is shown to the user even though the app declares
/// NSPhotoLibraryUsageDescription for the reviewer.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _avatarKey = 'gr.avatar_path';
  static const _nameKey = 'gr.display_name';

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameCtrl = TextEditingController();

  String? _avatarPath;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_avatarKey);
    final name = prefs.getString(_nameKey) ?? 'Player';
    if (!mounted) return;
    setState(() {
      _avatarPath = (path != null && File(path).existsSync()) ? path : null;
      _nameCtrl.text = name;
    });
  }

  Future<void> _pickAvatar() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final docs = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last.toLowerCase();
      final safeExt = (ext.length <= 4) ? ext : 'jpg';
      final dest = File(
        '${docs.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt',
      );
      await File(picked.path).copy(dest.path);

      // Cleanup any previous avatar so Documents doesn't grow unbounded.
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getString(_avatarKey);
      if (old != null && old != dest.path) {
        try {
          final f = File(old);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      await prefs.setString(_avatarKey, dest.path);

      if (!mounted) return;
      setState(() => _avatarPath = dest.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load image: $e'),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _removeAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString(_avatarKey);
    if (old != null) {
      try {
        final f = File(old);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      await prefs.remove(_avatarKey);
    }
    if (!mounted) return;
    setState(() => _avatarPath = null);
  }

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Player'
        : _nameCtrl.text.trim();
    await prefs.setString(_nameKey, name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.cyanAccent,
        elevation: 0,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(child: _buildAvatar()),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  onPressed: _picking ? null : _pickAvatar,
                  icon: const Icon(Icons.photo_library_outlined,
                      color: Colors.cyanAccent),
                  label: Text(
                    _avatarPath == null ? 'CHOOSE AVATAR' : 'CHANGE AVATAR',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              if (_avatarPath != null)
                Center(
                  child: TextButton(
                    onPressed: _removeAvatar,
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              const Text(
                'DISPLAY NAME',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                maxLength: 20,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.cyanAccent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  counterStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.cyanAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.18),
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'SAVE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final size = 140.0;
    final hasImage = _avatarPath != null && File(_avatarPath!).existsSync();

    return GestureDetector(
      onTap: _picking ? null : _pickAvatar,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.cyanAccent, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.cyanAccent, blurRadius: 24),
          ],
          color: Colors.white.withValues(alpha: 0.04),
          image: hasImage
              ? DecorationImage(
                  image: FileImage(File(_avatarPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? null
            : Icon(
                Icons.person,
                size: size * 0.55,
                color: Colors.cyanAccent.withValues(alpha: 0.6),
              ),
      ),
    );
  }
}
