import 'dart:ui' show Color;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import '../models/orb_skin.dart';
import '../utils/drop_config.dart';
import 'components/peg_field.dart';
import 'components/drop_orb.dart';
import 'managers/stage_control.dart';
import 'managers/coin_ledger.dart';
import 'models/stage_config.dart';
import 'orb_cache.dart';
import 'ui/arena_hud.dart';

enum DropResult { trapHit, stageCleared, banked }

class DropCore extends FlameGame with PanDetector {
  final OrbSkin    skin;
  final StageConfig stage;
  final CoinLedger  ledger    = CoinLedger();
  late  final StageControl stageCtrl;
  final OrbCache   orbCache  = OrbCache();

  late PegField _field;
  PegField get field => _field;
  DropOrb?  _active;
  OrbTrail? _trail;

  bool   _over        = false;
  bool   _waitingTap  = true;
  bool   _cooling     = false;
  double _coolTimer   = 0;

  DropResult? result;
  int         lastAmt = 0;

  final ValueNotifier<bool> canBank = ValueNotifier(false);

  DropCore({required this.skin, required this.stage}) {
    images.prefix = 'assets/';
    stageCtrl = StageControl(cfg: stage);
  }

  @override
  Color backgroundColor() => const Color(0xFF080818);

  @override
  Future<void> onLoad() async {
    await orbCache.loadAll(this);
    await ledger.load();
    _begin();
  }

  void _begin() {
    _over = false; _waitingTap = true; _cooling = false;
    result = null; lastAmt = 0;
    ledger.resetRound();
    stageCtrl.reset();

    _field = PegField(stage: stage);
    add(_field);

    _trail = OrbTrail(skin: skin);
    add(_trail!);

    add(ScoreBar());
    add(HeartBar());
    add(StageLabel());
    add(PegMeter());
    add(DropHint());
    _refreshBank();
  }

  void _refreshBank() {
    canBank.value = _waitingTap && ledger.pending > 0 && !_over;
  }

  @override
  void onPanDown(DragDownInfo info) {
    if (_over || !_waitingTap || _cooling || paused) return;
    _waitingTap = false;
    canBank.value = false;
    final tx = info.eventPosition.widget.x;
    final mg = size.x * DropConfig.boardMargin;
    final dx = tx.clamp(mg + DropConfig.orbRadius, size.x - mg - DropConfig.orbRadius);
    ledger.resetDrop();
    _field.prepDrop(chance: stageCtrl.moveChance, amp: stageCtrl.moveRange);
    _launch(dx);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_active != null && !_over && !paused) _active!.steer(info.delta.global.x);
  }

  void _launch(double x) {
    final y = size.y * DropConfig.boardTop - DropConfig.orbRadius;
    _active = DropOrb(
      sprite: orbCache.getOrb(skin.id),
      origin: Vector2(x, y),
      pegs: _field.pegs,
      pegR: _field.actualPegR,
      onGrounded: _onLanded,
      onPegStruck: _onStrike,
      floorY: _field.floorY,
      screenW: size.x,
    );
    add(_active!);
    _trail?.orb = _active;
    _trail?.clearTrail();
  }

  void _onStrike(int i) {
    final bonus = _field.onStrike(i);
    if (bonus > 0) {
      ledger.onGoldPeg();
      add(PopLabel(text: '+$bonus', position: _field.pegs[i].clone(), color: const Color(0xFFFFD700)));
    }
  }

  void _onLanded(double x) {
    _trail?.orb = null;
    _active?.removeFromParent(); _active = null;
    final idx = _field.slotFor(x);
    if (_field.isTrap(idx)) { _hitTrap(); return; }

    final multi = _field.multiAt(idx);
    ledger.recordLanding(multi);
    add(PopLabel(text: '×${multi.toStringAsFixed(1)}', position: Vector2(x, _field.floorY - 20), color: const Color(0xFF00FF88)));

    stageCtrl.countDrop();
    _field.randomiseSlots();

    final banked = ledger.bank();
    if (ledger.session >= stage.goal) { _clear(banked); return; }

    _cooling = true; _coolTimer = 0.5;
  }

  void _hitTrap() {
    stageCtrl.loseLife();
    final lost = ledger.skullPenalty();
    add(PopLabel(text: lost > 0 ? '-$lost' : '💀', position: Vector2(size.x / 2, size.y * 0.5), color: const Color(0xFFFF2244)));
    if (!stageCtrl.hasLives) { _fail(); return; }
    _field.randomiseSlots();
    _cooling = true; _coolTimer = 0.8;
  }

  void _clear(int banked) {
    result = DropResult.stageCleared; lastAmt = banked;
    _end();
  }

  void _fail() {
    result = DropResult.trapHit; lastAmt = ledger.forfeit();
    _end();
  }

  void _end() {
    _over = true; canBank.value = false;
    pauseEngine(); overlays.add('Result');
  }

  void bankNow() {
    if (_over || ledger.pending <= 0) return;
    result = DropResult.banked; lastAmt = ledger.bank();
    canBank.value = false;
    if (ledger.session >= stage.goal) {
      _over = true; pauseEngine(); overlays.add('Result');
    } else {
      _cooling = true; _coolTimer = 0.3;
    }
  }

  void restart() {
    overlays.remove('Result'); overlays.remove('Paused');
    removeAll(children); resumeEngine(); _begin();
  }

  void togglePause() {
    if (_over) return;
    if (paused) { resumeEngine(); overlays.remove('Paused'); }
    else        { pauseEngine();  overlays.add('Paused'); }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_over) return;
    if (_cooling) {
      _coolTimer -= dt;
      if (_coolTimer <= 0) {
        _cooling = false; _waitingTap = true; _refreshBank();
      }
    }
  }
}
