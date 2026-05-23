import 'dart:math' show sin;
import 'dart:ui' show Canvas, Color, Offset, FontWeight, Paint;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, Shadow;
import '../../models/orb_skin.dart';
import '../../utils/drop_config.dart';
import '../drop_core.dart';

class OrbTrail extends Component with HasGameReference<DropCore> {
  dynamic orb;
  final OrbSkin skin;
  final List<Vector2> _pts = [];
  final Paint _pt = Paint();
  static const int _max = 12;

  OrbTrail({required this.skin}) { priority = 5; }
  void clearTrail() => _pts.clear();

  @override
  void update(double dt) {
    if (orb == null || !orb!.isMounted) { _pts.clear(); return; }
    _pts.add(orb!.position.clone());
    while (_pts.length > _max) { _pts.removeAt(0); }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _pts.length; i++) {
      final t = i / _pts.length;
      _pt.color = skin.glowColor.withValues(alpha: t * 0.25);
      canvas.drawCircle(Offset(_pts[i].x, _pts[i].y), DropConfig.orbRadius * t * 0.4, _pt);
    }
  }
}

class ScoreBar extends TextComponent with HasGameReference<DropCore> {
  ScoreBar() : super(
    anchor: Anchor.topCenter,
    priority: 100,
    textRenderer: TextPaint(style: const TextStyle(
      color: Color(0xFFFFFFFF), fontSize: 26, fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Color(0xFF000000), blurRadius: 8, offset: Offset(2, 2))],
    )),
  );
  @override void onLoad() { position = Vector2(game.size.x / 2, 28); }
  @override void update(double dt) {
    super.update(dt);
    final s = game.ledger.session, g = game.stageCtrl.cfg.goal, p = game.ledger.pending;
    text = '$s / $g${p > 0 ? '  (+$p)' : ''}';
  }
}

// Keep alias so arena_view.dart can reference CoinsDisplay if needed
typedef CoinsDisplay = ScoreBar;

class HeartBar extends TextComponent with HasGameReference<DropCore> {
  HeartBar() : super(
    anchor: Anchor.topLeft,
    priority: 100,
    textRenderer: TextPaint(style: const TextStyle(
      color: Color(0xFFFF6B6B), fontSize: 18, fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Color(0xAAFF0000), blurRadius: 6)],
    )),
  );
  @override void onLoad() { position = Vector2(12, 28); }
  @override void update(double dt) {
    super.update(dt);
    text = '♥' * game.stageCtrl.livesLeft;
  }
}

class StageLabel extends TextComponent with HasGameReference<DropCore> {
  StageLabel() : super(
    anchor: Anchor.topRight,
    priority: 100,
    textRenderer: TextPaint(style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 13, letterSpacing: 1)),
  );
  @override void onLoad() {
    position = Vector2(game.size.x - 12, 28);
    text = 'LV ${game.stageCtrl.cfg.number}';
  }
}

class PegMeter extends TextComponent with HasGameReference<DropCore> {
  PegMeter() : super(
    anchor: Anchor.topCenter,
    priority: 100,
    textRenderer: TextPaint(style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 13)),
  );
  @override void onLoad() { position = Vector2(game.size.x / 2, 58); }
  @override void update(double dt) {
    super.update(dt);
    text = 'PEGS: ${game.field.struckPegs}/${game.field.totalPegs}';
  }
}

class DropHint extends TextComponent with HasGameReference<DropCore> {
  double _t = 0;
  late final double _cx;

  DropHint() : super(
    text: '● TAP TO DROP  ● DRAG TO STEER ●',
    anchor: Anchor.center,
    priority: 100,
    textRenderer: TextPaint(style: const TextStyle(color: Color(0x77FFFFFF), fontSize: 11, letterSpacing: 1.5)),
  );
  @override void onLoad() { _cx = game.size.x / 2; position = Vector2(_cx, 78); }
  @override void update(double dt) { super.update(dt); _t += dt; position.x = _cx + sin(_t * 1.5) * 12; }
}

class PopLabel extends TextComponent {
  double _age = 0;

  PopLabel({required String text, required Vector2 position, Color color = const Color(0xFF00FF00)})
      : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          priority: 50,
          textRenderer: TextPaint(style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color, blurRadius: 10)],
          )),
        );

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= 60 * dt;
    if (_age >= 0.8) removeFromParent();
  }
}
