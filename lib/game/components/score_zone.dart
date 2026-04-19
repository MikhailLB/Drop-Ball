import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class ScoreZone extends SpriteComponent with CollisionCallbacks {
  final bool is2x;
  bool collected = false;

  ScoreZone({
    required this.is2x,
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(sprite: sprite, position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(isSolid: true));
  }
}
