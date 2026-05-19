import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/ball_skin.dart';
import 'screens/arena_screen.dart';
import 'screens/preload_screen.dart';
import 'screens/lobby_screen.dart';

class BallDropApp extends StatefulWidget {
  const BallDropApp({super.key});

  @override
  State<BallDropApp> createState() => _BallDropAppState();
}

enum _ViewRoute { preload, lobby, arena }

class _BallDropAppState extends State<BallDropApp> {
  _ViewRoute _route = _ViewRoute.preload;
  BallSkin _activeSkin = BallSkin.all[0];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _onReady() => setState(() => _route = _ViewRoute.lobby);

  void _onPlay(BallSkin skin) {
    setState(() {
      _activeSkin = skin;
      _route = _ViewRoute.arena;
    });
  }

  void _onLobby() => setState(() => _route = _ViewRoute.lobby);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bounce Ball 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: _buildRoute(),
    );
  }

  Widget _buildRoute() {
    switch (_route) {
      case _ViewRoute.preload:
        return PreloadScreen(onReady: _onReady);
      case _ViewRoute.lobby:
        return LobbyScreen(onPlay: _onPlay);
      case _ViewRoute.arena:
        return ArenaScreen(
          key: UniqueKey(),
          skin: _activeSkin,
          onMainMenu: _onLobby,
        );
    }
  }
}
