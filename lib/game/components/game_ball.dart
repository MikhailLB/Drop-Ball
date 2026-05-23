import 'dart:math';

import 'package:flame/components.dart';
import '../../utils/game_config.dart';

class GameBall extends SpriteComponent {
  final Vector2 velocity = Vector2.zero();
  final List<Vector2> pegs;
  final double pegRadius;
  final void Function(double x) onLanded;
  final void Function(int pegIndex) onPegHit;
  final double slotsY;
  final double screenWidth;
  bool _landed = false;
  final Random _rng = Random();
  double _driftTimer = 0;

  GameBall({
    required Sprite sprite,
    required Vector2 startPosition,
    required this.pegs,
    required this.pegRadius,
    required this.onLanded,
    required this.onPegHit,
    required this.slotsY,
    required this.screenWidth,
  }) : super(
          sprite: sprite,
          position: startPosition,
          size: Vector2.all(GameConfig.ballRadius * 2),
          anchor: Anchor.center,
          priority: 10,
        );

  void applyNudge(double dx) {
    if (_landed) return;
    velocity.x += dx * GameConfig.nudgeStrength;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) return;

    _driftTimer += dt;
    if (_driftTimer >= GameConfig.driftInterval) {
      _driftTimer = 0;
      velocity.x += (_rng.nextDouble() - 0.5) * GameConfig.driftForce;
    }

    final subDt = dt / GameConfig.physicsSubsteps;
    for (int s = 0; s < GameConfig.physicsSubsteps; s++) {
      _physicsStep(subDt);
      if (_landed) return;
    }
  }

  void _physicsStep(double dt) {
    velocity.y += GameConfig.gravity * dt;

    if (velocity.length > GameConfig.maxVelocity) {
      velocity.setFrom(velocity.normalized() * GameConfig.maxVelocity);
    }

    position += velocity * dt;

    final r = GameConfig.ballRadius;

    if (position.x - r < 0) {
      position.x = r;
      velocity.x = velocity.x.abs() * GameConfig.bounceDamping;
    } else if (position.x + r > screenWidth) {
      position.x = screenWidth - r;
      velocity.x = -velocity.x.abs() * GameConfig.bounceDamping;
    }

    for (int i = 0; i < pegs.length; i++) {
      final peg = pegs[i];
      final dx = position.x - peg.x;
      final dy = position.y - peg.y;
      final dist = sqrt(dx * dx + dy * dy);
      final minDist = r + pegRadius;

      if (dist < minDist && dist > 0.001) {
        final nx = dx / dist;
        final ny = dy / dist;
        position.x = peg.x + nx * minDist;
        position.y = peg.y + ny * minDist;

        final dot = velocity.x * nx + velocity.y * ny;
        if (dot < 0) {
          velocity.x -= 2 * dot * nx;
          velocity.y -= 2 * dot * ny;
          velocity.x *= GameConfig.bounceDamping;
          velocity.y *= GameConfig.bounceDamping;
          velocity.x += (_rng.nextDouble() - 0.5) * GameConfig.horizontalJitter;
          onPegHit(i);
        }
      }
    }

    if (position.y + r >= slotsY) {
      _landed = true;
      onLanded(position.x);
    }
  }
}
