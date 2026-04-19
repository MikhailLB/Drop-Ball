import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../gravity_rush_game.dart';

enum PipeType { green, redWithSkull, redWithoutSkull }

class Pipe extends SpriteComponent
    with HasGameReference<GravityRushGame>, CollisionCallbacks {
  final PipeType pipeType;
  final bool isLethal;

  Pipe({
    required this.pipeType,
    required Vector2 position,
    required Vector2 size,
  })  : isLethal = pipeType != PipeType.green,
        super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    final path = switch (pipeType) {
      PipeType.green => 'game_assets/green_pipe.webp',
      PipeType.redWithSkull => 'game_assets/red_pipe_with_skull.webp',
      PipeType.redWithoutSkull => 'game_assets/red_pipe_without_skull.webp',
    };

    sprite = await game.loadSprite(path);
    add(RectangleHitbox());
  }
}
