import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/skin_data.dart';
import '../../utils/constants.dart';
import '../gravity_rush_game.dart';
import 'ball_particles.dart';

class Ball extends SpriteComponent
    with HasGameReference<GravityRushGame>, CollisionCallbacks {
  final SkinData skin;
  late BallParticleEmitter _particleEmitter;

  Ball({required this.skin})
      : super(
          size: Vector2.all(GameConstants.ballSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(skin.assetPath.replaceFirst('assets/', ''));
    position = Vector2(game.size.x / 2, game.size.y * 0.25);

    add(CircleHitbox(
      radius: GameConstants.ballSize / 2 * 0.8,
      anchor: Anchor.center,
      position: Vector2.all(GameConstants.ballSize / 2),
    ));

    _particleEmitter = BallParticleEmitter(
      skin: skin,
      positionGetter: () => position.clone(),
    );
    game.add(_particleEmitter);

    priority = 10;
  }

  @override
  void render(Canvas canvas) {
    if (skin.glowRadius > 0) {
      final glowPaint = Paint()
        ..color = skin.primaryColor.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, skin.glowRadius);
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 + skin.glowRadius / 2,
        glowPaint,
      );
    }
    super.render(canvas);
  }

  void moveHorizontal(double dx) {
    final newX = (position.x + dx).clamp(
      size.x / 2,
      game.size.x - size.x / 2,
    );
    position.x = newX;
  }

  @override
  void onRemove() {
    if (_particleEmitter.isMounted) {
      _particleEmitter.removeFromParent();
    }
    super.onRemove();
  }
}
