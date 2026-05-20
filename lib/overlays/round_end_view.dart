import 'package:flutter/material.dart';
import '../game/drop_game.dart';

class RoundEndView extends StatelessWidget {
  final NeonDropGame game;
  final VoidCallback onMainMenu;

  const RoundEndView({
    super.key,
    required this.game,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final result = game.endResult ?? DropResult.died;
    final amount = game.lastAmount;
    final balance = game.wallet.balance;

    String title;
    Color titleColor;
    String subtitle;

    switch (result) {
      case DropResult.died:
        title = 'SKULL HIT';
        titleColor = const Color(0xFFFF3355);
        subtitle = 'LOST: $amount — 30% saved as consolation';
      case DropResult.collected:
        title = 'CASHED OUT!';
        titleColor = const Color(0xFFCC66FF);
        subtitle = 'SAVED: $amount coins';
      case DropResult.won:
        title = 'ALL PEGS HIT!';
        titleColor = const Color(0xFFFFCC00);
        subtitle = 'BONUS 2x — SAVED: $amount coins';
    }

    return Container(
      color: const Color(0xCC0A001A),
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
            _btn('RETRY', const Color(0xFFCC66FF), () => game.restart()),
            const SizedBox(height: 16),
            _btn('MAIN MENU', const Color(0xFFFFCC00), onMainMenu),
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
