import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../gravity_rush_game.dart';

class ScoreZone extends SpriteComponent
    with HasGameReference<GravityRushGame>, CollisionCallbacks {
  final bool is2x;
  bool collected = false;

  ScoreZone({
    required this.is2x,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final path = is2x
        ? 'game_assets/circle_with_2x_inside.webp'
        : 'game_assets/green_circle.webp';
    sprite = await game.loadSprite(path);
    add(CircleHitbox(isSolid: true));
  }
}
