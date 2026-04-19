import 'package:flutter/material.dart';
import '../game/gravity_rush_game.dart';

class GameOverOverlay extends StatelessWidget {
  final GravityRushGame game;
  final VoidCallback onMainMenu;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final score = game.scoreManager.score;
    final highScore = game.scoreManager.highScore;
    final isNewRecord = score >= highScore && score > 0;

    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [
                  Shadow(color: Colors.red, blurRadius: 20),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (isNewRecord)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'NEW RECORD!',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.amber, blurRadius: 15)],
                  ),
                ),
              ),
            Text(
              'SCORE: $score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'BEST: $highScore',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 40),
            _buildButton('RETRY', Colors.cyanAccent, () {
              game.restart();
            }),
            const SizedBox(height: 16),
            _buildButton('MAIN MENU', Colors.orangeAccent, onMainMenu),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
