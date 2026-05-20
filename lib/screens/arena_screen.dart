import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/drop_game.dart';
import '../models/ball_skin.dart';
import '../overlays/paused_view.dart';
import '../overlays/round_end_view.dart';

class ArenaScreen extends StatefulWidget {
  final BallSkin skin;
  final VoidCallback onMainMenu;

  const ArenaScreen({
    super.key,
    required this.skin,
    required this.onMainMenu,
  });

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late NeonDropGame _game;

  @override
  void initState() {
    super.initState();
    _game = NeonDropGame(skin: widget.skin);
  }

  void _goToLobby() {
    _game.overlays.remove('Halted');
    _game.overlays.remove('RoundEnd');
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
              'Halted': (context, game) => PausedView(
                    game: game as NeonDropGame,
                    onMainMenu: _goToLobby,
                  ),
              'RoundEnd': (context, game) => RoundEndView(
                    game: game as NeonDropGame,
                    onMainMenu: _goToLobby,
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
                  color: const Color(0xAA1A0033),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x66AA66FF)),
                ),
                child: const Icon(Icons.pause, color: Color(0xCCBB99FF), size: 28),
              ),
            ),
          ),
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
                        color: const Color(0xCC5500AA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFAA66FF),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9933FF).withValues(alpha: 0.5),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Text(
                        'COLLECT  ${_game.wallet.pending}',
                        style: const TextStyle(
                          color: Color(0xFFFFCC00),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [Shadow(color: Color(0xFFFFAA00), blurRadius: 8)],
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
