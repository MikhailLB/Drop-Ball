import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skin_data.dart';
import '../utils/asset_paths.dart';
import 'in_app_web_page.dart';

class MainMenuScreen extends StatefulWidget {
  final void Function(SkinData skin) onPlay;

  const MainMenuScreen({super.key, required this.onPlay});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  int _selectedSkinIndex = 0;
  int _balance = 0;
  Set<String> _unlockedSkins = {'blue'};
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
      _balance = prefs.getInt('balance') ?? 0;
      final raw = prefs.getString('unlocked_skins') ?? 'blue';
      _unlockedSkins = raw.split(',').toSet();
      final savedSkin = prefs.getString('selected_skin') ?? 'blue';
      _selectedSkinIndex = SkinData.allSkins
          .indexWhere((s) => s.id == savedSkin)
          .clamp(0, SkinData.allSkins.length - 1);
      if (!_unlockedSkins.contains(SkinData.allSkins[_selectedSkinIndex].id)) {
        _selectedSkinIndex = 0;
      }
    });
  }

  Future<void> _saveSkinSelection(String skinId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_skin', skinId);
  }

  Future<void> _buySkin(SkinData skin) async {
    if (_balance < skin.price) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance -= skin.price;
      _unlockedSkins.add(skin.id);
    });
    await prefs.setInt('balance', _balance);
    await prefs.setString('unlocked_skins', _unlockedSkins.join(','));
  }

  void _onSkinTap(int index) {
    final skin = SkinData.allSkins[index];
    final isUnlocked = _unlockedSkins.contains(skin.id);

    if (isUnlocked) {
      setState(() => _selectedSkinIndex = index);
      _saveSkinSelection(skin.id);
    } else if (_balance >= skin.price) {
      _showBuyDialog(skin, index);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${SkinData.formatPrice(skin.price)} coins',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showBuyDialog(SkinData skin, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'BUY ${skin.name.toUpperCase()}?',
          style: TextStyle(color: skin.primaryColor, letterSpacing: 2),
        ),
        content: Text(
          'Cost: ${SkinData.formatPrice(skin.price)} coins\n'
          'Balance: ${SkinData.formatPrice(_balance)}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _buySkin(skin);
              setState(() => _selectedSkinIndex = index);
              _saveSkinSelection(skin.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: skin.primaryColor.withValues(alpha: 0.3),
              foregroundColor: skin.primaryColor,
            ),
            child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            Image.asset(AssetPaths.logo, width: 140, height: 140),
            const SizedBox(height: 10),
            const Text(
              'GRAVITY RUSH',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'BALANCE: ${SkinData.formatPrice(_balance)}',
              style: TextStyle(
                color: Colors.greenAccent.withValues(alpha: 0.7),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SHOP',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _linkButton('Privacy Policy',
                    'https://gravittyrush.com/privacy-policy.html'),
                const SizedBox(width: 20),
                _linkButton(
                    'Support', 'https://gravittyrush.com/support.html'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _linkButton(String label, String url) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InAppWebPage(title: label, url: url),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 12,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildSkinSelector(SkinData selected) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: SkinData.allSkins.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final skin = SkinData.allSkins[index];
          final isSelected = index == _selectedSkinIndex;
          final isUnlocked = _unlockedSkins.contains(skin.id);
          final canAfford = _balance >= skin.price;

          return GestureDetector(
            onTap: () => _onSkinTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 92,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? skin.primaryColor
                      : isUnlocked
                          ? Colors.white24
                          : Colors.white10,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? skin.primaryColor.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.03),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: skin.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: isUnlocked ? 1.0 : 0.3,
                        child: Image.asset(skin.assetPath,
                            width: 46, height: 46),
                      ),
                      if (!isUnlocked)
                        Icon(
                          Icons.lock,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 22,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    skin.name,
                    style: TextStyle(
                      color: isUnlocked
                          ? (isSelected ? skin.primaryColor : Colors.white60)
                          : Colors.white30,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isUnlocked)
                    Text(
                      skin.tier.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? skin.primaryColor.withValues(alpha: 0.7)
                            : Colors.white30,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    )
                  else
                    Text(
                      SkinData.formatPrice(skin.price),
                      style: TextStyle(
                        color: canAfford
                            ? Colors.greenAccent.withValues(alpha: 0.8)
                            : Colors.redAccent.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
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
