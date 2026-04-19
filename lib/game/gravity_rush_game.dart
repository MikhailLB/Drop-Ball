import 'dart:ui' show Canvas, Color, Offset, FontWeight, Paint;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, Shadow;
import '../models/skin_data.dart';
import '../utils/constants.dart';
import 'components/peg_board.dart';
import 'components/plinko_ball.dart';
import 'managers/difficulty_manager.dart';
import 'managers/score_manager.dart';
import 'sprite_cache.dart';

class GravityRushGame extends FlameGame with TapCallbacks {
  final SkinData skin;
  final ScoreManager scoreManager = ScoreManager();
  final DifficultyManager difficultyManager = DifficultyManager();
  final SpriteCache spriteCache = SpriteCache();

  late PegBoard _board;
  PlinkoBall? _activeBall;
  _BallTrail? _trail;
  bool _isGameOver = false;
  bool _waitingForTap = true;
  double _cooldownTimer = 0;
  bool _inCooldown = false;
  TextComponent? _tapHint;

  GravityRushGame({required this.skin}) {
    images.prefix = 'assets/';
  }

  @override
  Color backgroundColor() => const Color(0xFF080818);

  @override
  Future<void> onLoad() async {
    await spriteCache.loadAll(this);
    await scoreManager.loadHighScore();
    await _startGame();
  }

  Future<void> _startGame() async {
    _isGameOver = false;
    _waitingForTap = true;
    _inCooldown = false;
    scoreManager.reset();
    difficultyManager.reset();

    _board = PegBoard();
    add(_board);

    _trail = _BallTrail(skin: skin);
    add(_trail!);

    add(_ScoreDisplay());
    _showTapHint();
  }

  void _showTapHint() {
    _tapHint?.removeFromParent();
    _tapHint = TextComponent(
      text: 'TAP TO DROP',
      position: Vector2(size.x / 2, size.y * 0.06),
      anchor: Anchor.center,
      priority: 50,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0x99FFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
    );
    add(_tapHint!);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isGameOver || !_waitingForTap || _inCooldown || paused) return;

    _waitingForTap = false;
    _tapHint?.removeFromParent();
    _tapHint = null;

    final tapX = event.canvasPosition.x;
    final margin = size.x * GameConstants.boardMarginFraction;
    final dropX = tapX.clamp(
      margin + GameConstants.ballRadius,
      size.x - margin - GameConstants.ballRadius,
    );

    _dropBall(dropX);
  }

  void _dropBall(double x) {
    final dropY = size.y * GameConstants.boardTopFraction - GameConstants.ballRadius;
    _activeBall = PlinkoBall(
      sprite: spriteCache.getSphere(skin.id),
      startPosition: Vector2(x, dropY),
      pegs: _board.pegs,
      pegRadius: _board.actualPegRadius,
      onLanded: _onBallLanded,
      slotsY: _board.slotsY,
      screenWidth: size.x,
    );
    add(_activeBall!);
    _trail?.ball = _activeBall;
    _trail?.clearTrail();
  }

  void _onBallLanded(double x) {
    final slotIndex = _board.getSlotIndex(x);
    final slotType = _board.slots[slotIndex];

    _trail?.ball = null;

    if (slotType == SlotType.skull) {
      gameOver();
      return;
    }

    final points = slotType == SlotType.score2x
        ? GameConstants.score2x
        : GameConstants.baseScore;
    scoreManager.addScore(points);
    add(_ScorePopup(
      text: '+$points',
      position: Vector2(x, _board.slotsY - 20),
      color: slotType == SlotType.score2x
          ? const Color(0xFFFFD700)
          : const Color(0xFF00FF00),
    ));

    _activeBall?.removeFromParent();
    _activeBall = null;

    difficultyManager.onDrop();
    if (difficultyManager.tierChanged) {
      _board.generateSlots(
        skullCount: difficultyManager.skullCount,
        bonus2xCount: difficultyManager.bonus2xCount,
      );
    }

    _inCooldown = true;
    _cooldownTimer = 0.5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;

    if (_inCooldown) {
      _cooldownTimer -= dt;
      if (_cooldownTimer <= 0) {
        _inCooldown = false;
        _waitingForTap = true;
        _showTapHint();
      }
    }
  }

  void gameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void restart() {
    overlays.remove('GameOver');
    overlays.remove('Pause');
    removeAll(children);
    resumeEngine();
    _startGame();
  }

  void togglePause() {
    if (_isGameOver) return;
    if (paused) {
      resumeEngine();
      overlays.remove('Pause');
    } else {
      pauseEngine();
      overlays.add('Pause');
    }
  }
}

class _BallTrail extends Component with HasGameReference<GravityRushGame> {
  PlinkoBall? ball;
  final SkinData skin;
  final List<Vector2> _positions = [];
  final Paint _paint = Paint();
  static const int _maxLength = 12;

  _BallTrail({required this.skin}) {
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
      final r = GameConstants.ballRadius * t * 0.4;
      canvas.drawCircle(Offset(_positions[i].x, _positions[i].y), r, _paint);
    }
  }
}

class _ScoreDisplay extends TextComponent
    with HasGameReference<GravityRushGame> {
  _ScoreDisplay()
      : super(
          anchor: Anchor.topCenter,
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 36,
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
    position = Vector2(game.size.x / 2, 40);
  }

  @override
  void update(double dt) {
    super.update(dt);
    text = '${game.scoreManager.score}';
  }
}

class _ScorePopup extends TextComponent {
  double _lifetime = 0;

  _ScorePopup({
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
