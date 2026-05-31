import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../resonance/game_mode.dart';
import '../services/progress_store.dart';
import 'collection_screen.dart';
import 'home_screen.dart';
import 'how_to_play_screen.dart';
import 'launch_screen.dart';
import 'level_select_screen.dart';
import 'mode_select_screen.dart';
import 'puzzle_screen.dart';

enum _Scene { launch, howTo, home, levels, modes, collection, puzzle }

class GameFlow extends StatefulWidget {
  const GameFlow({super.key});

  @override
  State<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<GameFlow> {
  _Scene _scene = _Scene.launch;
  GameMode _mode = GameMode.campaign;
  int _index = 1;

  void _go(_Scene s) => setState(() => _scene = s);

  void _openPuzzle(GameMode mode, int index) => setState(() {
        _mode = mode;
        _index = index;
        _scene = _Scene.puzzle;
      });

  void _playCampaign(int level) => _openPuzzle(GameMode.campaign, level);

  void _onLaunchDone() {
    // The loading screen is free to rotate; the game itself is portrait-only.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    _go(ProgressStore.instance.tutorialDone ? _Scene.home : _Scene.howTo);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _buildScene(),
    );
  }

  Widget _buildScene() {
    switch (_scene) {
      case _Scene.launch:
        return LaunchScreen(
          key: const ValueKey('launch'),
          onReady: _onLaunchDone,
        );
      case _Scene.howTo:
        return HowToPlayScreen(
          key: const ValueKey('howto'),
          onDone: () => _go(_Scene.home),
        );
      case _Scene.home:
        return HomeScreen(
          key: const ValueKey('home'),
          onPlay: _playCampaign,
          onLevels: () => _go(_Scene.levels),
          onModes: () => _go(_Scene.modes),
          onCollection: () => _go(_Scene.collection),
          onHowTo: () => _go(_Scene.howTo),
        );
      case _Scene.levels:
        return LevelSelectScreen(
          key: const ValueKey('levels'),
          onPick: _playCampaign,
          onBack: () => _go(_Scene.home),
        );
      case _Scene.modes:
        return ModeSelectScreen(
          key: const ValueKey('modes'),
          onOpen: _openPuzzle,
          onCampaign: _playCampaign,
          onBack: () => _go(_Scene.home),
        );
      case _Scene.collection:
        return CollectionScreen(
          key: const ValueKey('collection'),
          onBack: () => _go(_Scene.home),
        );
      case _Scene.puzzle:
        return PuzzleScreen(
          key: ValueKey('puzzle_${_mode.name}_$_index'),
          mode: _mode,
          index: _index,
          onMenu: () => _go(_Scene.home),
          onOpen: _openPuzzle,
        );
    }
  }
}
