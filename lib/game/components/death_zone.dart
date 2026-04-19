import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class DeathZone extends SpriteComponent with CollisionCallbacks {
  DeathZone({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(sprite: sprite, position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(isSolid: true));
  }
}
