import 'package:flutter/material.dart';
import 'screens/game_flow.dart';

class DropBallApp extends StatelessWidget {
  const DropBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DropBall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GameFlow(),
    );
  }
}
