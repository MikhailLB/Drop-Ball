import 'package:flutter/material.dart';

import '../models/orb_skin.dart';
import '../resonance/board_engine.dart';
import '../resonance/game_mode.dart';
import '../resonance/level_book.dart';
import '../services/progress_store.dart';
import '../widgets/aurora_background.dart';
import '../widgets/board_view.dart';

class PuzzleScreen extends StatefulWidget {
  final GameMode mode;
  final int index; // campaign: level number · endless: step · daily: unused
  final VoidCallback onMenu;
  final void Function(GameMode mode, int index) onOpen;

  const PuzzleScreen({
    super.key,
    required this.mode,
    required this.index,
    required this.onMenu,
    required this.onOpen,
  });

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late LevelSpec _spec;
  late BoardEngine _engine;
  late OrbSkin _orb;
  int? _moveLimit;

  bool _won = false;
  bool _failed = false;
  int _earnedStars = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _spec = switch (widget.mode) {
      GameMode.campaign => LevelBook.at(widget.index),
      GameMode.daily => ModeFactory.daily(DateTime.now()),
      GameMode.endless => ModeFactory.endless(widget.index),
    };
    _engine = BoardEngine(_spec);
    _orb = ProgressStore.instance.activeOrb;
    _moveLimit =
        widget.mode == GameMode.endless ? ModeFactory.budgetFor(_engine.par) : null;
    _won = false;
    _failed = false;
    _earnedStars = 0;
  }

  Color get _tint => switch (widget.mode) {
        GameMode.campaign => _spec.tint,
        GameMode.daily => ModeFactory.dailyTint,
        GameMode.endless => ModeFactory.endlessTint,
      };

  void _onTap(int r, int c) {
    if (_won || _failed) return;
    setState(() {
      _engine.tap(r, c);
      if (_engine.isSolved) {
        _finish();
      } else if (_moveLimit != null && _engine.moves >= _moveLimit!) {
        _fail();
      }
    });
  }

  Future<void> _finish() async {
    _won = true;
    _earnedStars = _engine.earnedStars;
    final store = ProgressStore.instance;
    switch (widget.mode) {
      case GameMode.campaign:
        await store.recordResult(_spec.number, _earnedStars);
        break;
      case GameMode.daily:
        final now = DateTime.now();
        final today = ModeFactory.dailyKey(now);
        final yesterday =
            ModeFactory.dailyKey(now.subtract(const Duration(days: 1)));
        await store.markDailySolved(today, yesterday);
        break;
      case GameMode.endless:
        await store.recordEndless(widget.index + 1);
        break;
    }
    if (mounted) setState(() {});
  }

  void _fail() {
    _failed = true;
    ProgressStore.instance.recordEndless(widget.index);
  }

  void _restart() => setState(() {
        _engine.reset();
        _won = false;
        _failed = false;
        _earnedStars = 0;
      });

  bool get _campaignHasNext =>
      widget.mode == GameMode.campaign && _spec.number < LevelBook.count;

  void _advance() {
    switch (widget.mode) {
      case GameMode.campaign:
        if (_campaignHasNext) {
          widget.onOpen(GameMode.campaign, _spec.number + 1);
        } else {
          widget.onMenu();
        }
        break;
      case GameMode.endless:
        widget.onOpen(GameMode.endless, widget.index + 1);
        break;
      case GameMode.daily:
        widget.onMenu();
        break;
    }
  }

  String get _headerTitle => switch (widget.mode) {
        GameMode.campaign => _spec.title.toUpperCase(),
        GameMode.daily => 'DAILY CHALLENGE',
        GameMode.endless => 'ENDLESS',
      };

  String get _headerSub => switch (widget.mode) {
        GameMode.campaign => 'LEVEL ${_spec.number}',
        GameMode.daily => 'TODAY',
        GameMode.endless => 'BOARD ${widget.index + 1}',
      };

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      tint: _tint,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _header(),
                _stats(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                    child: BoardView(
                      engine: _engine,
                      orb: _orb,
                      locked: _won || _failed,
                      onTap: _onTap,
                    ),
                  ),
                ),
              ],
            ),
            if (_won) _winOverlay(),
            if (_failed) _failOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
        child: Row(
          children: [
            _iconButton(Icons.arrow_back_ios_new, widget.onMenu),
            const Spacer(),
            Column(
              children: [
                Text(_headerSub,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        letterSpacing: 4)),
                Text(_headerTitle,
                    style: TextStyle(
                        color: _tint,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [Shadow(color: _tint, blurRadius: 14)])),
              ],
            ),
            const Spacer(),
            _iconButton(Icons.refresh_rounded, _restart),
          ],
        ),
      );

  Widget _stats() {
    final limited = _moveLimit != null;
    final left =
        limited ? (_moveLimit! - _engine.moves) : _engine.dimRemaining;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statChip('MOVES', '${_engine.moves}', _tint),
          const SizedBox(width: 10),
          _statChip('PAR', '${_engine.par}',
              Colors.white.withValues(alpha: 0.75)),
          const SizedBox(width: 10),
          _statChip(limited ? 'BUDGET' : 'LEFT', '$left',
              const Color(0xFFFFD54F)),
          const SizedBox(width: 10),
          _ruleChip(),
        ],
      ),
    );
  }

  Widget _ruleChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Text('LINK',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 9,
                    letterSpacing: 2)),
            const SizedBox(height: 2),
            Text(_spec.rule.glyph,
                style: TextStyle(
                    color: _tint,
                    fontSize: 18,
                    height: 1.0,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _statChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 9,
                    letterSpacing: 2)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _iconButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      );

  Widget _scrim(Widget panel) => Positioned.fill(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          tween: Tween(begin: 0, end: 1),
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
          ),
          child: Container(
            color: Colors.black.withValues(alpha: 0.64),
            alignment: Alignment.center,
            child: panel,
          ),
        ),
      );

  Widget _winOverlay() {
    final nextLabel = switch (widget.mode) {
      GameMode.campaign => _campaignHasNext ? 'NEXT LEVEL' : 'FINISH',
      GameMode.endless => 'NEXT BOARD',
      GameMode.daily => 'DONE',
    };
    return _scrim(_panel(
      title: 'SYNCED',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final on = i < _earnedStars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  on ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 46,
                  color: on
                      ? const Color(0xFFFFD54F)
                      : Colors.white.withValues(alpha: 0.18),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text('Solved in ${_engine.moves} moves · par ${_engine.par}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _overlayButton('MENU',
                    Colors.white.withValues(alpha: 0.7),
                    filled: false, onTap: widget.onMenu),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _overlayButton('RETRY',
                    Colors.white.withValues(alpha: 0.7),
                    filled: false, onTap: _restart),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _overlayButton(nextLabel, _tint, filled: true, onTap: _advance),
        ],
      ),
    ));
  }

  Widget _failOverlay() {
    return _scrim(_panel(
      title: 'OUT OF MOVES',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('You cleared ${widget.index} boards',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text('Best: ${ProgressStore.instance.endlessBest}',
              style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _overlayButton('MENU',
                    Colors.white.withValues(alpha: 0.7),
                    filled: false, onTap: widget.onMenu),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _overlayButton('RETRY', _tint,
                    filled: true,
                    onTap: () => widget.onOpen(GameMode.endless, 0)),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _panel({required String title, required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
        decoration: BoxDecoration(
          color: const Color(0xFF120B22),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _tint.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: _tint.withValues(alpha: 0.3), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: TextStyle(
                    color: _tint,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                    shadows: [Shadow(color: _tint, blurRadius: 18)])),
            const SizedBox(height: 18),
            child,
          ],
        ),
      );

  Widget _overlayButton(String label, Color color,
      {required bool filled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: filled
              ? color.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
              color: filled ? color : Colors.white.withValues(alpha: 0.18),
              width: filled ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: filled ? color : Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 3)),
      ),
    );
  }
}
