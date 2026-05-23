import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;
import '../../utils/drop_config.dart';
import '../models/stage_config.dart';
import '../drop_core.dart';

class PegField extends PositionComponent with HasGameReference<DropCore> {
  final StageConfig stage;
  final List<Vector2> pegs = [];
  final List<Vector2> _base = [];
  final List<bool> _gold    = [];
  final List<bool> _struck  = [];
  final List<bool> _moving  = [];
  double _swingAmp  = 0;
  double _clock     = 0;
  List<double> slotValues = [];
  double _slotW  = 0;
  double _floorY = 0;
  double _floorB = 0;
  double _pegR   = 0;

  double get floorY    => _floorY;
  double get actualPegR => _pegR;

  int get totalPegs => _gold.where((g) => !g).length;
  int get struckPegs {
    int c = 0;
    for (int i = 0; i < pegs.length; i++) {
      if (!_gold[i] && _struck[i]) c++;
    }
    return c;
  }

  late final Sprite _trap;

  final Paint _pPaint  = Paint()..color = const Color(0xFFDDCCFF);
  final Paint _pGlow   = Paint()..color = const Color(0x557788FF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _pGold   = Paint()..color = const Color(0xFFFFCC00);
  final Paint _pGoldG  = Paint()..color = const Color(0x77FFB800)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _pSpent  = Paint()..color = const Color(0xFF3D2060);
  final Paint _pMove   = Paint()..color = const Color(0x66FF22CC)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _sFill   = Paint();
  final Paint _sBorder = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8;
  final TextPaint _sText = TextPaint(
    style: const TextStyle(color: Color(0xFFEEDDFF), fontSize: 14, fontWeight: FontWeight.bold),
  );

  PegField({required this.stage});

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = 0;
    _trap = game.orbCache.trapMarker;
    _buildGrid();
    _assignTypes();
    randomiseSlots();
  }

  void _buildGrid() {
    pegs.clear(); _base.clear(); _gold.clear(); _struck.clear(); _moving.clear();
    final w = size.x, h = size.y;
    final topY = h * DropConfig.boardTop,  botY = h * DropConfig.boardBottom;
    final margin = w * DropConfig.boardMargin;
    final usable = w - 2 * margin;
    _pegR = DropConfig.pegRadius;
    final wide = stage.pegColsWide, narrow = wide - 1;
    final colGap = usable / (wide - 1);
    final rowGap = (botY - topY) / (stage.pegRows + 1);
    for (int r = 0; r < stage.pegRows; r++) {
      final y = topY + (r + 1) * rowGap;
      if (r.isEven) {
        for (int c = 0; c < wide; c++) { _addPeg(Vector2(margin + c * colGap, y)); }
      } else {
        for (int c = 0; c < narrow; c++) { _addPeg(Vector2(margin + colGap / 2 + c * colGap, y)); }
      }
    }
    _floorY = botY + 10;
    _floorB = _floorY + h * DropConfig.slotHeight;
    _slotW  = w / DropConfig.slotCount;
  }

  void _addPeg(Vector2 p) {
    pegs.add(p); _base.add(p.clone());
    _gold.add(false); _struck.add(false); _moving.add(false);
  }

  void _assignTypes() {
    final rng = Random();
    for (int i = 0; i < pegs.length; i++) {
      _gold[i]   = rng.nextDouble() < DropConfig.goldChance;
      _struck[i] = false;
    }
  }

  void prepDrop({required double chance, required double amp}) {
    final rng = Random();
    _swingAmp = amp;
    for (int i = 0; i < pegs.length; i++) {
      _moving[i] = rng.nextDouble() < chance;
      if (!_moving[i]) pegs[i].setFrom(_base[i]);
    }
  }

  int onStrike(int idx) {
    if (idx < 0 || idx >= pegs.length || _struck[idx]) return 0;
    _struck[idx] = true;
    return _gold[idx] ? DropConfig.goldBonus : 0;
  }

  void randomiseSlots() {
    final rng = Random();
    slotValues = List.generate(DropConfig.slotCount, (_) {
      final v = stage.minMulti + rng.nextDouble() * (stage.maxMulti - stage.minMulti);
      return double.parse(v.toStringAsFixed(1));
    });
    int placed = 0;
    while (placed < stage.trapCount && placed < DropConfig.slotCount - 1) {
      final idx = rng.nextInt(DropConfig.slotCount);
      if (slotValues[idx] > 0) { slotValues[idx] = 0; placed++; }
    }
  }

  bool isTrap(int i)     => slotValues[i] == 0;
  double multiAt(int i)  => slotValues[i];
  int slotFor(double x)  => (x / _slotW).floor().clamp(0, DropConfig.slotCount - 1);

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    for (int i = 0; i < pegs.length; i++) {
      if (_moving[i]) pegs[i].x = _base[i].x + sin(_clock * 2.0 + i * 0.7) * _swingAmp;
    }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < pegs.length; i++) {
      final o = Offset(pegs[i].x, pegs[i].y);
      if (_struck[i]) {
        canvas.drawCircle(o, _pegR, _pSpent);
      } else if (_gold[i]) {
        canvas.drawCircle(o, _pegR + 6, _pGoldG);
        canvas.drawCircle(o, _pegR, _pGold);
      } else {
        canvas.drawCircle(o, _pegR + 5, _moving[i] ? _pMove : _pGlow);
        canvas.drawCircle(o, _pegR, _pPaint);
      }
    }
    final ico = _slotW * 0.50;
    for (int i = 0; i < slotValues.length; i++) {
      final x    = i * _slotW;
      final rect = Rect.fromLTWH(x + 2, _floorY, _slotW - 4, _floorB - _floorY);
      final rr   = RRect.fromRectAndRadius(rect, const Radius.circular(10));
      final cx   = x + _slotW / 2, cy = _floorY + (_floorB - _floorY) / 2;
      if (slotValues[i] == 0) {
        _sFill.color   = const Color(0x40CC0033);
        _sBorder.color = const Color(0x99FF0044);
        canvas.drawRRect(rr, _sFill); canvas.drawRRect(rr, _sBorder);
        _trap.render(canvas, position: Vector2(cx - ico / 2, cy - ico / 2), size: Vector2.all(ico));
      } else {
        _sFill.color   = const Color(0x288833FF);
        _sBorder.color = const Color(0x99AA66FF);
        canvas.drawRRect(rr, _sFill); canvas.drawRRect(rr, _sBorder);
        _sText.render(canvas, '${slotValues[i]}x', Vector2(cx, cy), anchor: Anchor.center);
      }
    }
  }
}
