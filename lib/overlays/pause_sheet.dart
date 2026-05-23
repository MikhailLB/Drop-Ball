import 'package:flutter/material.dart';
import '../game/drop_core.dart';

class PauseSheet extends StatelessWidget {
  final DropCore game;
  final VoidCallback onMenu;

  const PauseSheet({super.key, required this.game, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('PAUSED', style: TextStyle(
            color: Colors.white, fontSize: 46, fontWeight: FontWeight.bold,
            letterSpacing: 4, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)],
          )),
          const SizedBox(height: 36),
          _btn('RESUME',  Colors.cyanAccent,   () => game.togglePause()),
          const SizedBox(height: 14),
          _btn('MENU',    Colors.orangeAccent,  onMenu),
        ]),
      ),
    );
  }

  Widget _btn(String lbl, Color c, VoidCallback fn) => SizedBox(
    width: 220, height: 54,
    child: ElevatedButton(
      onPressed: fn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, foregroundColor: c,
        side: BorderSide(color: c, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
      ),
      child: Text(lbl, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: [Shadow(color: c, blurRadius: 10)])),
    ),
  );
}
