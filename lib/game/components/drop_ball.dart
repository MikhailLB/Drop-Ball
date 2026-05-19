import 'dart:math';

import 'package:flame/components.dart';
import '../../utils/physics_cfg.dart';

class DropBall extends SpriteComponent {
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

  DropBall({
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
          size: Vector2.all(PhysicsCfg.ballRadius * 2),
          anchor: Anchor.center,
          priority: 10,
        );

  void applyNudge(double dx) {
    if (_landed) return;
    velocity.x += dx * PhysicsCfg.nudgeStrength;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) return;

    _driftTimer += dt;
    if (_driftTimer >= PhysicsCfg.driftInterval) {
      _driftTimer = 0;
      velocity.x += (_rng.nextDouble() - 0.5) * PhysicsCfg.driftForce;
    }

    final subDt = dt / PhysicsCfg.physicsSubsteps;
    for (int s = 0; s < PhysicsCfg.physicsSubsteps; s++) {
      _step(subDt);
      if (_landed) return;
    }
  }

  void _step(double dt) {
    velocity.y += PhysicsCfg.gravity * dt;

    if (velocity.length > PhysicsCfg.maxVelocity) {
      velocity.setFrom(velocity.normalized() * PhysicsCfg.maxVelocity);
    }

    position += velocity * dt;

    final r = PhysicsCfg.ballRadius;

    if (position.x - r < 0) {
      position.x = r;
      velocity.x = velocity.x.abs() * PhysicsCfg.bounceDamping;
    } else if (position.x + r > screenWidth) {
      position.x = screenWidth - r;
      velocity.x = -velocity.x.abs() * PhysicsCfg.bounceDamping;
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
          velocity.x *= PhysicsCfg.bounceDamping;
          velocity.y *= PhysicsCfg.bounceDamping;
          velocity.x += (_rng.nextDouble() - 0.5) * PhysicsCfg.horizontalJitter;
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
