import 'dart:math';

import 'package:flame/components.dart';
<<<<<<<< HEAD:lib/game/components/game_ball.dart
import '../../utils/game_config.dart';

class GameBall extends SpriteComponent {
========
import '../../utils/physics_cfg.dart';

class DropBall extends SpriteComponent {
>>>>>>>> white-ios:lib/game/components/drop_ball.dart
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

<<<<<<<< HEAD:lib/game/components/game_ball.dart
  GameBall({
========
  DropBall({
>>>>>>>> white-ios:lib/game/components/drop_ball.dart
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
<<<<<<<< HEAD:lib/game/components/game_ball.dart
          size: Vector2.all(GameConfig.ballRadius * 2),
========
          size: Vector2.all(PhysicsCfg.ballRadius * 2),
>>>>>>>> white-ios:lib/game/components/drop_ball.dart
          anchor: Anchor.center,
          priority: 10,
        );

  void applyNudge(double dx) {
    if (_landed) return;
<<<<<<<< HEAD:lib/game/components/game_ball.dart
    velocity.x += dx * GameConfig.nudgeStrength;
========
    velocity.x += dx * PhysicsCfg.nudgeStrength;
>>>>>>>> white-ios:lib/game/components/drop_ball.dart
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) return;

    _driftTimer += dt;
<<<<<<<< HEAD:lib/game/components/game_ball.dart
    if (_driftTimer >= GameConfig.driftInterval) {
      _driftTimer = 0;
      velocity.x +=
          (_rng.nextDouble() - 0.5) * GameConfig.driftForce;
    }

    final subDt = dt / GameConfig.physicsSubsteps;
    for (int s = 0; s < GameConfig.physicsSubsteps; s++) {
      _physicsStep(subDt);
========
    if (_driftTimer >= PhysicsCfg.driftInterval) {
      _driftTimer = 0;
      velocity.x += (_rng.nextDouble() - 0.5) * PhysicsCfg.driftForce;
    }

    final subDt = dt / PhysicsCfg.physicsSubsteps;
    for (int s = 0; s < PhysicsCfg.physicsSubsteps; s++) {
      _step(subDt);
>>>>>>>> white-ios:lib/game/components/drop_ball.dart
      if (_landed) return;
    }
  }

<<<<<<<< HEAD:lib/game/components/game_ball.dart
  void _physicsStep(double dt) {
    velocity.y += GameConfig.gravity * dt;

    if (velocity.length > GameConfig.maxVelocity) {
      velocity.setFrom(velocity.normalized() * GameConfig.maxVelocity);
========
  void _step(double dt) {
    velocity.y += PhysicsCfg.gravity * dt;

    if (velocity.length > PhysicsCfg.maxVelocity) {
      velocity.setFrom(velocity.normalized() * PhysicsCfg.maxVelocity);
>>>>>>>> white-ios:lib/game/components/drop_ball.dart
    }

    position += velocity * dt;

<<<<<<<< HEAD:lib/game/components/game_ball.dart
    final r = GameConfig.ballRadius;

    if (position.x - r < 0) {
      position.x = r;
      velocity.x = velocity.x.abs() * GameConfig.bounceDamping;
    } else if (position.x + r > screenWidth) {
      position.x = screenWidth - r;
      velocity.x = -velocity.x.abs() * GameConfig.bounceDamping;
========
    final r = PhysicsCfg.ballRadius;

    if (position.x - r < 0) {
      position.x = r;
      velocity.x = velocity.x.abs() * PhysicsCfg.bounceDamping;
    } else if (position.x + r > screenWidth) {
      position.x = screenWidth - r;
      velocity.x = -velocity.x.abs() * PhysicsCfg.bounceDamping;
>>>>>>>> white-ios:lib/game/components/drop_ball.dart
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
<<<<<<<< HEAD:lib/game/components/game_ball.dart
          velocity.x *= GameConfig.bounceDamping;
          velocity.y *= GameConfig.bounceDamping;
          velocity.x +=
              (_rng.nextDouble() - 0.5) * GameConfig.horizontalJitter;
========
          velocity.x *= PhysicsCfg.bounceDamping;
          velocity.y *= PhysicsCfg.bounceDamping;
          velocity.x += (_rng.nextDouble() - 0.5) * PhysicsCfg.horizontalJitter;
>>>>>>>> white-ios:lib/game/components/drop_ball.dart
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
