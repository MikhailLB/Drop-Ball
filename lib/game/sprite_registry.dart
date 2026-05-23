import 'package:flame/components.dart';
import 'package:flame/game.dart';

class SpriteRegistry {
  late final Sprite circleSkull;
  late final Map<String, Sprite> spheres;

  Future<void> loadAll(FlameGame game) async {
    game.images.prefix = 'assets/';

    final loaded = await Future.wait([
      game.loadSprite('game_assets/circle_with_skull_inside.webp'),
      game.loadSprite('game_assets/blue_sphere_asset.webp'),
      game.loadSprite('game_assets/ground_sphere_asset.webp'),
      game.loadSprite('game_assets/green_sphere_asset.webp'),
      game.loadSprite('game_assets/aqua_sphere_asset.webp'),
      game.loadSprite('game_assets/air_sphere_asset.webp'),
      game.loadSprite('game_assets/yellow_sphere_asset.webp'),
      game.loadSprite('game_assets/red_sphere_asset.webp'),
      game.loadSprite('game_assets/purple_sphere_asset.webp'),
      game.loadSprite('game_assets/fire_sphere_asset.webp'),
    ]);

    circleSkull = loaded[0];
    spheres = {
      'blue': loaded[1],
      'ground': loaded[2],
      'green': loaded[3],
      'aqua': loaded[4],
      'air': loaded[5],
      'yellow': loaded[6],
      'red': loaded[7],
      'purple': loaded[8],
      'fire': loaded[9],
    };
  }

  Sprite getSphere(String skinId) => spheres[skinId] ?? spheres['blue']!;
}
