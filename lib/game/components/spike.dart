import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum SpikeType { blue, red }

class Spike extends SpriteComponent with CollisionCallbacks {
  Spike({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.topCenter,
        );

  @override
  Future<void> onLoad() async {
    add(PolygonHitbox([
      Vector2(size.x / 2, 0),
      Vector2(size.x, size.y),
      Vector2(0, size.y),
    ]));
  }
}
