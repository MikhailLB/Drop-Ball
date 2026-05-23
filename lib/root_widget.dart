// Legacy entry point — not used by main.dart (which uses root_app.dart).
// Kept for reference only.
import 'package:flutter/material.dart';
import 'screens/flow_screen.dart';

class BallDropApp extends StatelessWidget {
  const BallDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Ball',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const FlowScreen(),
    );
  }
}
