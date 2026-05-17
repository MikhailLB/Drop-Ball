import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ball_skin.dart';
import 'game_screen.dart';
import 'loading_screen.dart';
import 'main_menu_screen.dart';

enum _FlowState { loading, menu, game }

class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  _FlowState _state = _FlowState.loading;
  BallSkin _selectedSkin = BallSkin.allSkins[0];

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
    setState(() => _state = _FlowState.menu);
  }

  void _onPlay(BallSkin skin) {
    setState(() {
      _selectedSkin = skin;
      _state = _FlowState.game;
    });
  }

  void _onMainMenu() {
    setState(() => _state = _FlowState.menu);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _FlowState.loading:
        return LoadingScreen(onLoadingComplete: _onLoadingComplete);
      case _FlowState.menu:
        return MainMenuScreen(onPlay: _onPlay);
      case _FlowState.game:
        return GameScreen(
          key: UniqueKey(),
          skin: _selectedSkin,
          onMainMenu: _onMainMenu,
        );
    }
  }
}
