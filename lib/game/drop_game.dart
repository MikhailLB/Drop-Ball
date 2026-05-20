import 'dart:math' show sin;
import 'dart:ui' show BlurStyle, Canvas, Color, MaskFilter, Offset, Paint;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart' show FontWeight, Shadow, TextStyle;
import '../models/ball_skin.dart';
import '../utils/physics_cfg.dart';
import 'components/pin_field.dart';
import 'components/drop_ball.dart';
import 'managers/round_scaler.dart';
import 'managers/coin_wallet.dart';
import 'game_assets.dart';

part 'src/hud_components.dart';
part 'src/fx_components.dart';

enum DropResult { died, collected, won }

class NeonDropGame extends FlameGame with PanDetector {
  final BallSkin skin;
  final CoinWallet wallet = CoinWallet();
  final RoundScaler roundScaler = RoundScaler();
  final GameAssets spriteAssets = GameAssets();

  late PinField _field;
  PinField get field => _field;
  DropBall? _activeBall;
  _BallTrailFx? _trail;

  bool _isOver = false;
  bool _awaitingDrop = true;
  double _cooldown = 0;
  bool _inCooldown = false;
  int _streak = 0;

  DropResult? endResult;
  int lastAmount = 0;

  final ValueNotifier<bool> collectAvailable = ValueNotifier(false);

  NeonDropGame({required this.skin}) {
    images.prefix = 'assets/';
  }

  @override
  Color backgroundColor() => const Color(0xFF08001A);

  @override
  Future<void> onLoad() async {
    await spriteAssets.loadAll(this);
    await wallet.load();
    await _initSession();
  }

  Future<void> _initSession() async {
    _isOver = false;
    _awaitingDrop = true;
    _inCooldown = false;
    _streak = 0;
    endResult = null;
    lastAmount = 0;
    wallet.resetGame();
    roundScaler.reset();

    _field = PinField();
    add(_field);

    _trail = _BallTrailFx(skin: skin);
    add(_trail!);

    add(_CoinsHud());
    add(_PegTracker());
    add(_DropHint());
    _refreshCollect();
  }

  void _refreshCollect() {
    collectAvailable.value = _awaitingDrop && wallet.pending > 0 && !_isOver;
  }

  @override
  void onPanDown(DragDownInfo info) {
    if (_isOver || !_awaitingDrop || _inCooldown || paused) return;

    _awaitingDrop = false;
    collectAvailable.value = false;

    final tapX = info.eventPosition.widget.x;
    final margin = size.x * PhysicsCfg.boardMarginFraction;
    final dropX = tapX.clamp(
      margin + PhysicsCfg.ballRadius,
      size.x - margin - PhysicsCfg.ballRadius,
    );

    wallet.resetDrop();
    _field.prepareForDrop(
      moveChance: roundScaler.movingPegChance,
      moveAmplitude: roundScaler.movingPegAmplitude,
    );
    _launchBall(dropX);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_activeBall != null && !_isOver && !paused) {
      _activeBall!.applyNudge(info.delta.global.x);
    }
  }

  void _launchBall(double x) {
    final dropY = size.y * PhysicsCfg.boardTopFraction - PhysicsCfg.ballRadius;
    _activeBall = DropBall(
      sprite: spriteAssets.getSphere(skin.id),
      startPosition: Vector2(x, dropY),
      pegs: _field.pegs,
      pegRadius: _field.actualPegRadius,
      onLanded: _onBallLanded,
      onPegHit: _onPegHit,
      slotsY: _field.slotsY,
      screenWidth: size.x,
    );
    add(_activeBall!);
    _trail?.ball = _activeBall;
    _trail?.clear();
  }

  void _onPegHit(int pegIndex) {
    final bonus = _field.onPegHit(pegIndex);
    if (bonus > 0) {
      wallet.onGoldHit();
      add(_FloatLabel(
        text: '+$bonus',
        position: _field.pegs[pegIndex].clone(),
        color: const Color(0xFFFFCC00),
      ));
    }
  }

  void _onBallLanded(double x) {
    _trail?.ball = null;
    _activeBall?.removeFromParent();
    _activeBall = null;

    final slot = _field.getSlotIndex(x);

    if (_field.isSkullSlot(slot)) {
      _streak = 0;
      _die();
      return;
    }

    var multi = _field.getMultiplier(slot);

    if (_streak >= 2) {
      multi = double.parse((multi + 0.5).toStringAsFixed(1));
      add(_FloatLabel(
        text: 'STREAK +0.5x',
        position: Vector2(size.x / 2, _field.slotsY - 50),
        color: const Color(0xFFFF8C00),
      ));
    }

    _streak++;
    wallet.applyLanding(multi);

    add(_FloatLabel(
      text: 'x$multi',
      position: Vector2(x, _field.slotsY - 20),
      color: const Color(0xFFBB88FF),
    ));

    roundScaler.advance();
    _field.buildSlots();

    if (_field.allWhitePegsHit) {
      _win();
      return;
    }

    _inCooldown = true;
    _cooldown = 0.5;
  }

  void _die() {
    endResult = DropResult.died;
    lastAmount = wallet.burn();
    _isOver = true;
    collectAvailable.value = false;
    pauseEngine();
    overlays.add('RoundEnd');
  }

  void _win() {
    endResult = DropResult.won;
    lastAmount = wallet.collectBonus();
    _isOver = true;
    collectAvailable.value = false;
    pauseEngine();
    overlays.add('RoundEnd');
  }

  void collectCoins() {
    if (_isOver || wallet.pending <= 0) return;
    endResult = DropResult.collected;
    lastAmount = wallet.collect();
    _isOver = true;
    collectAvailable.value = false;
    pauseEngine();
    overlays.add('RoundEnd');
  }

  void restart() {
    overlays.remove('RoundEnd');
    overlays.remove('Halted');
    removeAll(children);
    resumeEngine();
    _initSession();
  }

  void togglePause() {
    if (_isOver) return;
    if (paused) {
      resumeEngine();
      overlays.remove('Halted');
    } else {
      pauseEngine();
      overlays.add('Halted');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isOver) return;

    if (_inCooldown) {
      _cooldown -= dt;
      if (_cooldown <= 0) {
        _inCooldown = false;
        _awaitingDrop = true;
        _refreshCollect();
      }
    }
  }
}
