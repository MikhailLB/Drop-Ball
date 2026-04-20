import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;
import '../../utils/constants.dart';
import '../gravity_rush_game.dart';

class PegBoard extends PositionComponent
    with HasGameReference<GravityRushGame> {
  final List<Vector2> pegs = [];
  final List<Vector2> _basePegs = [];
  final List<bool> _isGold = [];
  final List<bool> _isHit = [];
  final List<bool> _isMoving = [];
  double _moveAmplitude = 0;
  double _time = 0;

  /// Slot multipliers. 0 means skull.
  List<double> slotMultipliers = [];

  double _slotWidth = 0;
  double _slotsY = 0;
  double _slotsBottom = 0;
  double _actualPegRadius = 0;

  double get slotsY => _slotsY;
  double get actualPegRadius => _actualPegRadius;

  int get totalWhitePegs => _isGold.where((g) => !g).length;
  int get hitWhitePegs {
    int c = 0;
    for (int i = 0; i < pegs.length; i++) {
      if (!_isGold[i] && _isHit[i]) c++;
    }
    return c;
  }

  bool get allWhitePegsHit => hitWhitePegs >= totalWhitePegs;

  late final Sprite _circleSkull;

  final Paint _pegPaint = Paint()..color = const Color(0xFFDDDDEE);
  final Paint _pegGlowPaint = Paint()
    ..color = const Color(0x4400CCFF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _goldPegPaint = Paint()..color = const Color(0xFFFFD700);
  final Paint _goldGlowPaint = Paint()
    ..color = const Color(0x55FFD700)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final Paint _spentPegPaint = Paint()..color = const Color(0xFF555566);
  final Paint _movingGlowPaint = Paint()
    ..color = const Color(0x33FF66FF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _slotFillPaint = Paint();
  final Paint _slotBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  final TextPaint _slotTextPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = 0;
    _circleSkull = game.spriteCache.circleSkull;
    _buildLayout();
    _assignPegTypes();
    generateSlots();
  }

  void _buildLayout() {
    pegs.clear();
    _basePegs.clear();
    _isGold.clear();
    _isHit.clear();
    _isMoving.clear();

    final w = size.x;
    final h = size.y;
    final topY = h * GameConstants.boardTopFraction;
    final botY = h * GameConstants.boardBottomFraction;
    final boardH = botY - topY;
    final margin = w * GameConstants.boardMarginFraction;
    final usableW = w - 2 * margin;

    _actualPegRadius = GameConstants.pegRadius;
    final colSpacing = usableW / (GameConstants.pegColsWide - 1);
    final rowSpacing = boardH / (GameConstants.pegRows + 1);

    for (int row = 0; row < GameConstants.pegRows; row++) {
      final y = topY + (row + 1) * rowSpacing;
      if (row.isEven) {
        for (int col = 0; col < GameConstants.pegColsWide; col++) {
          _addPeg(Vector2(margin + col * colSpacing, y));
        }
      } else {
        for (int col = 0; col < GameConstants.pegColsNarrow; col++) {
          _addPeg(Vector2(margin + colSpacing / 2 + col * colSpacing, y));
        }
      }
    }

    _slotsY = botY + 10;
    _slotsBottom = _slotsY + h * GameConstants.slotHeightFraction;
    _slotWidth = w / GameConstants.numSlots;
  }

  void _addPeg(Vector2 pos) {
    pegs.add(pos);
    _basePegs.add(pos.clone());
    _isGold.add(false);
    _isHit.add(false);
    _isMoving.add(false);
  }

  /// Called once at game start to assign gold vs white pegs.
  void _assignPegTypes() {
    final rng = Random();
    for (int i = 0; i < pegs.length; i++) {
      _isGold[i] = rng.nextDouble() < GameConstants.goldPegChance;
      _isHit[i] = false;
    }
  }

  /// Called before each drop to set moving pegs for current difficulty.
  void prepareForDrop({
    required double moveChance,
    required double moveAmplitude,
  }) {
    final rng = Random();
    _moveAmplitude = moveAmplitude;
    for (int i = 0; i < pegs.length; i++) {
      _isMoving[i] = rng.nextDouble() < moveChance;
      if (!_isMoving[i]) {
        pegs[i].setFrom(_basePegs[i]);
      }
    }
  }

  /// Returns gold bonus points if gold peg hit for first time, else 0.
  int onPegHit(int index) {
    if (index < 0 || index >= pegs.length || _isHit[index]) return 0;
    _isHit[index] = true;
    return _isGold[index] ? GameConstants.goldPegBonus : 0;
  }

  void generateSlots() {
    final dm = game.difficultyManager;
    slotMultipliers = dm.generateMultipliers();
    final rng = Random();
    int placed = 0;
    while (placed < dm.skullCount && placed < GameConstants.numSlots - 1) {
      final idx = rng.nextInt(GameConstants.numSlots);
      if (slotMultipliers[idx] > 0) {
        slotMultipliers[idx] = 0;
        placed++;
      }
    }
  }

  bool isSkullSlot(int index) => slotMultipliers[index] == 0;
  double getMultiplier(int index) => slotMultipliers[index];

  int getSlotIndex(double x) {
    return (x / _slotWidth).floor().clamp(0, GameConstants.numSlots - 1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    for (int i = 0; i < pegs.length; i++) {
      if (_isMoving[i]) {
        pegs[i].x =
            _basePegs[i].x + sin(_time * 2.0 + i * 0.7) * _moveAmplitude;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // --- Pegs ---
    for (int i = 0; i < pegs.length; i++) {
      final offset = Offset(pegs[i].x, pegs[i].y);

      if (_isHit[i]) {
        canvas.drawCircle(offset, _actualPegRadius, _spentPegPaint);
      } else if (_isGold[i]) {
        canvas.drawCircle(offset, _actualPegRadius + 4, _goldGlowPaint);
        canvas.drawCircle(offset, _actualPegRadius, _goldPegPaint);
      } else {
        final glow = _isMoving[i] ? _movingGlowPaint : _pegGlowPaint;
        canvas.drawCircle(offset, _actualPegRadius + 3, glow);
        canvas.drawCircle(offset, _actualPegRadius, _pegPaint);
      }
    }

    // --- Slots ---
    final iconSize = _slotWidth * 0.50;

    for (int i = 0; i < slotMultipliers.length; i++) {
      final x = i * _slotWidth;
      final rect = Rect.fromLTWH(
          x + 2, _slotsY, _slotWidth - 4, _slotsBottom - _slotsY);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      final cx = x + _slotWidth / 2;
      final cy = _slotsY + (_slotsBottom - _slotsY) / 2;
      final isSkull = slotMultipliers[i] == 0;

      if (isSkull) {
        _slotFillPaint.color = const Color(0x30FF0000);
        _slotBorderPaint.color = const Color(0x66FF0000);
        canvas.drawRRect(rrect, _slotFillPaint);
        canvas.drawRRect(rrect, _slotBorderPaint);
        _circleSkull.render(
          canvas,
          position: Vector2(cx - iconSize / 2, cy - iconSize / 2),
          size: Vector2.all(iconSize),
        );
      } else {
        _slotFillPaint.color = const Color(0x3000FF00);
        _slotBorderPaint.color = const Color(0x6600FF00);
        canvas.drawRRect(rrect, _slotFillPaint);
        canvas.drawRRect(rrect, _slotBorderPaint);
        _slotTextPaint.render(
          canvas,
          '${slotMultipliers[i]}x',
          Vector2(cx, cy),
          anchor: Anchor.center,
        );
      }
    }
  }
}
