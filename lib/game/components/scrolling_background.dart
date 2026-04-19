import 'dart:ui' as ui;
import 'package:flame/components.dart';
import '../gravity_rush_game.dart';

class ScrollingBackground extends SpriteComponent with HasGameReference<GravityRushGame> {
  late ui.Image _bgImage;
  late ui.Rect _srcRect;
  double _offset = 0;
  late double _tileHeight;

  @override
  Future<void> onLoad() async {
    final sprite = await game.loadSprite('game_assets/backround_asset.webp');
    _bgImage = sprite.image;
    _srcRect = ui.Rect.fromLTWH(0, 0, _bgImage.width.toDouble(), _bgImage.height.toDouble());
    size = game.size;
    _tileHeight = size.y;
    priority = -10;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final paint = ui.Paint();

    final y1 = _offset % _tileHeight - _tileHeight;
    final y2 = y1 + _tileHeight;
    final y3 = y2 + _tileHeight;

    for (final yPos in [y1, y2, y3]) {
      canvas.drawImageRect(
        _bgImage,
        _srcRect,
        ui.Rect.fromLTWH(0, yPos, size.x, _tileHeight),
        paint,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _offset += game.difficultyManager.scrollSpeed * dt;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _tileHeight = size.y;
  }
}
