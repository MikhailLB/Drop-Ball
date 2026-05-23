import 'package:flutter/material.dart';
import '../game/bounce_game.dart';
import '../game/models/level_config.dart';

class GameOverOverlay extends StatelessWidget {
  final BounceGame game;
  final VoidCallback onMainMenu;
  final VoidCallback onNextLevel;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onMainMenu,
    required this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final reason = game.endReason ?? GameEndReason.skullDied;
    final sessionScore = game.scoreTracker.sessionScore;
    final target = game.levelController.config.targetScore;
    final levelNum = game.levelController.config.number;
    final themeColor = game.levelController.config.themeColor;
    final isLastLevel = levelNum >= Levels.count;

    String title;
    Color titleColor;
    String subtitle;
    bool showNextLevel;

    switch (reason) {
      case GameEndReason.levelComplete:
        title = 'LEVEL COMPLETE!';
        titleColor = Colors.amberAccent;
        subtitle = 'Score: $sessionScore / $target';
        showNextLevel = !isLastLevel;
      case GameEndReason.skullDied:
        title = 'LEVEL FAILED';
        titleColor = Colors.redAccent;
        subtitle = 'Score: $sessionScore / $target';
        showNextLevel = false;
      case GameEndReason.collected:
        title = 'BANKED!';
        titleColor = Colors.greenAccent;
        subtitle = 'Score: $sessionScore / $target';
        showNextLevel = false;
    }

    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: titleColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: titleColor.withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: titleColor, blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 16),
              _buildProgressBar(sessionScore, target, themeColor),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildButton(
                'RETRY',
                themeColor,
                () => game.restart(),
              ),
              const SizedBox(height: 12),
              if (showNextLevel)
                _buildButton(
                  'NEXT LEVEL',
                  Colors.amberAccent,
                  onNextLevel,
                ),
              if (showNextLevel) const SizedBox(height: 12),
              _buildButton(
                'MAIN MENU',
                Colors.white38,
                onMainMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int score, int target, Color color) {
    final progress = (score / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
      String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}
