import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum PipeType { green, redWithSkull, redWithoutSkull }

class Pipe extends SpriteComponent with CollisionCallbacks {
  Pipe({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.topLeft,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }
}
