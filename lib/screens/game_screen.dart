import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/bounce_game.dart';
import '../models/ball_skin.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  final BallSkin skin;
  final VoidCallback onMainMenu;

  const GameScreen({
    super.key,
    required this.skin,
    required this.onMainMenu,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BounceGame _game;

  @override
  void initState() {
    super.initState();
    _game = BounceGame(skin: widget.skin);
  }

  void _goToMainMenu() {
    _game.overlays.remove('Pause');
    _game.overlays.remove('GameOver');
    if (_game.paused) _game.resumeEngine();
    widget.onMainMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: _game,
            overlayBuilderMap: {
              'Pause': (context, game) => PauseOverlay(
                    game: game as BounceGame,
                    onMainMenu: _goToMainMenu,
                  ),
              'GameOver': (context, game) => GameOverOverlay(
                    game: game as BounceGame,
                    onMainMenu: _goToMainMenu,
                  ),
            },
          ),
          // Pause button
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => _game.togglePause(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.pause, color: Colors.white70, size: 28),
              ),
            ),
          ),
          // COLLECT button
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _game.collectAvailable,
                builder: (context, available, _) {
                  if (!available) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => _game.collectCoins(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xCC00AA44),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.greenAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        'COLLECT  ${_game.scoreTracker.pendingCoins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
