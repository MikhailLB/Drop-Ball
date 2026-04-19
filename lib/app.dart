import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/skin_data.dart';
import 'screens/game_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/main_menu_screen.dart';

class GravityRushApp extends StatefulWidget {
  const GravityRushApp({super.key});

  @override
  State<GravityRushApp> createState() => _GravityRushAppState();
}

enum AppScreen { loading, menu, game }

class _GravityRushAppState extends State<GravityRushApp> {
  AppScreen _currentScreen = AppScreen.loading;
  SkinData _selectedSkin = SkinData.allSkins[0];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _onLoadingComplete() {
    setState(() => _currentScreen = AppScreen.menu);
  }

  void _onPlay(SkinData skin) {
    setState(() {
      _selectedSkin = skin;
      _currentScreen = AppScreen.game;
    });
  }

  void _onMainMenu() {
    setState(() => _currentScreen = AppScreen.menu);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gravity Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case AppScreen.loading:
        return LoadingScreen(onLoadingComplete: _onLoadingComplete);
      case AppScreen.menu:
        return MainMenuScreen(onPlay: _onPlay);
      case AppScreen.game:
        return GameScreen(
          key: UniqueKey(),
          skin: _selectedSkin,
          onMainMenu: _onMainMenu,
        );
    }
  }
}
