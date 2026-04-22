import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/skin_data.dart';
import 'game_screen.dart';
import 'loading_screen.dart';
import 'main_menu_screen.dart';

enum _GameFlowState { loading, menu, game }

class GameFlowScreen extends StatefulWidget {
  const GameFlowScreen({super.key});

  @override
  State<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends State<GameFlowScreen> {
  _GameFlowState _state = _GameFlowState.loading;
  SkinData _selectedSkin = SkinData.allSkins[0];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
    setState(() => _state = _GameFlowState.menu);
  }

  void _onPlay(SkinData skin) {
    setState(() {
      _selectedSkin = skin;
      _state = _GameFlowState.game;
    });
  }

  void _onMainMenu() {
    setState(() => _state = _GameFlowState.menu);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GameFlowState.loading:
        return LoadingScreen(onLoadingComplete: _onLoadingComplete);
      case _GameFlowState.menu:
        return MainMenuScreen(onPlay: _onPlay);
      case _GameFlowState.game:
        return GameScreen(
          key: UniqueKey(),
          skin: _selectedSkin,
          onMainMenu: _onMainMenu,
        );
    }
  }
}
