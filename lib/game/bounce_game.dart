import 'dart:ui' show Color;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import '../models/ball_skin.dart';
import '../utils/game_config.dart';
import 'components/board_layout.dart';
import 'components/game_ball.dart';
import 'managers/level_controller.dart';
import 'managers/score_tracker.dart';
import 'sprite_registry.dart';
import 'ui/game_hud.dart';

enum GameEndReason { died, collected, won }

class BounceGame extends FlameGame with PanDetector {
  final BallSkin skin;
  final ScoreTracker scoreTracker = ScoreTracker();
  final LevelController levelController = LevelController();
  final SpriteRegistry spriteRegistry = SpriteRegistry();

  late BoardLayout _board;
  BoardLayout get board => _board;
  GameBall? _activeBall;
  BallTrail? _trail;

  bool _isGameOver = false;
  bool _waitingForTap = true;
  double _cooldownTimer = 0;
  bool _inCooldown = false;

  GameEndReason? endReason;
  int lastAmount = 0;

  final ValueNotifier<bool> collectAvailable = ValueNotifier(false);

  BounceGame({required this.skin}) {
    images.prefix = 'assets/';
  }

  @override
  Color backgroundColor() => const Color(0xFF080818);

  @override
  Future<void> onLoad() async {
    await spriteRegistry.loadAll(this);
    await scoreTracker.loadBalance();
    await _startGame();
  }

  Future<void> _startGame() async {
    _isGameOver = false;
    _waitingForTap = true;
    _inCooldown = false;
    endReason = null;
    lastAmount = 0;
    scoreTracker.resetForNewGame();
    levelController.reset();

    _board = BoardLayout();
    add(_board);

    _trail = BallTrail(skin: skin);
    add(_trail!);

    add(CoinsDisplay());
    add(PegCounter());
    add(HintText());
    _updateCollect();
  }

  void _updateCollect() {
    collectAvailable.value =
        _waitingForTap && scoreTracker.pendingCoins > 0 && !_isGameOver;
  }

  @override
  void onPanDown(DragDownInfo info) {
    if (_isGameOver || !_waitingForTap || _inCooldown || paused) return;

    _waitingForTap = false;
    collectAvailable.value = false;

    final tapX = info.eventPosition.widget.x;
    final margin = size.x * GameConfig.boardMarginFraction;
    final dropX = tapX.clamp(
      margin + GameConfig.ballRadius,
      size.x - margin - GameConfig.ballRadius,
    );

    scoreTracker.resetForNewDrop();
    _board.prepareForDrop(
      moveChance: levelController.movingPegChance,
      moveAmplitude: levelController.movingPegAmplitude,
    );
    _dropBall(dropX);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_activeBall != null && !_isGameOver && !paused) {
      _activeBall!.applyNudge(info.delta.global.x);
    }
  }

  void _dropBall(double x) {
    final dropY =
        size.y * GameConfig.boardTopFraction - GameConfig.ballRadius;
    _activeBall = GameBall(
      sprite: spriteRegistry.getSphere(skin.id),
      startPosition: Vector2(x, dropY),
      pegs: _board.pegs,
      pegRadius: _board.actualPegRadius,
      onLanded: _onBallLanded,
      onPegHit: _onPegHit,
      slotsY: _board.slotsY,
      screenWidth: size.x,
    );
    add(_activeBall!);
    _trail?.ball = _activeBall;
    _trail?.clearTrail();
  }

  void _onPegHit(int pegIndex) {
    final bonus = _board.onPegHit(pegIndex);
    if (bonus > 0) {
      scoreTracker.onGoldPegHit();
      add(ScorePopup(
        text: '+$bonus',
        position: _board.pegs[pegIndex].clone(),
        color: const Color(0xFFFFD700),
      ));
    }
  }

  void _onBallLanded(double x) {
    _trail?.ball = null;
    _activeBall?.removeFromParent();
    _activeBall = null;

    final slotIndex = _board.getSlotIndex(x);

    if (_board.isSkullSlot(slotIndex)) {
      _die();
      return;
    }

    final multi = _board.getMultiplier(slotIndex);
    scoreTracker.processLanding(multi);

    add(ScorePopup(
      text: '×$multi',
      position: Vector2(x, _board.slotsY - 20),
      color: const Color(0xFF00FF88),
    ));

    levelController.onDrop();
    _board.generateSlots();

    if (_board.allWhitePegsHit) {
      _win();
      return;
    }

    _inCooldown = true;
    _cooldownTimer = 0.5;
  }

  void _die() {
    endReason = GameEndReason.died;
    lastAmount = scoreTracker.burn();
    _isGameOver = true;
    collectAvailable.value = false;
    pauseEngine();
    overlays.add('GameOver');
  }

  void _win() {
    endReason = GameEndReason.won;
    lastAmount = scoreTracker.collectWithBonus();
    _isGameOver = true;
    collectAvailable.value = false;
    pauseEngine();
    overlays.add('GameOver');
  }

  void collectCoins() {
    if (_isGameOver || scoreTracker.pendingCoins <= 0) return;
    endReason = GameEndReason.collected;
    lastAmount = scoreTracker.collect();
    _isGameOver = true;
    collectAvailable.value = false;
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

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;

    if (_inCooldown) {
      _cooldownTimer -= dt;
      if (_cooldownTimer <= 0) {
        _inCooldown = false;
        _waitingForTap = true;
        _updateCollect();
      }
    }
  }
}
