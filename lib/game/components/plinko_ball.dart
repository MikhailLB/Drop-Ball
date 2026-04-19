import 'dart:math';

import 'package:flame/components.dart';
import '../../utils/constants.dart';

class PlinkoBall extends SpriteComponent {
  final Vector2 velocity = Vector2.zero();
  final List<Vector2> pegs;
  final double pegRadius;
  final void Function(double x) onLanded;
  final double slotsY;
  final double screenWidth;
  bool _landed = false;
  final Random _rng = Random();

  PlinkoBall({
    required Sprite sprite,
    required Vector2 startPosition,
    required this.pegs,
    required this.pegRadius,
    required this.onLanded,
    required this.slotsY,
    required this.screenWidth,
  }) : super(
          sprite: sprite,
          position: startPosition,
          size: Vector2.all(GameConstants.ballRadius * 2),
          anchor: Anchor.center,
          priority: 10,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) return;

    final subDt = dt / GameConstants.physicsSubsteps;
    for (int s = 0; s < GameConstants.physicsSubsteps; s++) {
      _physicsStep(subDt);
      if (_landed) return;
    }
  }

  void _physicsStep(double dt) {
    velocity.y += GameConstants.gravity * dt;

    if (velocity.length > GameConstants.maxVelocity) {
      velocity.setFrom(velocity.normalized() * GameConstants.maxVelocity);
    }

    position += velocity * dt;

    final r = GameConstants.ballRadius;

    if (position.x - r < 0) {
      position.x = r;
      velocity.x = velocity.x.abs() * GameConstants.bounceDamping;
    } else if (position.x + r > screenWidth) {
      position.x = screenWidth - r;
      velocity.x = -velocity.x.abs() * GameConstants.bounceDamping;
    }

    for (final peg in pegs) {
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
          velocity.x *= GameConstants.bounceDamping;
          velocity.y *= GameConstants.bounceDamping;
          velocity.x +=
              (_rng.nextDouble() - 0.5) * GameConstants.horizontalJitter;
        }
      }
    }

    if (position.y + r >= slotsY) {
      _landed = true;
      onLanded(position.x);
    }
  }
}
