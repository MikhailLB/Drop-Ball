import 'dart:math' show sin, cos, pi;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/orb_skin.dart';
import 'profile_screen.dart';

class ShopScreen extends StatefulWidget {
  final void Function(OrbSkin skin) onPlay;
  const ShopScreen({super.key, required this.onPlay});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with TickerProviderStateMixin {
  int _sel = 0;
  int _wallet = 0;
  Set<String> _owned = {'frost'};

  late AnimationController _orbit;   // rotating ring around hero
  late AnimationController _pulse;   // PLAY button pulse
  late Animation<double> _pAnim;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pAnim = Tween<double>(begin: 1.0, end: 1.055)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _wallet = p.getInt('db_wallet') ?? 0;
      _owned  = (p.getString('owned_orbs') ?? 'frost').split(',').toSet();
      final saved = p.getString('active_orb') ?? 'frost';
      _sel = OrbSkin.catalog.indexWhere((s) => s.id == saved).clamp(0, OrbSkin.catalog.length - 1);
      if (!_owned.contains(OrbSkin.catalog[_sel].id)) _sel = 0;
    });
  }

  Future<void> _saveSelection(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('active_orb', id);
  }

  Future<void> _purchase(OrbSkin skin) async {
    if (_wallet < skin.cost) return;
    final p = await SharedPreferences.getInstance();
    setState(() { _wallet -= skin.cost; _owned.add(skin.id); });
    await p.setInt('db_wallet', _wallet);
    await p.setString('owned_orbs', _owned.join(','));
  }

  void _onOrbTap(int idx) {
    final s = OrbSkin.catalog[idx];
    if (_owned.contains(s.id)) {
      setState(() => _sel = idx);
      _saveSelection(s.id);
    } else if (_wallet >= s.cost) {
      _showBuySheet(s, idx);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Need ${OrbSkin.formatCost(s.cost)} coins',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  void _showBuySheet(OrbSkin s, int idx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Image.asset(s.assetPath, width: 72, height: 72),
          const SizedBox(height: 12),
          Text(s.label.toUpperCase(), style: TextStyle(
            color: s.glowColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3,
            shadows: [Shadow(color: s.glowColor, blurRadius: 12)],
          )),
          const SizedBox(height: 6),
          Text('${OrbSkin.formatCost(s.cost)} coins',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white38,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CANCEL', style: TextStyle(letterSpacing: 2)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _purchase(s);
                setState(() => _sel = idx);
                _saveSelection(s.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: s.glowColor.withValues(alpha: 0.28),
                foregroundColor: s.glowColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            )),
          ]),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _orbit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final skin = OrbSkin.catalog[_sel];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF060614),
              skin.glowColor.withValues(alpha: 0.18),
              const Color(0xFF060614),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _header(skin),
            Expanded(child: _center(skin, size)),
            _strip(),
            _footer(skin),
          ]),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header(OrbSkin skin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        // Wallet
        _chip(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.toll_rounded, color: Colors.amber, size: 15),
            const SizedBox(width: 4),
            Text(OrbSkin.formatCost(_wallet),
                style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        ),
        const Spacer(),
        // Profile avatar
        GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
            _loadPrefs();
          },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: skin.glowColor.withValues(alpha: 0.55), width: 2),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: const Icon(Icons.person_outline_rounded, size: 22, color: Colors.white60),
          ),
        ),
      ]),
    );
  }

  Widget _chip({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: child,
  );

  // ── Center hero ───────────────────────────────────────────────────────────
  Widget _center(OrbSkin skin, Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text('DROPBALL: NEON EDITION', style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3,
        )),
        const SizedBox(height: 28),
        // Hero orb with orbit ring
        _heroWithRing(skin),
        const SizedBox(height: 20),
        // Name
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(skin.label.toUpperCase(),
            key: ValueKey(skin.id),
            style: TextStyle(
              color: skin.glowColor, fontSize: 26, fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [Shadow(color: skin.glowColor, blurRadius: 20)],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Rarity stars
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Row(key: ValueKey('${skin.id}_rarity'),
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < _rarityStars(skin.rarity)
                    ? Icons.diamond_rounded
                    : Icons.diamond_outlined,
                color: i < _rarityStars(skin.rarity)
                    ? skin.glowColor
                    : Colors.white.withValues(alpha: 0.15),
                size: 14,
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _heroWithRing(OrbSkin skin) {
    return SizedBox(
      width: 200, height: 200,
      child: Stack(alignment: Alignment.center, children: [
        // Outer glow
        Container(
          width: 170, height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: skin.glowColor.withValues(alpha: 0.30), blurRadius: 50, spreadRadius: 10),
              BoxShadow(color: skin.glowColor.withValues(alpha: 0.15), blurRadius: 80, spreadRadius: 20),
            ],
          ),
        ),
        // Spinning dashed orbit
        AnimatedBuilder(
          animation: _orbit,
          builder: (ctx2, ch2) => Transform.rotate(
            angle: _orbit.value * 2 * pi,
            child: CustomPaint(
              size: const Size(170, 170),
              painter: _OrbitPainter(color: skin.glowColor),
            ),
          ),
        ),
        // Orb image
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Image.asset(skin.assetPath, key: ValueKey(skin.id),
              width: 120, height: 120, fit: BoxFit.contain),
        ),
      ]),
    );
  }

  // ── Orb strip ─────────────────────────────────────────────────────────────
  Widget _strip() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: OrbSkin.catalog.length,
        itemBuilder: (ctx, i) {
          final s      = OrbSkin.catalog[i];
          final isSel  = i == _sel;
          final isOwn  = _owned.contains(s.id);

          return GestureDetector(
            onTap: () => _onOrbTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSel
                    ? s.glowColor.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isSel ? s.glowColor : Colors.white.withValues(alpha: 0.12),
                  width: isSel ? 2.5 : 1,
                ),
                boxShadow: isSel
                    ? [BoxShadow(color: s.glowColor.withValues(alpha: 0.45), blurRadius: 14)]
                    : null,
              ),
              child: Stack(alignment: Alignment.center, children: [
                Opacity(
                  opacity: isOwn ? 1.0 : 0.25,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(s.assetPath),
                  ),
                ),
                if (!isOwn)
                  const Icon(Icons.lock, color: Colors.white54, size: 16),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _footer(OrbSkin skin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // PLAY button
        AnimatedBuilder(
          animation: _pAnim,
          builder: (_, child) => Transform.scale(scale: _pAnim.value, child: child),
          child: GestureDetector(
            onTap: () => widget.onPlay(OrbSkin.catalog[_sel]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    skin.glowColor.withValues(alpha: 0.85),
                    skin.accentColor.withValues(alpha: 0.75),
                  ],
                ),
                boxShadow: [
                  BoxShadow(color: skin.glowColor.withValues(alpha: 0.5), blurRadius: 22, offset: const Offset(0, 6)),
                ],
              ),
              child: const Center(
                child: Text('PLAY', style: TextStyle(
                  color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 8,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                )),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _link('Privacy', ClientConfig.privacyUrl),
          Container(width: 1, height: 12, margin: const EdgeInsets.symmetric(horizontal: 14),
              color: Colors.white12),
          _link('Support', ClientConfig.supportUrl),
        ]),
      ]),
    );
  }

  Widget _link(String lbl, String url) => GestureDetector(
    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView),
    child: Text(lbl, style: TextStyle(
      color: Colors.white.withValues(alpha: 0.3), fontSize: 11, letterSpacing: 1,
    )),
  );

  int _rarityStars(OrbRarity r) => switch (r) {
    OrbRarity.starter   => 1,
    OrbRarity.common    => 2,
    OrbRarity.rare      => 3,
    OrbRarity.elite     => 4,
    OrbRarity.legendary => 5,
  };
}

// ── Orbit ring painter ────────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final Color color;
  const _OrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = size.width / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.35);

    // Draw dashed circle
    const dashCount = 24;
    const dashAngle = 2 * pi / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i.isOdd) continue;
      final start = i * dashAngle;
      final end   = start + dashAngle * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, end - start, false, paint,
      );
    }

    // Small bright dot on the orbit
    final dotAngle = 0.0;
    final dx = cx + r * cos(dotAngle);
    final dy = cy + r * sin(dotAngle);
    canvas.drawCircle(Offset(dx, dy), 4,
        Paint()..color = color.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.color != color;
}
