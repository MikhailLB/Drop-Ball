import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/orb_skin.dart';
import '../utils/asset_paths.dart';
import 'profile_screen.dart';

class ShopScreen extends StatefulWidget {
  final void Function(OrbSkin skin) onPlay;
  const ShopScreen({super.key, required this.onPlay});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  int _sel = 0;
  int _wallet = 0;
  Set<String> _owned = {'frost'};
  String? _avatarPath;
  // _playerName reserved for future profile display
  late AnimationController _pulse;
  late Animation<double> _pAnim;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pAnim = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final av = p.getString('gr.avatar_path');
    setState(() {
      _wallet = p.getInt('db_wallet') ?? 0;
      _owned  = (p.getString('owned_orbs') ?? 'frost').split(',').toSet();
      final saved = p.getString('active_orb') ?? 'frost';
      _sel = OrbSkin.catalog.indexWhere((s) => s.id == saved).clamp(0, OrbSkin.catalog.length - 1);
      if (!_owned.contains(OrbSkin.catalog[_sel].id)) _sel = 0;
      _avatarPath = (av != null && File(av).existsSync()) ? av : null;
    });
  }

  Future<void> _saveSelection(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('active_orb', id);
  }

  Future<void> _purchase(OrbSkin skin, int idx) async {
    if (_wallet < skin.cost) return;
    final p = await SharedPreferences.getInstance();
    setState(() { _wallet -= skin.cost; _owned.add(skin.id); });
    await p.setInt('db_wallet', _wallet);
    await p.setString('owned_orbs', _owned.join(','));
  }

  void _tap(int idx) {
    final s = OrbSkin.catalog[idx];
    if (_owned.contains(s.id)) {
      setState(() => _sel = idx);
      _saveSelection(s.id);
    } else if (_wallet >= s.cost) {
      _showBuy(s, idx);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Need ${OrbSkin.formatCost(s.cost)} coins', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  void _showBuy(OrbSkin s, int idx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('GET ${s.label.toUpperCase()}?',
            style: TextStyle(color: s.glowColor, letterSpacing: 2)),
        content: Text(
          'Cost: ${OrbSkin.formatCost(s.cost)}\nBalance: ${OrbSkin.formatCost(_wallet)}',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _purchase(s, idx);
              setState(() => _sel = idx);
              _saveSelection(s.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: s.glowColor.withValues(alpha: 0.25), foregroundColor: s.glowColor,
            ),
            child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final active = OrbSkin.catalog[_sel];
    return Scaffold(
      backgroundColor: const Color(0xFF08091A),
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          Expanded(child: _body(active)),
          _bottomBar(active),
        ]),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        // Logo mark
        Image.asset(AssetPaths.logoMark, width: 36, height: 36, fit: BoxFit.contain),
        const SizedBox(width: 10),
        const Text('DROP BALL', style: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3,
        )),
        const Spacer(),
        // Wallet chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(OrbSkin.formatCost(_wallet),
                style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(width: 8),
        // Profile
        GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            _loadPrefs();
          },
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyanAccent.withValues(alpha: 0.12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
              image: (_avatarPath != null)
                  ? DecorationImage(image: FileImage(File(_avatarPath!)), fit: BoxFit.cover)
                  : null,
            ),
            child: (_avatarPath == null)
                ? const Icon(Icons.person, size: 20, color: Colors.cyanAccent)
                : null,
          ),
        ),
      ]),
    );
  }

  // ── Middle body ───────────────────────────────────────────────────────────
  Widget _body(OrbSkin active) {
    return Column(children: [
      const SizedBox(height: 18),
      // Hero — selected orb showcase
      _heroOrb(active),
      const SizedBox(height: 16),
      // Orb name + rarity
      Text(active.label.toUpperCase(), style: TextStyle(
        color: active.glowColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3,
        shadows: [Shadow(color: active.glowColor, blurRadius: 14)],
      )),
      const SizedBox(height: 4),
      Text(_rarityLabel(active.rarity), style: TextStyle(
        color: active.glowColor.withValues(alpha: 0.6), fontSize: 11, letterSpacing: 2,
      )),
      const SizedBox(height: 20),
      // Skin carousel
      SizedBox(height: 100, child: _carousel(active)),
      const Spacer(),
    ]);
  }

  Widget _heroOrb(OrbSkin s) {
    return Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: s.glowColor.withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 4)],
      ),
      child: Image.asset(s.assetPath, fit: BoxFit.contain),
    );
  }

  Widget _carousel(OrbSkin active) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: OrbSkin.catalog.length,
      itemBuilder: (ctx, i) {
        final s = OrbSkin.catalog[i];
        final isSel   = i == _sel;
        final isOwned = _owned.contains(s.id);
        final canBuy  = _wallet >= s.cost;

        return GestureDetector(
          onTap: () => _tap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 72,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSel ? s.glowColor.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: isSel ? s.glowColor : (isOwned ? Colors.white24 : Colors.white10),
                width: isSel ? 2 : 1,
              ),
              boxShadow: isSel ? [BoxShadow(color: s.glowColor.withValues(alpha: 0.35), blurRadius: 12)] : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Stack(alignment: Alignment.center, children: [
                Opacity(opacity: isOwned ? 1.0 : 0.3,
                    child: Image.asset(s.assetPath, width: 38, height: 38)),
                if (!isOwned) const Icon(Icons.lock, color: Colors.white60, size: 18),
              ]),
              const SizedBox(height: 5),
              Text(s.label, style: TextStyle(
                color: isOwned ? (isSel ? s.glowColor : Colors.white60) : Colors.white30,
                fontSize: 10, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 2),
              if (!isOwned)
                Text(OrbSkin.formatCost(s.cost), style: TextStyle(
                  color: canBuy ? Colors.greenAccent.withValues(alpha: 0.8) : Colors.redAccent.withValues(alpha: 0.6),
                  fontSize: 9, fontWeight: FontWeight.bold,
                ))
              else
                Text(_rarityLabel(s.rarity), style: TextStyle(
                  color: isSel ? s.glowColor.withValues(alpha: 0.7) : Colors.white24,
                  fontSize: 9, letterSpacing: 1,
                )),
            ]),
          ),
        );
      },
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _bottomBar(OrbSkin active) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Play button
        AnimatedBuilder(
          animation: _pAnim,
          builder: (_, child) => Transform.scale(scale: _pAnim.value, child: child),
          child: SizedBox(
            width: double.infinity, height: 58,
            child: ElevatedButton(
              onPressed: () => widget.onPlay(active),
              style: ElevatedButton.styleFrom(
                backgroundColor: active.glowColor.withValues(alpha: 0.18),
                foregroundColor: active.glowColor,
                side: BorderSide(color: active.glowColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('PLAY', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 6,
                shadows: [Shadow(color: active.glowColor, blurRadius: 16)],
              )),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _link('Privacy', ClientConfig.privacyUrl),
          const SizedBox(width: 24),
          _link('Support', ClientConfig.supportUrl),
        ]),
      ]),
    );
  }

  Widget _link(String lbl, String url) => GestureDetector(
    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    child: Text(lbl, style: TextStyle(
      color: Colors.white.withValues(alpha: 0.3), fontSize: 12,
      decoration: TextDecoration.underline,
      decorationColor: Colors.white.withValues(alpha: 0.2),
    )),
  );

  String _rarityLabel(OrbRarity r) => switch (r) {
    OrbRarity.starter   => 'STARTER',
    OrbRarity.common    => 'COMMON',
    OrbRarity.rare      => 'RARE',
    OrbRarity.elite     => 'ELITE',
    OrbRarity.legendary => 'LEGENDARY',
  };
}
