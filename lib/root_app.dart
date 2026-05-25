import 'package:flutter/material.dart';

class DropBallApp extends StatelessWidget {
  final Widget home;
  const DropBallApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DropBall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: home,
    );
  }
}
