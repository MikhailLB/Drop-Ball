import 'package:flame/components.dart';
import 'package:flame/game.dart';

<<<<<<<< HEAD:lib/game/sprite_registry.dart
class SpriteRegistry {
  late final Sprite greenCircle;
  late final Sprite circle2x;
========
class GameAssets {
>>>>>>>> white-ios:lib/game/game_assets.dart
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
    ]);

    circleSkull = loaded[0];
    spheres = {
<<<<<<<< HEAD:lib/game/sprite_registry.dart
      'blue': results[3],
      'ground': results[4],
      'green': results[5],
      'aqua': results[6],
      'air': results[7],
      'yellow': results[8],
      'red': results[9],
      'purple': results[10],
========
      'blue': loaded[1],
      'green': loaded[2],
      'yellow': loaded[3],
      'red': loaded[4],
      'purple': loaded[5],
>>>>>>>> white-ios:lib/game/game_assets.dart
    };
  }

  Sprite getSphere(String skinId) => spheres[skinId] ?? spheres['blue']!;
}
