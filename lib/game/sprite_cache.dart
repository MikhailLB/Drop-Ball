import 'package:flame/components.dart';
import 'package:flame/game.dart';

class SpriteCache {
  late final Sprite greenPipe;
  late final Sprite redPipeWithSkull;
  late final Sprite redPipeWithoutSkull;
  late final Sprite blueSpike;
  late final Sprite redSpike;
  late final Sprite greenCircle;
  late final Sprite circle2x;
  late final Sprite circleSkull;
  late final Map<String, Sprite> spheres;

  Future<void> loadAll(FlameGame game) async {
    game.images.prefix = 'assets/';

    final results = await Future.wait([
      game.loadSprite('game_assets/green_pipe.webp'),
      game.loadSprite('game_assets/red_pipe_with_skull.webp'),
      game.loadSprite('game_assets/red_pipe_without_skull.webp'),
      game.loadSprite('game_assets/blue_spike.webp'),
      game.loadSprite('game_assets/red_spike.webp'),
      game.loadSprite('game_assets/green_circle.webp'),
      game.loadSprite('game_assets/circle_with_2x_inside.webp'),
      game.loadSprite('game_assets/circle_with_skull_inside.webp'),
      game.loadSprite('game_assets/blue_sphere_asset.webp'),
      game.loadSprite('game_assets/green_sphere_asset.webp'),
      game.loadSprite('game_assets/yellow_sphere_asset.webp'),
      game.loadSprite('game_assets/red_sphere_asset.webp'),
      game.loadSprite('game_assets/purple_sphere_asset.webp'),
      game.loadSprite('game_assets/backround_asset.webp'),
    ]);

    greenPipe = results[0];
    redPipeWithSkull = results[1];
    redPipeWithoutSkull = results[2];
    blueSpike = results[3];
    redSpike = results[4];
    greenCircle = results[5];
    circle2x = results[6];
    circleSkull = results[7];

    spheres = {
      'blue': results[8],
      'green': results[9],
      'yellow': results[10],
      'red': results[11],
      'purple': results[12],
    };
  }

  Sprite getSphere(String skinId) => spheres[skinId] ?? spheres['blue']!;
}
