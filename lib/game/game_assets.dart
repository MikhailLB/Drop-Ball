import 'package:flame/components.dart';
import 'package:flame/game.dart';

class GameAssets {
  late final Sprite greenCircle;
  late final Sprite circle2x;
  late final Sprite circleSkull;
  late final Map<String, Sprite> spheres;

  Future<void> loadAll(FlameGame game) async {
    game.images.prefix = 'assets/';

    final loaded = await Future.wait([
      game.loadSprite('game_assets/green_circle.webp'),
      game.loadSprite('game_assets/circle_with_2x_inside.webp'),
      game.loadSprite('game_assets/circle_with_skull_inside.webp'),
      game.loadSprite('game_assets/blue_sphere_asset.webp'),
      game.loadSprite('game_assets/green_sphere_asset.webp'),
      game.loadSprite('game_assets/yellow_sphere_asset.webp'),
      game.loadSprite('game_assets/red_sphere_asset.webp'),
      game.loadSprite('game_assets/purple_sphere_asset.webp'),
    ]);

    greenCircle = loaded[0];
    circle2x = loaded[1];
    circleSkull = loaded[2];
    spheres = {
      'blue': loaded[3],
      'green': loaded[4],
      'yellow': loaded[5],
      'red': loaded[6],
      'purple': loaded[7],
    };
  }

  Sprite getSphere(String skinId) => spheres[skinId] ?? spheres['blue']!;
}
