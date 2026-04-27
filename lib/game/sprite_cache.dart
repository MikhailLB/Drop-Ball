import 'package:flame/components.dart';
import 'package:flame/game.dart';

class SpriteCache {
  late final Sprite greenCircle;
  late final Sprite circle2x;
  late final Sprite circleSkull;
  late final Map<String, Sprite> spheres;

  Future<void> loadAll(FlameGame game) async {
    game.images.prefix = 'assets/';

    final results = await Future.wait([
      game.loadSprite('game_assets/green_circle.webp'),
      game.loadSprite('game_assets/circle_with_2x_inside.webp'),
      game.loadSprite('game_assets/circle_with_skull_inside.webp'),
      game.loadSprite('game_assets/blue_sphere_asset.webp'),
      game.loadSprite('game_assets/ground_sphere_asset.webp'),
      game.loadSprite('game_assets/green_sphere_asset.webp'),
      game.loadSprite('game_assets/aqua_sphere_asset.webp'),
      game.loadSprite('game_assets/air_sphere_asset.webp'),
      game.loadSprite('game_assets/yellow_sphere_asset.webp'),
      game.loadSprite('game_assets/red_sphere_asset.webp'),
      game.loadSprite('game_assets/purple_sphere_asset.webp'),
    ]);

    greenCircle = results[0];
    circle2x = results[1];
    circleSkull = results[2];
    spheres = {
      'blue': results[3],
      'ground': results[4],
      'green': results[5],
      'aqua': results[6],
      'air': results[7],
      'yellow': results[8],
      'red': results[9],
      'purple': results[10],
    };
  }

  Sprite getSphere(String skinId) => spheres[skinId] ?? spheres['blue']!;
}
