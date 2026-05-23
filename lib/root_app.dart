import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/tracker.dart';
import 'services/push_service.dart';
import 'services/remote_config.dart';
import 'services/app_storage.dart';
import 'services/net_checker.dart';

class BounceBallApp extends StatelessWidget {
  final AppStorage store;
  final NetChecker net;
  final Tracker attribution;
  final RemoteConfig config;
  final PushService push;

  const BounceBallApp({
    super.key,
    required this.store,
    required this.net,
    required this.attribution,
    required this.config,
    required this.push,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Ball',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: SplashScreen(
        store: store,
        net: net,
        attribution: attribution,
        config: config,
        push: push,
      ),
    );
  }
}
