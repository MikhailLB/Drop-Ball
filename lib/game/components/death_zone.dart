import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../gravity_rush_game.dart';

class DeathZone extends SpriteComponent
    with HasGameReference<GravityRushGame>, CollisionCallbacks {
  DeathZone({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('game_assets/circle_with_skull_inside.webp');
    add(CircleHitbox(isSolid: true));
  }
}
