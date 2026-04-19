import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/gravity_rush_game.dart';
import '../models/skin_data.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  final SkinData skin;
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
  late GravityRushGame _game;

  @override
  void initState() {
    super.initState();
    _game = GravityRushGame(skin: widget.skin);
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
                    game: game as GravityRushGame,
                    onMainMenu: _goToMainMenu,
                  ),
              'GameOver': (context, game) => GameOverOverlay(
                    game: game as GravityRushGame,
                    onMainMenu: _goToMainMenu,
                  ),
            },
          ),
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
                child: const Icon(
                  Icons.pause,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
