import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Golden gradient Accept button with animated shimmer and pulsing glow.
class AcceptButton extends StatefulWidget {
  final double width;
  final bool compact;
  final VoidCallback onTap;

  const AcceptButton({
    super.key,
    required this.width,
    required this.compact,
    required this.onTap,
  });

  @override
  State<AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<AcceptButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shimmer;
  bool _down = false;

  static const _gold = Color(0xFFF6C54A);
  static const _goldDeep = Color(0xFFB07713);
  static const _goldLight = Color(0xFFFFE9A8);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 40.0 : 50.0;
    final fontSize = widget.compact ? 13.0 : 17.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _shimmer]),
          builder: (_, _) {
            final pulse = 0.5 + _pulse.value * 0.5;
            final shimmer = _shimmer.value;
            return SizedBox(
              width: widget.width,
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.35 * pulse),
                            blurRadius: 22 + 10 * pulse,
                            spreadRadius: 1 + 2 * pulse,
                          ),
                          BoxShadow(
                            color: _goldLight.withValues(alpha: 0.25 * pulse),
                            blurRadius: 40 + 20 * pulse,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(height / 2),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_goldLight, _gold, _goldDeep],
                          stops: [0.0, 0.55, 1.0],
                        ),
                        border: Border.all(
                          color: _goldLight.withValues(alpha: 0.9),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(height / 2),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.white.withValues(alpha: 0.55),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(height / 2),
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: Offset((shimmer * 2.0 - 1.0) * widget.width, 0),
                        child: Transform.rotate(
                          angle: -math.pi / 9,
                          child: Container(
                            width: widget.width * 0.35,
                            height: height * 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.55),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'ALLOW',
                    style: TextStyle(
                      color: const Color(0xFF3B2500),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: _goldLight.withValues(alpha: 0.9),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Outlined Skip button: minimal, gold-outline, subtle breathing animation.
class DismissButton extends StatefulWidget {
  final double width;
  final bool compact;
  final VoidCallback onTap;

  const DismissButton({
    super.key,
    required this.width,
    required this.compact,
    required this.onTap,
  });

  @override
  State<DismissButton> createState() => _DismissButtonState();
}

class _DismissButtonState extends State<DismissButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 30.0 : 38.0;
    final fontSize = widget.compact ? 11.0 : 14.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedBuilder(
          animation: _breathe,
          builder: (_, _) {
            final t = _breathe.value;
            return SizedBox(
              width: widget.width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  color: Colors.black.withValues(alpha: _down ? 0.5 : 0.35),
                  border: Border.all(
                    color: const Color(
                      0xFFF6C54A,
                    ).withValues(alpha: 0.55 + 0.25 * t),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFF6C54A,
                      ).withValues(alpha: 0.12 * t),
                      blurRadius: 10 + 8 * t,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
