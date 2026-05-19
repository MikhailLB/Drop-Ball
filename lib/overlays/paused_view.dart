import 'package:flutter/material.dart';
import '../game/drop_game.dart';

class PausedView extends StatelessWidget {
  final NeonDropGame game;
  final VoidCallback onMainMenu;

  const PausedView({
    super.key,
    required this.game,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 40),
            _btn('RESUME', Colors.cyanAccent, () => game.togglePause()),
            const SizedBox(height: 16),
            _btn('MAIN MENU', Colors.orangeAccent, onMainMenu),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: color, blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}
