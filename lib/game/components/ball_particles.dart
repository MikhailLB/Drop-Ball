import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart' as fp;
import 'package:flutter/material.dart';
import '../../models/skin_data.dart';
import '../gravity_rush_game.dart';

class BallParticleEmitter extends Component with HasGameReference<GravityRushGame> {
  final SkinData skin;
  final Random _rng = Random();
  double _timer = 0;
  Vector2 Function() positionGetter;

  BallParticleEmitter({required this.skin, required this.positionGetter});

  double get _emitInterval {
    switch (skin.tier) {
      case SkinTier.basic:
        return 0.12;
      case SkinTier.common:
        return 0.08;
      case SkinTier.rare:
        return 0.05;
      case SkinTier.epic:
        return 0.03;
      case SkinTier.legendary:
        return 0.02;
    }
  }

  @override
  void update(double dt) {
    _timer += dt;
    if (_timer >= _emitInterval) {
      _timer = 0;
      _emitParticles();
    }
  }

  void _emitParticles() {
    final pos = positionGetter();
    final count = skin.particleDensity ~/ 3 + 1;

    for (int i = 0; i < count; i++) {
      final particle = _createParticle();
      game.add(
        ParticleSystemComponent(
          particle: fp.MovingParticle(
            from: pos + Vector2(_rng.nextDouble() * 20 - 10, 10),
            to: pos + Vector2(
              _rng.nextDouble() * skin.particleSpeed - skin.particleSpeed / 2,
              30 + _rng.nextDouble() * 40,
            ),
            child: particle,
          ),
          priority: -1,
        ),
      );
    }
  }

  fp.Particle _createParticle() {
    switch (skin.tier) {
      case SkinTier.basic:
        return _basicTrail();
      case SkinTier.common:
        return _sparkleParticle();
      case SkinTier.rare:
        return _glowParticle();
      case SkinTier.epic:
        return _fireParticle();
      case SkinTier.legendary:
        return _nebulaParticle();
    }
  }

  fp.Particle _basicTrail() {
    final r = 2 + _rng.nextDouble() * 2;
    final color = skin.primaryColor.withValues(alpha: 0.6);
    return fp.ComputedParticle(
      lifespan: skin.particleLifespan,
      renderer: (canvas, particle) {
        final alpha = (1 - particle.progress) * 0.6;
        canvas.drawCircle(
          Offset.zero,
          r * (1 - particle.progress * 0.5),
          Paint()..color = color.withValues(alpha: alpha),
        );
      },
    );
  }

  fp.Particle _sparkleParticle() {
    final color = _rng.nextBool() ? skin.primaryColor : skin.secondaryColor;
    final r = 2 + _rng.nextDouble() * 3;
    return fp.ComputedParticle(
      lifespan: skin.particleLifespan,
      renderer: (canvas, particle) {
        final scale = 1 - particle.progress * 0.8;
        final alpha = (1 - particle.progress) * 0.7;
        canvas.drawCircle(
          Offset.zero,
          r * scale,
          Paint()..color = color.withValues(alpha: alpha),
        );
      },
    );
  }

  fp.Particle _glowParticle() {
    final color = _rng.nextBool() ? skin.primaryColor : skin.secondaryColor;
    return fp.ComputedParticle(
      lifespan: skin.particleLifespan,
      renderer: (canvas, particle) {
        final r = (3 + _rng.nextDouble() * 4) * (1 - particle.progress);
        final paint = Paint()
          ..color = color.withValues(alpha: (1 - particle.progress) * 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset.zero, r, paint);
      },
    );
  }

  fp.Particle _fireParticle() {
    return fp.ComputedParticle(
      lifespan: skin.particleLifespan,
      renderer: (canvas, particle) {
        final progress = particle.progress;
        final color = Color.lerp(
          skin.primaryColor,
          skin.secondaryColor,
          progress,
        )!;
        final r = (4 + _rng.nextDouble() * 5) * (1 - progress);
        final paint = Paint()
          ..color = color.withValues(alpha: (1 - progress) * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset.zero, r, paint);
        canvas.drawCircle(
          Offset(_rng.nextDouble() * 4 - 2, _rng.nextDouble() * 4 - 2),
          r * 0.4,
          Paint()..color = Colors.yellow.withValues(alpha: (1 - progress) * 0.5),
        );
      },
    );
  }

  fp.Particle _nebulaParticle() {
    return fp.ComputedParticle(
      lifespan: skin.particleLifespan,
      renderer: (canvas, particle) {
        final progress = particle.progress;
        final hue = (progress * 120 + _rng.nextDouble() * 60) % 360;
        final color = HSLColor.fromAHSL(1, hue, 0.8, 0.6).toColor();
        final r = (5 + _rng.nextDouble() * 6) * (1 - progress * 0.5);
        final paint = Paint()
          ..color = color.withValues(alpha: (1 - progress) * 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset.zero, r, paint);
        for (int j = 0; j < 3; j++) {
          final sparkR = r * 0.3;
          final angle = _rng.nextDouble() * pi * 2;
          final dist = r * 1.2;
          canvas.drawCircle(
            Offset(cos(angle) * dist, sin(angle) * dist),
            sparkR,
            Paint()..color = Colors.white.withValues(alpha: (1 - progress) * 0.6),
          );
        }
      },
    );
  }
}
