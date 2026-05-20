part of '../drop_game.dart';

class _CoinsHud extends TextComponent with HasGameReference<NeonDropGame> {
  _CoinsHud()
      : super(
          anchor: Anchor.topCenter,
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFFCC00),
              fontSize: 30,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Color(0xFFFFAA00), blurRadius: 14),
                Shadow(color: Color(0xFF000000), blurRadius: 4, offset: Offset(1, 1)),
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
    text = 'COINS: ${game.wallet.pending}';
  }
}

class _PegTracker extends TextComponent with HasGameReference<NeonDropGame> {
  _PegTracker()
      : super(
          anchor: Anchor.topCenter,
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xAABBAAFF),
              fontSize: 14,
              shadows: [Shadow(color: Color(0x88AA66FF), blurRadius: 8)],
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
    text = 'PEGS: ${game.field.hitWhitePegs}/${game.field.totalWhitePegs}';
  }
}

class _DropHint extends TextComponent with HasGameReference<NeonDropGame> {
  double _t = 0;
  late final double _baseX;

  _DropHint()
      : super(
          text: '* HIT ALL PEGS * DRAG TO STEER *',
          anchor: Anchor.center,
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0x99AA99FF),
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
