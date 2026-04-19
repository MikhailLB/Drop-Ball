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
      game.loadSprite('game_assets/green_sphere_asset.webp'),
      game.loadSprite('game_assets/yellow_sphere_asset.webp'),
      game.loadSprite('game_assets/red_sphere_asset.webp'),
      game.loadSprite('game_assets/purple_sphere_asset.webp'),
    ]);

    greenCircle = results[0];
    circle2x = results[1];
    circleSkull = results[2];
    spheres = {
      'blue': results[3],
      'green': results[4],
      'yellow': results[5],
      'red': results[6],
      'purple': results[7],
    };
  }

  Sprite getSphere(String skinId) => spheres[skinId] ?? spheres['blue']!;
}
