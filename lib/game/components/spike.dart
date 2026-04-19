import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../gravity_rush_game.dart';

enum SpikeType { blue, red }

class Spike extends SpriteComponent
    with HasGameReference<GravityRushGame>, CollisionCallbacks {
  final SpikeType spikeType;

  Spike({
    required this.spikeType,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    final path = switch (spikeType) {
      SpikeType.blue => 'game_assets/blue_spike.webp',
      SpikeType.red => 'game_assets/red_spike.webp',
    };

    sprite = await game.loadSprite(path);
    add(PolygonHitbox([
      Vector2(size.x / 2, 0),
      Vector2(size.x, size.y),
      Vector2(0, size.y),
    ]));
  }
}
