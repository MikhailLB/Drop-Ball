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
import 'models/level_config.dart';
import 'sprite_registry.dart';
import 'ui/game_hud.dart';

enum GameEndReason { skullDied, levelComplete, collected }

class BounceGame extends FlameGame with PanDetector {
  final BallSkin skin;
  final LevelConfig levelConfig;
  final ScoreTracker scoreTracker = ScoreTracker();
  late final LevelController levelController;
  final SpriteRegistry spriteRegistry = SpriteRegistry();

  late BoardLayout _board;
  BoardLayout get board => _board;
  GameBall? _activeBall;
  BallTrail? _trail;

  bool _isRoundOver = false;
  bool _waitingForTap = true;
  double _cooldownTimer = 0;
  bool _inCooldown = false;

  GameEndReason? endReason;
  int lastAmount = 0;

  final ValueNotifier<bool> collectAvailable = ValueNotifier(false);

  BounceGame({required this.skin, required this.levelConfig}) {
    images.prefix = 'assets/';
    levelController = LevelController(config: levelConfig);
  }

  @override
  Color backgroundColor() => const Color(0xFF080818);

  @override
  Future<void> onLoad() async {
    await spriteRegistry.loadAll(this);
    await scoreTracker.loadBalance();
    _startGame();
  }

  void _startGame() {
    _isRoundOver = false;
    _waitingForTap = true;
    _inCooldown = false;
    endReason = null;
    lastAmount = 0;
    scoreTracker.resetForNewGame();
    levelController.reset();

    _board = BoardLayout(levelConfig: levelConfig);
    add(_board);

    _trail = BallTrail(skin: skin);
    add(_trail!);

    add(ScoreDisplay());
    add(LivesDisplay());
    add(LevelLabel());
    add(PegCounter());
    add(HintText());
    _updateCollect();
  }

  void _updateCollect() {
    collectAvailable.value =
        _waitingForTap && scoreTracker.pendingCoins > 0 && !_isRoundOver;
  }

  @override
  void onPanDown(DragDownInfo info) {
    if (_isRoundOver || !_waitingForTap || _inCooldown || paused) return;

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
    if (_activeBall != null && !_isRoundOver && !paused) {
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
      _hitSkull();
      return;
    }

    final multi = _board.getMultiplier(slotIndex);
    scoreTracker.processLanding(multi);

    add(ScorePopup(
      text: '×${multi.toStringAsFixed(1)}',
      position: Vector2(x, _board.slotsY - 20),
      color: const Color(0xFF00FF88),
    ));

    levelController.onDrop();
    _board.generateSlots();

    // Auto-collect pending and check win condition
    final autoCollected = scoreTracker.collect();
    if (scoreTracker.sessionScore >= levelConfig.targetScore) {
      _winLevel(autoCollected);
      return;
    }

    _inCooldown = true;
    _cooldownTimer = 0.5;
  }

  void _hitSkull() {
    levelController.loseLife();
    final lost = scoreTracker.skullPenalty();

    add(ScorePopup(
      text: lost > 0 ? '-$lost' : '💀',
      position: Vector2(size.x / 2, size.y * 0.5),
      color: const Color(0xFFFF2244),
    ));

    if (!levelController.hasLivesLeft) {
      _failLevel();
      return;
    }

    _board.generateSlots();
    _inCooldown = true;
    _cooldownTimer = 0.8;
  }

  void _winLevel(int banked) {
    endReason = GameEndReason.levelComplete;
    lastAmount = banked;
    _isRoundOver = true;
    collectAvailable.value = false;
    pauseEngine();
    overlays.add('GameOver');
  }

  void _failLevel() {
    endReason = GameEndReason.skullDied;
    lastAmount = scoreTracker.burn();
    _isRoundOver = true;
    collectAvailable.value = false;
    pauseEngine();
    overlays.add('GameOver');
  }

  void collectCoins() {
    if (_isRoundOver || scoreTracker.pendingCoins <= 0) return;
    endReason = GameEndReason.collected;
    lastAmount = scoreTracker.collect();
    _isRoundOver = true;
    collectAvailable.value = false;

    if (scoreTracker.sessionScore >= levelConfig.targetScore) {
      pauseEngine();
      overlays.add('GameOver');
    } else {
      // Still have coins but not enough — just resume
      _isRoundOver = false;
      _inCooldown = true;
      _cooldownTimer = 0.3;
    }
  }

  void restart() {
    overlays.remove('GameOver');
    overlays.remove('Pause');
    removeAll(children);
    resumeEngine();
    _startGame();
  }

  void togglePause() {
    if (_isRoundOver) return;
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
    if (_isRoundOver) return;

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
