import 'package:flutter/material.dart';
import 'screens/boot_screen.dart';
import 'services/attribution_gateway.dart';
import 'services/cloud_push_client.dart';
import 'services/config_api.dart';
import 'services/local_store.dart';
import 'services/network_monitor.dart';

class GravityRushApp extends StatelessWidget {
  final LocalStore store;
  final NetworkMonitor net;
  final AttributionGateway attribution;
  final ConfigApi config;
  final CloudPushClient push;

  const GravityRushApp({
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
      title: 'Gravity Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: BootScreen(
        store: store,
        net: net,
        attribution: attribution,
        config: config,
        push: push,
      ),
    );
  }
}
