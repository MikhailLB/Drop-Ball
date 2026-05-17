import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'root_app.dart';
import 'services/tracker.dart';
import 'services/push_service.dart';
import 'services/remote_config.dart';
import 'services/app_storage.dart';
import 'services/net_checker.dart';

Future<void> _configureChrome() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureChrome();

  final store = AppStorage();
  final net = NetChecker();
  final attribution = Tracker();
  final config = RemoteConfig(store);
  final push = PushService(store);

  runApp(BounceBallApp(
    store: store,
    net: net,
    attribution: attribution,
    config: config,
    push: push,
  ));
}
