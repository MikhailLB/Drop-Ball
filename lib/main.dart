import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'boot/boot_core.dart';
import 'root_app.dart';
import 'screens/game_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final flow = await FlowBoot.prepare();

  runApp(DropBallApp(
    home: flow.buildHome(fallback: (_) => const GameFlow()),
  ));
}
