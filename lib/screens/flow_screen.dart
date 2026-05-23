import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/models/level_config.dart';
import '../models/ball_skin.dart';
import 'arena_screen.dart';
import 'level_select_screen.dart';
import 'loading_screen.dart';
import 'lobby_screen.dart';

enum _FlowState { loading, menu, levelSelect, game }

class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  _FlowState _state = _FlowState.loading;
  BallSkin _selectedSkin = BallSkin.allSkins[0];
  LevelConfig _selectedLevel = Levels.all[0];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _onLoadingComplete() {
    setState(() => _state = _FlowState.menu);
  }

  void _onPlayFromMenu(BallSkin skin) {
    _selectedSkin = skin;
    setState(() => _state = _FlowState.levelSelect);
  }

  void _onLevelSelected(LevelConfig level, BallSkin skin) {
    setState(() {
      _selectedLevel = level;
      _selectedSkin = skin;
      _state = _FlowState.game;
    });
  }

  void _onMainMenu() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setState(() => _state = _FlowState.menu);
  }

  void _onBackFromLevelSelect() {
    setState(() => _state = _FlowState.menu);
  }

  Future<void> _onNextLevel(int nextLevelNumber) async {
    if (nextLevelNumber > Levels.count) {
      _onMainMenu();
      return;
    }

    // Persist progress: mark current level completed + unlock next
    final prefs = await SharedPreferences.getInstance();
    final highest = prefs.getInt('highest_unlocked_level') ?? 1;
    final completedList =
        (prefs.getStringList('completed_levels') ?? []).toSet();

    completedList.add('${_selectedLevel.number}');
    final newHighest = nextLevelNumber > highest ? nextLevelNumber : highest;

    await prefs.setInt('highest_unlocked_level', newHighest);
    await prefs.setStringList('completed_levels', completedList.toList());

    final nextLevel = Levels.get(nextLevelNumber);
    final nextSkin = BallSkin.getById(nextLevel.sphereSkinId);

    if (!mounted) return;
    setState(() {
      _selectedLevel = nextLevel;
      _selectedSkin = nextSkin;
      _state = _FlowState.game;
    });
  }

  Future<void> _onLevelComplete() async {
    // Persist when player completes current level
    final prefs = await SharedPreferences.getInstance();
    final highest = prefs.getInt('highest_unlocked_level') ?? 1;
    final completedList =
        (prefs.getStringList('completed_levels') ?? []).toSet();

    completedList.add('${_selectedLevel.number}');
    final nextNum = _selectedLevel.number + 1;
    final newHighest = nextNum > highest ? nextNum : highest;

    await prefs.setInt('highest_unlocked_level', newHighest);
    await prefs.setStringList('completed_levels', completedList.toList());
  }

  @override
  Widget build(BuildContext context) {
    // Enforce portrait-only for game and menu screens
    if (_state == _FlowState.game ||
        _state == _FlowState.menu ||
        _state == _FlowState.levelSelect) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    switch (_state) {
      case _FlowState.loading:
        return LoadingScreen(onLoadingComplete: _onLoadingComplete);

      case _FlowState.menu:
        return MainMenuScreen(onPlay: _onPlayFromMenu);

      case _FlowState.levelSelect:
        return LevelSelectScreen(
          onLevelSelected: _onLevelSelected,
          onBack: _onBackFromLevelSelect,
        );

      case _FlowState.game:
        return GameScreen(
          key: ValueKey('game_${_selectedLevel.number}'),
          skin: _selectedSkin,
          levelConfig: _selectedLevel,
          onMainMenu: _onMainMenu,
          onNextLevel: (nextNum) async {
            await _onLevelComplete();
            await _onNextLevel(nextNum);
          },
        );
    }
  }
}
