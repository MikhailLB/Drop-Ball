import 'dart:math';
import 'package:flame/components.dart';
import '../../utils/drop_config.dart';

class DropOrb extends SpriteComponent {
  final Vector2 vel = Vector2.zero();
  final List<Vector2> pegs;
  final double pegR;
  final void Function(double x)   onGrounded;
  final void Function(int idx)    onPegStruck;
  final double floorY;
  final double screenW;
  bool _settled = false;
  final Random _rng = Random();
  double _driftClock = 0;

  DropOrb({
    required Sprite sprite,
    required Vector2 origin,
    required this.pegs,
    required this.pegR,
    required this.onGrounded,
    required this.onPegStruck,
    required this.floorY,
    required this.screenW,
  }) : super(
          sprite: sprite,
          position: origin,
          size: Vector2.all(DropConfig.orbRadius * 2),
          anchor: Anchor.center,
          priority: 10,
        );

  void steer(double dx) {
    if (_settled) return;
    vel.x += dx * DropConfig.steerStrength;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_settled) return;
    _driftClock += dt;
    if (_driftClock >= DropConfig.driftTick) {
      _driftClock = 0;
      vel.x += (_rng.nextDouble() - 0.5) * DropConfig.driftPush;
    }
    final sub = dt / DropConfig.subSteps;
    for (int i = 0; i < DropConfig.subSteps; i++) {
      _step(sub);
      if (_settled) return;
    }
  }

  void _step(double dt) {
    vel.y += DropConfig.gravity * dt;
    if (vel.length > DropConfig.speedCap) {
      vel.setFrom(vel.normalized() * DropConfig.speedCap);
    }
    position += vel * dt;

    final r = DropConfig.orbRadius;
    if (position.x - r < 0) {
      position.x = r;
      vel.x = vel.x.abs() * DropConfig.dampening;
    } else if (position.x + r > screenW) {
      position.x = screenW - r;
      vel.x = -vel.x.abs() * DropConfig.dampening;
    }

    for (int i = 0; i < pegs.length; i++) {
      final dx = position.x - pegs[i].x;
      final dy = position.y - pegs[i].y;
      final d = sqrt(dx * dx + dy * dy);
      final minD = r + pegR;
      if (d < minD && d > 0.001) {
        final nx = dx / d, ny = dy / d;
        position.x = pegs[i].x + nx * minD;
        position.y = pegs[i].y + ny * minD;
        final dot = vel.x * nx + vel.y * ny;
        if (dot < 0) {
          vel.x -= 2 * dot * nx;
          vel.y -= 2 * dot * ny;
          vel.x *= DropConfig.dampening;
          vel.y *= DropConfig.dampening;
          vel.x += (_rng.nextDouble() - 0.5) * DropConfig.lateralJitter;
          onPegStruck(i);
        }
      }
    }
    if (position.y + r >= floorY) {
      _settled = true;
      onGrounded(position.x);
    }
  }
}
