import 'package:flame/components.dart';
import 'package:flame/game.dart';

class OrbCache {
  late final Sprite trapMarker;
  late final Map<String, Sprite> orbs;

  Future<void> loadAll(FlameGame game) async {
    game.images.prefix = 'assets/';

    final loaded = await Future.wait([
      game.loadSprite('game_assets/trap_marker.webp'),
      game.loadSprite('game_assets/orb_frost.webp'),
      game.loadSprite('game_assets/orb_terra.webp'),
      game.loadSprite('game_assets/orb_verdant.webp'),
      game.loadSprite('game_assets/orb_aqua.webp'),
      game.loadSprite('game_assets/orb_gale.webp'),
      game.loadSprite('game_assets/orb_solar.webp'),
      game.loadSprite('game_assets/orb_ember.webp'),
      game.loadSprite('game_assets/orb_void.webp'),
      game.loadSprite('game_assets/orb_blaze.webp'),
    ]);

    trapMarker = loaded[0];
    orbs = {
      'frost':   loaded[1],
      'terra':   loaded[2],
      'verdant': loaded[3],
      'aqua':    loaded[4],
      'gale':    loaded[5],
      'solar':   loaded[6],
      'ember':   loaded[7],
      'void':    loaded[8],
      'blaze':   loaded[9],
    };
  }

  Sprite getOrb(String id) => orbs[id] ?? orbs['frost']!;
}
