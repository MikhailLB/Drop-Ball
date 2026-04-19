import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skin_data.dart';
import '../utils/asset_paths.dart';

class MainMenuScreen extends StatefulWidget {
  final void Function(SkinData skin) onPlay;

  const MainMenuScreen({super.key, required this.onPlay});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  int _selectedSkinIndex = 0;
  int _highScore = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('high_score') ?? 0;
      final savedSkin = prefs.getString('selected_skin') ?? 'blue';
      _selectedSkinIndex = SkinData.allSkins
          .indexWhere((s) => s.id == savedSkin)
          .clamp(0, SkinData.allSkins.length - 1);
    });
  }

  Future<void> _saveSkinSelection(String skinId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_skin', skinId);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSkin = SkinData.allSkins[_selectedSkinIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Image.asset(AssetPaths.logo, width: 160, height: 160),
            const SizedBox(height: 10),
            const Text(
              'GRAVITY RUSH',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                shadows: [
                  Shadow(color: Colors.cyanAccent, blurRadius: 20),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_highScore > 0)
              Text(
                'BEST: $_highScore',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            const Spacer(),
            _buildSkinSelector(selectedSkin),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              ),
              child: _buildPlayButton(selectedSkin),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinSelector(SkinData selected) {
    return Column(
      children: [
        Text(
          'SELECT SKIN',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: SkinData.allSkins.length,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemBuilder: (context, index) {
              final skin = SkinData.allSkins[index];
              final isSelected = index == _selectedSkinIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedSkinIndex = index);
                  _saveSkinSelection(skin.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? skin.primaryColor : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? skin.primaryColor.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    boxShadow: isSelected
                        ? [BoxShadow(color: skin.primaryColor.withValues(alpha: 0.4), blurRadius: 16)]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(skin.assetPath, width: 50, height: 50),
                      const SizedBox(height: 8),
                      Text(
                        skin.name,
                        style: TextStyle(
                          color: isSelected ? skin.primaryColor : Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        skin.tier.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? skin.primaryColor.withValues(alpha: 0.7)
                              : Colors.white30,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(SkinData skin) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton(
        onPressed: () => widget.onPlay(skin),
        style: ElevatedButton.styleFrom(
          backgroundColor: skin.primaryColor.withValues(alpha: 0.2),
          foregroundColor: skin.primaryColor,
          side: BorderSide(color: skin.primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'PLAY',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
            shadows: [Shadow(color: skin.primaryColor, blurRadius: 15)],
          ),
        ),
      ),
    );
  }
}
