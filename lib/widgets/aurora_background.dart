import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft animated nebula + starfield backdrop shared by every screen.
/// Pure Flutter painting — no images, no packages.
///
/// It wraps its content in a [Scaffold] so descendant [Text] widgets always
/// have a Material/DefaultTextStyle ancestor (otherwise Flutter paints the
/// debug yellow double-underline).
class AuroraBackground extends StatefulWidget {
  final Color tint;
  final Widget child;

  const AuroraBackground({super.key, required this.tint, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    final rng = math.Random(7);
    _stars = List.generate(
      48,
      (_) => _Star(
        dx: rng.nextDouble(),
        dy: rng.nextDouble(),
        radius: 0.4 + rng.nextDouble() * 1.6,
        phase: rng.nextDouble(),
        speed: 0.4 + rng.nextDouble() * 0.9,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05030E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              painter: _AuroraPainter(
                t: _ctrl.value,
                tint: widget.tint,
                stars: _stars,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Star {
  final double dx, dy, radius, phase, speed;
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
    required this.speed,
  });
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final Color tint;
  final List<_Star> stars;

  _AuroraPainter({required this.t, required this.tint, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;

    void blob(Color color, double cx, double cy, double radius, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    blob(
      tint,
      size.width * (0.3 + 0.12 * math.cos(angle)),
      size.height * (0.26 + 0.06 * math.sin(angle)),
      size.width * 0.66,
      0.38,
    );
    blob(
      const Color(0xFF7C4DFF),
      size.width * (0.74 + 0.10 * math.sin(angle * 0.8)),
      size.height * (0.64 + 0.08 * math.cos(angle * 0.9)),
      size.width * 0.58,
      0.34,
    );
    blob(
      tint,
      size.width * 0.5,
      size.height * 0.96,
      size.width * 0.52,
      0.30,
    );

    // Twinkling starfield.
    final starPaint = Paint()..color = Colors.white;
    for (final s in stars) {
      final twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin((t * s.speed + s.phase) * 2 * math.pi));
      starPaint.color = Colors.white.withValues(alpha: 0.5 * twinkle);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        s.radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t || old.tint != tint;
}
