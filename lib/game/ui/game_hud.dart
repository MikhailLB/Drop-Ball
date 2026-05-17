import 'dart:math' show sin;
import 'dart:ui' show Canvas, Color, Offset, FontWeight, Paint;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, Shadow;
import '../../models/ball_skin.dart';
import '../../utils/game_config.dart';
import '../bounce_game.dart';

class BallTrail extends Component with HasGameReference<BounceGame> {
  dynamic ball;
  final BallSkin skin;
  final List<Vector2> _positions = [];
  final Paint _paint = Paint();
  static const int _maxLength = 12;

  BallTrail({required this.skin}) {
    priority = 5;
  }

  void clearTrail() => _positions.clear();

  @override
  void update(double dt) {
    if (ball == null || !ball!.isMounted) {
      _positions.clear();
      return;
    }
    _positions.add(ball!.position.clone());
    while (_positions.length > _maxLength) {
      _positions.removeAt(0);
    }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _positions.length; i++) {
      final t = i / _positions.length;
      _paint.color = skin.primaryColor.withValues(alpha: t * 0.25);
      final r = GameConfig.ballRadius * t * 0.4;
      canvas.drawCircle(Offset(_positions[i].x, _positions[i].y), r, _paint);
    }
  }
}

class CoinsDisplay extends TextComponent
    with HasGameReference<BounceGame> {
  CoinsDisplay()
      : super(
          anchor: Anchor.topCenter,
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 30,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                    color: Color(0xFF000000),
                    blurRadius: 8,
                    offset: Offset(2, 2)),
              ],
            ),
          ),
        );

  @override
  void onLoad() {
    position = Vector2(game.size.x / 2, 32);
  }

  @override
  void update(double dt) {
    super.update(dt);
    text = 'COINS: ${game.scoreTracker.pendingCoins}';
  }
}

class PegCounter extends TextComponent
    with HasGameReference<BounceGame> {
  PegCounter()
      : super(
          anchor: Anchor.topCenter,
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xAAFFFFFF),
              fontSize: 14,
            ),
          ),
        );

  @override
  void onLoad() {
    position = Vector2(game.size.x / 2, 66);
  }

  @override
  void update(double dt) {
    super.update(dt);
    text = 'PEGS: ${game.board.hitWhitePegs}/${game.board.totalWhitePegs}';
  }
}

class HintText extends TextComponent with HasGameReference<BounceGame> {
  double _t = 0;
  late final double _baseX;

  HintText()
      : super(
          text: '● HIT ALL WHITE PEGS ● DRAG TO STEER ●',
          anchor: Anchor.center,
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0x77FFFFFF),
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        );

  @override
  void onLoad() {
    _baseX = game.size.x / 2;
    position = Vector2(_baseX, 88);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.x = _baseX + sin(_t * 1.5) * 12;
  }
}

class ScorePopup extends TextComponent {
  double _lifetime = 0;

  ScorePopup({
    required String text,
    required Vector2 position,
    Color color = const Color(0xFF00FF00),
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          priority: 50,
          textRenderer: TextPaint(
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: color, blurRadius: 10)],
            ),
          ),
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;
    position.y -= 60 * dt;
    if (_lifetime >= 0.8) removeFromParent();
  }
}
