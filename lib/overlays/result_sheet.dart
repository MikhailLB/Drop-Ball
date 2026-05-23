import 'package:flutter/material.dart';
import '../game/drop_core.dart';
import '../game/models/stage_config.dart';

class ResultSheet extends StatelessWidget {
  final DropCore game;
  final VoidCallback onMenu;
  final VoidCallback onNext;

  const ResultSheet({super.key, required this.game, required this.onMenu, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final res      = game.result ?? DropResult.trapHit;
    final session  = game.ledger.session;
    final goal     = game.stageCtrl.cfg.goal;
    final lvNum    = game.stageCtrl.cfg.number;
    final tint     = game.stageCtrl.cfg.tint;
    final isLast   = lvNum >= StageBook.count;

    String title; Color titleCol; bool showNext;
    switch (res) {
      case DropResult.stageCleared:
        title = 'STAGE CLEAR!'; titleCol = Colors.amberAccent; showNext = !isLast;
      case DropResult.trapHit:
        title = 'STAGE FAILED'; titleCol = Colors.redAccent; showNext = false;
      case DropResult.banked:
        title = 'BANKED!'; titleCol = Colors.greenAccent; showNext = false;
    }

    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: titleCol.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [BoxShadow(color: titleCol.withValues(alpha: 0.12), blurRadius: 28, spreadRadius: 4)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(
              color: titleCol, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2,
              shadows: [Shadow(color: titleCol, blurRadius: 20)],
            )),
            const SizedBox(height: 14),
            _progress(session, goal, tint),
            const SizedBox(height: 10),
            Text('$session / $goal', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),
            _btn('RETRY',     tint,             () => game.restart()),
            if (showNext) ...[const SizedBox(height: 10), _btn('NEXT STAGE', Colors.amberAccent, onNext)],
            const SizedBox(height: 10),
            _btn('MENU',      Colors.white38,    onMenu),
          ]),
        ),
      ),
    );
  }

  Widget _progress(int val, int max, Color c) {
    final p = (val / max).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(value: p, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(c), minHeight: 8),
    );
  }

  Widget _btn(String lbl, Color c, VoidCallback fn) => SizedBox(
    width: double.infinity, height: 48,
    child: ElevatedButton(
      onPressed: fn,
      style: ElevatedButton.styleFrom(
        backgroundColor: c.withValues(alpha: 0.1), foregroundColor: c,
        side: BorderSide(color: c.withValues(alpha: 0.55), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
      ),
      child: Text(lbl, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: [Shadow(color: c, blurRadius: 8)])),
    ),
  );
}
