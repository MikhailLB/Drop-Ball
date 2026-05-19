part of '../drop_game.dart';

class _BallTrailFx extends Component with HasGameReference<NeonDropGame> {
  DropBall? ball;
  final BallSkin skin;
  final List<Vector2> _pts = [];
  final Paint _paint = Paint();
  static const int _maxLen = 12;

  _BallTrailFx({required this.skin}) {
    priority = 5;
  }

  void clear() => _pts.clear();

  @override
  void update(double dt) {
    if (ball == null || !ball!.isMounted) {
      _pts.clear();
      return;
    }
    _pts.add(ball!.position.clone());
    while (_pts.length > _maxLen) {
      _pts.removeAt(0);
    }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _pts.length; i++) {
      final t = i / _pts.length;
      _paint.color = skin.primaryColor.withValues(alpha: t * 0.25);
      final r = PhysicsCfg.ballRadius * t * 0.4;
      canvas.drawCircle(Offset(_pts[i].x, _pts[i].y), r, _paint);
    }
  }
}

class _FloatLabel extends TextComponent {
  double _life = 0;

  _FloatLabel({
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
    _life += dt;
    position.y -= 60 * dt;
    if (_life >= 0.8) removeFromParent();
  }
}
