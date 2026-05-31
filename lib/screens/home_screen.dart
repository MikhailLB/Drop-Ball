import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/orb_skin.dart';
import '../resonance/level_book.dart';
import '../services/progress_store.dart';
import '../utils/asset_paths.dart';
import '../widgets/aurora_background.dart';
import 'web_view_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int level) onPlay;
  final VoidCallback onLevels;
  final VoidCallback onModes;
  final VoidCallback onCollection;
  final VoidCallback onHowTo;

  const HomeScreen({
    super.key,
    required this.onPlay,
    required this.onLevels,
    required this.onModes,
    required this.onCollection,
    required this.onHowTo,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _ring;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ring.dispose();
    _pulse.dispose();
    super.dispose();
  }

  int get _continueLevel {
    final store = ProgressStore.instance;
    for (var i = 1; i <= LevelBook.count; i++) {
      if (store.isUnlocked(i) && !store.isCleared(i)) return i;
    }
    for (var i = LevelBook.count; i >= 1; i--) {
      if (store.isUnlocked(i)) return i;
    }
    return 1;
  }

  void _openWeb(String title, String url, Color tint) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebViewScreen(title: title, url: url, tint: tint),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    final orb = store.activeOrb;
    final cleared = List.generate(LevelBook.count, (i) => i + 1)
        .where(store.isCleared)
        .length;

    return AuroraBackground(
      tint: orb.glowColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  _roundButton(Icons.help_outline_rounded, widget.onHowTo,
                      orb.glowColor),
                  const Spacer(),
                  _statChip(Icons.star_rounded, '${store.totalStars}',
                      const Color(0xFFFFD54F)),
                  const SizedBox(width: 10),
                  _statChip(Icons.flag_rounded, '$cleared/${LevelBook.count}',
                      Colors.white.withValues(alpha: 0.85)),
                ],
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 168,
                child: Image.asset(AssetPaths.logoTitle, fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              _heroOrb(orb),
              const SizedBox(height: 18),
              Text('SYNC THE GRID',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w700)),
              const Spacer(flex: 3),
              _playButton(orb),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _secondaryButton(
                      icon: Icons.grid_view_rounded,
                      label: 'LEVELS',
                      color: orb.glowColor,
                      onTap: widget.onLevels,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _secondaryButton(
                      icon: Icons.tune_rounded,
                      label: 'MODES',
                      color: orb.glowColor,
                      onTap: widget.onModes,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _secondaryButton(
                      icon: Icons.auto_awesome_rounded,
                      label: 'ORBS',
                      color: orb.glowColor,
                      onTap: widget.onCollection,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _links(orb.glowColor),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(text,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _roundButton(IconData icon, VoidCallback onTap, Color color) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );

  Widget _heroOrb(OrbSkin orb) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ring,
            builder: (context, _) => Transform.rotate(
              angle: _ring.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(204, 204),
                painter: _RingPainter(orb.glowColor, dashes: 36),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ring,
            builder: (context, _) => Transform.rotate(
              angle: -_ring.value * 2 * math.pi * 0.6,
              child: CustomPaint(
                size: const Size(168, 168),
                painter: _RingPainter(orb.accentColor, dashes: 20),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: orb.glowColor
                        .withValues(alpha: 0.30 + 0.22 * _pulse.value),
                    blurRadius: 56,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: child,
            ),
            child: Image.asset(orb.assetPath, width: 140, height: 140),
          ),
        ],
      ),
    );
  }

  Widget _playButton(OrbSkin orb) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) =>
          Transform.scale(scale: 1 + 0.03 * _pulse.value, child: child),
      child: GestureDetector(
        onTap: () => widget.onPlay(_continueLevel),
        child: Container(
          width: double.infinity,
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [
              orb.glowColor.withValues(alpha: 0.92),
              orb.accentColor.withValues(alpha: 0.82),
            ]),
            boxShadow: [
              BoxShadow(
                  color: orb.glowColor.withValues(alpha: 0.5),
                  blurRadius: 26,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Center(
            child: Text(
              _continueLevel == 1 ? 'PLAY' : 'CONTINUE',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 6)]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _links(Color tint) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _link('Privacy', ClientConfig.privacyUrl, tint),
          Container(
              width: 1,
              height: 11,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: Colors.white24),
          _link('Support', ClientConfig.supportUrl, tint),
        ],
      );

  Widget _link(String label, String url, Color tint) => GestureDetector(
        onTap: () => _openWeb(label, url, tint),
        child: Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                letterSpacing: 1)),
      );
}

class _RingPainter extends CustomPainter {
  final Color color;
  final int dashes;
  const _RingPainter(this.color, {required this.dashes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: 0.32);

    final step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      if (i.isOdd) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * step,
        step * 0.6,
        false,
        paint,
      );
    }
    final dot = Offset(center.dx + radius, center.dy);
    canvas.drawCircle(dot, 3.5, Paint()..color = color.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.dashes != dashes;
}
