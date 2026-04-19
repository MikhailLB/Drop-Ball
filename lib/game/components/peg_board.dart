import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import '../../utils/constants.dart';
import '../gravity_rush_game.dart';

enum SlotType { score, score2x, skull }

class PegBoard extends PositionComponent
    with HasGameReference<GravityRushGame> {
  final List<Vector2> pegs = [];
  final List<Vector2> _basePegs = [];
  final List<bool> _isGold = [];
  final List<bool> _isHit = [];
  final List<bool> _isMoving = [];
  double _moveAmplitude = 0;
  double _time = 0;

  List<SlotType> slots = [];

  double _slotWidth = 0;
  double _slotsY = 0;
  double _slotsBottom = 0;
  double _actualPegRadius = 0;

  double get slotsY => _slotsY;
  double get actualPegRadius => _actualPegRadius;

  late final Sprite _greenCircle;
  late final Sprite _circle2x;
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

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = 0;
    _greenCircle = game.spriteCache.greenCircle;
    _circle2x = game.spriteCache.circle2x;
    _circleSkull = game.spriteCache.circleSkull;
    _buildLayout();
    generateSlots(skullCount: 1, bonus2xCount: 1);
    prepareForDrop(
      goldChance: game.difficultyManager.goldPegChance,
      moveChance: game.difficultyManager.movingPegChance,
      moveAmplitude: game.difficultyManager.movingPegAmplitude,
    );
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

  void prepareForDrop({
    required double goldChance,
    required double moveChance,
    required double moveAmplitude,
  }) {
    final rng = Random();
    _moveAmplitude = moveAmplitude;
    for (int i = 0; i < pegs.length; i++) {
      _isGold[i] = rng.nextDouble() < goldChance;
      _isHit[i] = false;
      _isMoving[i] = rng.nextDouble() < moveChance;
      if (!_isMoving[i]) {
        pegs[i].setFrom(_basePegs[i]);
      }
    }
  }

  /// Returns bonus points awarded (goldPegBonus for gold, 0 for normal).
  int onPegHit(int index) {
    if (index < 0 || index >= pegs.length || _isHit[index]) return 0;
    _isHit[index] = true;
    return _isGold[index] ? GameConstants.goldPegBonus : 0;
  }

  void generateSlots({required int skullCount, required int bonus2xCount}) {
    slots = List.filled(GameConstants.numSlots, SlotType.score);
    final rng = Random();

    int placed = 0;
    while (placed < skullCount && placed < GameConstants.numSlots - 2) {
      final idx = rng.nextInt(GameConstants.numSlots);
      if (slots[idx] == SlotType.score) {
        slots[idx] = SlotType.skull;
        placed++;
      }
    }

    placed = 0;
    while (placed < bonus2xCount) {
      final idx = rng.nextInt(GameConstants.numSlots);
      if (slots[idx] == SlotType.score) {
        slots[idx] = SlotType.score2x;
        placed++;
      }
    }
  }

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
    for (int i = 0; i < pegs.length; i++) {
      final offset = Offset(pegs[i].x, pegs[i].y);

      if (_isGold[i] && !_isHit[i]) {
        canvas.drawCircle(offset, _actualPegRadius + 4, _goldGlowPaint);
        canvas.drawCircle(offset, _actualPegRadius, _goldPegPaint);
      } else if (_isGold[i]) {
        canvas.drawCircle(offset, _actualPegRadius, _spentPegPaint);
      } else if (_isMoving[i]) {
        canvas.drawCircle(offset, _actualPegRadius + 3, _movingGlowPaint);
        canvas.drawCircle(offset, _actualPegRadius, _pegPaint);
      } else {
        canvas.drawCircle(offset, _actualPegRadius + 3, _pegGlowPaint);
        canvas.drawCircle(offset, _actualPegRadius, _pegPaint);
      }
    }

    final iconSize = _slotWidth * 0.55;

    for (int i = 0; i < slots.length; i++) {
      final x = i * _slotWidth;
      final rect = Rect.fromLTWH(
          x + 2, _slotsY, _slotWidth - 4, _slotsBottom - _slotsY);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      Color bg;
      Color border;
      Sprite icon;

      switch (slots[i]) {
        case SlotType.score:
          bg = const Color(0x3000FF00);
          border = const Color(0x6600FF00);
          icon = _greenCircle;
        case SlotType.score2x:
          bg = const Color(0x30FFD700);
          border = const Color(0x66FFD700);
          icon = _circle2x;
        case SlotType.skull:
          bg = const Color(0x30FF0000);
          border = const Color(0x66FF0000);
          icon = _circleSkull;
      }

      _slotFillPaint.color = bg;
      _slotBorderPaint.color = border;
      canvas.drawRRect(rrect, _slotFillPaint);
      canvas.drawRRect(rrect, _slotBorderPaint);

      final cx = x + _slotWidth / 2;
      final cy = _slotsY + (_slotsBottom - _slotsY) / 2;
      icon.render(
        canvas,
        position: Vector2(cx - iconSize / 2, cy - iconSize / 2),
        size: Vector2.all(iconSize),
      );
    }
  }
}
