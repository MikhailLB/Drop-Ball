import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/drop_core.dart';
import '../game/models/stage_config.dart';
import '../models/orb_skin.dart';
import '../overlays/result_sheet.dart';
import '../overlays/pause_sheet.dart';

class ArenaView extends StatefulWidget {
  final OrbSkin  skin;
  final StageConfig stage;
  final VoidCallback onMenu;
  final void Function(int n)? onNextStage;

  const ArenaView({super.key, required this.skin, required this.stage, required this.onMenu, this.onNextStage});

  @override
  State<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  late DropCore _core;

  @override
  void initState() {
    super.initState();
    _core = DropCore(skin: widget.skin, stage: widget.stage);
  }

  void _goMenu() {
    _core.overlays.remove('Result');
    _core.overlays.remove('Paused');
    if (_core.paused) _core.resumeEngine();
    widget.onMenu();
  }

  void _goNext() {
    _core.overlays.remove('Result');
    if (_core.paused) _core.resumeEngine();
    widget.onNextStage?.call(widget.stage.number + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        GameWidget(
          game: _core,
          overlayBuilderMap: {
            'Paused': (ctx, g) => PauseSheet(game: g as DropCore, onMenu: _goMenu),
            'Result': (ctx, g) => ResultSheet(game: g as DropCore, onMenu: _goMenu, onNext: _goNext),
          },
        ),
        // Pause button
        Positioned(
          top: 96, right: 16,
          child: GestureDetector(
            onTap: () => _core.togglePause(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.black45, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.pause, color: Colors.white70, size: 28),
            ),
          ),
        ),
        // Bank button
        Positioned(
          bottom: 16, left: 0, right: 0,
          child: Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: _core.canBank,
              builder: (ctx, ok, _) {
                if (!ok) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => _core.bankNow(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xCC00AA44),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.greenAccent, width: 2),
                      boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.4), blurRadius: 12)],
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _core.canBank,
                        builder: (ctx2, val2, ch2) => Text(
                        'BANK  ${_core.ledger.pending}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
