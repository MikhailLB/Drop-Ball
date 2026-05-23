import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;
import '../../utils/game_config.dart';
import '../../game/models/level_config.dart';
import '../bounce_game.dart';

class BoardLayout extends PositionComponent with HasGameReference<BounceGame> {
  final LevelConfig levelConfig;

  final List<Vector2> pegs = [];
  final List<Vector2> _basePegs = [];
  final List<bool> _isGold = [];
  final List<bool> _isHit = [];
  final List<bool> _isMoving = [];
  double _moveAmplitude = 0;
  double _time = 0;

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

  late final Sprite _skullIcon;

  final Paint _pegPaint = Paint()..color = const Color(0xFFDDCCFF);
  final Paint _pegGlowPaint = Paint()
    ..color = const Color(0x557788FF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _goldPegPaint = Paint()..color = const Color(0xFFFFCC00);
  final Paint _goldGlowPaint = Paint()
    ..color = const Color(0x77FFB800)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _spentPegPaint = Paint()..color = const Color(0xFF3D2060);
  final Paint _movingGlowPaint = Paint()
    ..color = const Color(0x66FF22CC)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _slotFillPaint = Paint();
  final Paint _slotBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  final TextPaint _slotTextPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFEEDDFF),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );

  BoardLayout({required this.levelConfig});

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = 0;
    _skullIcon = game.spriteRegistry.circleSkull;
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
    final topY = h * GameConfig.boardTopFraction;
    final botY = h * GameConfig.boardBottomFraction;
    final boardH = botY - topY;
    final margin = w * GameConfig.boardMarginFraction;
    final usableW = w - 2 * margin;

    _actualPegRadius = GameConfig.pegRadius;
    final colsWide = levelConfig.pegColsWide;
    final colsNarrow = colsWide - 1;
    final colSpacing = usableW / (colsWide - 1);
    final rowSpacing = boardH / (levelConfig.pegRows + 1);

    for (int row = 0; row < levelConfig.pegRows; row++) {
      final y = topY + (row + 1) * rowSpacing;
      if (row.isEven) {
        for (int col = 0; col < colsWide; col++) {
          _addPeg(Vector2(margin + col * colSpacing, y));
        }
      } else {
        for (int col = 0; col < colsNarrow; col++) {
          _addPeg(Vector2(margin + colSpacing / 2 + col * colSpacing, y));
        }
      }
    }

    _slotsY = botY + 10;
    _slotsBottom = _slotsY + h * GameConfig.slotHeightFraction;
    _slotWidth = w / GameConfig.numSlots;
  }

  void _addPeg(Vector2 pos) {
    pegs.add(pos);
    _basePegs.add(pos.clone());
    _isGold.add(false);
    _isHit.add(false);
    _isMoving.add(false);
  }

  void _assignPegTypes() {
    final rng = Random();
    for (int i = 0; i < pegs.length; i++) {
      _isGold[i] = rng.nextDouble() < GameConfig.goldPegChance;
      _isHit[i] = false;
    }
  }

  void prepareForDrop({
    required double moveChance,
    required double moveAmplitude,
  }) {
    final rng = Random();
    _moveAmplitude = moveAmplitude;
    for (int i = 0; i < pegs.length; i++) {
      _isMoving[i] = rng.nextDouble() < moveChance;
      if (!_isMoving[i]) pegs[i].setFrom(_basePegs[i]);
    }
  }

  int onPegHit(int index) {
    if (index < 0 || index >= pegs.length || _isHit[index]) return 0;
    _isHit[index] = true;
    return _isGold[index] ? GameConfig.goldPegBonus : 0;
  }

  void generateSlots() {
    final rng = Random();
    slotMultipliers = List.generate(GameConfig.numSlots, (_) {
      final v = levelConfig.minMultiplier +
          rng.nextDouble() *
              (levelConfig.maxMultiplier - levelConfig.minMultiplier);
      return double.parse(v.toStringAsFixed(1));
    });

    int placed = 0;
    while (placed < levelConfig.skullCount &&
        placed < GameConfig.numSlots - 1) {
      final idx = rng.nextInt(GameConfig.numSlots);
      if (slotMultipliers[idx] > 0) {
        slotMultipliers[idx] = 0;
        placed++;
      }
    }
  }

  bool isSkullSlot(int index) => slotMultipliers[index] == 0;
  double getMultiplier(int index) => slotMultipliers[index];

  int getSlotIndex(double x) {
    return (x / _slotWidth).floor().clamp(0, GameConfig.numSlots - 1);
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

      if (_isHit[i]) {
        canvas.drawCircle(offset, _actualPegRadius, _spentPegPaint);
      } else if (_isGold[i]) {
        canvas.drawCircle(offset, _actualPegRadius + 6, _goldGlowPaint);
        canvas.drawCircle(offset, _actualPegRadius, _goldPegPaint);
      } else {
        final glow = _isMoving[i] ? _movingGlowPaint : _pegGlowPaint;
        canvas.drawCircle(offset, _actualPegRadius + 5, glow);
        canvas.drawCircle(offset, _actualPegRadius, _pegPaint);
      }
    }

    final iconSize = _slotWidth * 0.50;

    for (int i = 0; i < slotMultipliers.length; i++) {
      final x = i * _slotWidth;
      final rect =
          Rect.fromLTWH(x + 2, _slotsY, _slotWidth - 4, _slotsBottom - _slotsY);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
      final cx = x + _slotWidth / 2;
      final cy = _slotsY + (_slotsBottom - _slotsY) / 2;
      final isSkull = slotMultipliers[i] == 0;

      if (isSkull) {
        _slotFillPaint.color = const Color(0x40CC0033);
        _slotBorderPaint.color = const Color(0x99FF0044);
        canvas.drawRRect(rrect, _slotFillPaint);
        canvas.drawRRect(rrect, _slotBorderPaint);
        _skullIcon.render(
          canvas,
          position: Vector2(cx - iconSize / 2, cy - iconSize / 2),
          size: Vector2.all(iconSize),
        );
      } else {
        _slotFillPaint.color = const Color(0x288833FF);
        _slotBorderPaint.color = const Color(0x99AA66FF);
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
