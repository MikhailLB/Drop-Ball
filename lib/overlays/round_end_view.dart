import 'package:flutter/material.dart';
import '../game/bounce_game.dart';

class GameOverOverlay extends StatelessWidget {
  final BounceGame game;
  final VoidCallback onMainMenu;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final reason = game.endReason ?? GameEndReason.died;
    final amount = game.lastAmount;
    final balance = game.scoreTracker.balance;

    String title;
    Color titleColor;
    String subtitle;

    switch (reason) {
      case GameEndReason.died:
        title = 'GAME OVER';
        titleColor = Colors.redAccent;
        subtitle = 'BURNED: $amount coins';
      case GameEndReason.collected:
        title = 'COLLECTED!';
        titleColor = Colors.greenAccent;
        subtitle = 'SAVED: $amount coins';
      case GameEndReason.won:
        title = 'ALL PEGS HIT!';
        titleColor = Colors.amberAccent;
        subtitle = 'BONUS 2× — SAVED: $amount coins';
    }

    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 44,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [Shadow(color: titleColor, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'BALANCE: $balance',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
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
