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

  late final Paint _mainPaint;
  late final Paint _glowPaint;

  BallParticleEmitter({required this.skin, required this.positionGetter}) {
    _mainPaint = Paint()..color = skin.primaryColor;
    _glowPaint = Paint()
      ..color = skin.secondaryColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  }

  double get _emitInterval {
    switch (skin.tier) {
      case SkinTier.basic:
        return 0.20;
      case SkinTier.common:
        return 0.14;
      case SkinTier.rare:
        return 0.10;
      case SkinTier.epic:
        return 0.07;
      case SkinTier.legendary:
        return 0.05;
    }
  }

  int get _particlesPerEmit {
    switch (skin.tier) {
      case SkinTier.basic:
        return 1;
      case SkinTier.common:
        return 1;
      case SkinTier.rare:
        return 2;
      case SkinTier.epic:
        return 2;
      case SkinTier.legendary:
        return 3;
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

    for (int i = 0; i < _particlesPerEmit; i++) {
      game.add(
        ParticleSystemComponent(
          particle: fp.MovingParticle(
            from: pos + Vector2(_rng.nextDouble() * 14 - 7, 8),
            to: pos + Vector2(
              _rng.nextDouble() * 40 - 20,
              25 + _rng.nextDouble() * 30,
            ),
            child: _createParticle(),
          ),
          priority: -1,
        ),
      );
    }
  }

  fp.Particle _createParticle() {
    final lifespan = skin.particleLifespan;
    final r = 2.0 + _rng.nextDouble() * (skin.tier.index + 1);

    return fp.ComputedParticle(
      lifespan: lifespan,
      renderer: (canvas, particle) {
        final fade = 1 - particle.progress;
        final radius = r * fade;
        if (radius < 0.5) return;

        _mainPaint.color = skin.primaryColor.withValues(alpha: fade * 0.7);
        canvas.drawCircle(Offset.zero, radius, _mainPaint);

        if (skin.tier.index >= SkinTier.rare.index) {
          _glowPaint.color = skin.secondaryColor.withValues(alpha: fade * 0.4);
          canvas.drawCircle(Offset.zero, radius * 1.5, _glowPaint);
        }
      },
    );
  }
}
