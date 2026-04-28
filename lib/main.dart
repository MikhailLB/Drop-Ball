import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/attribution_gateway.dart';
import 'services/cloud_push_client.dart';
import 'services/config_api.dart';
import 'services/local_store.dart';
import 'services/network_monitor.dart';

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

  // Keep main() short so the first Flutter frame (branded splash)
  // appears immediately. Heavy bootstrap (Firebase, App Check,
  // SharedPreferences, device-info UA probe) is deferred to
  // BootScreen so the user never sees a long blank screen.
  await _configureChrome();

  final store = LocalStore();
  final net = NetworkMonitor();
  final attribution = AttributionGateway();
  final config = ConfigApi(store);
  final push = CloudPushClient(store);

  runApp(GravityRushApp(
    store: store,
    net: net,
    attribution: attribution,
    config: config,
    push: push,
  ));
}
