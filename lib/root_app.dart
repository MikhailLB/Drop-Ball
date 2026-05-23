import 'package:flutter/material.dart';

import 'flow/infra/attribution_beacon.dart';
import 'flow/infra/data_vault.dart';
import 'flow/infra/net_probe.dart';
import 'flow/infra/notify_relay.dart';
import 'flow/infra/route_dispatch.dart';
import 'flow/screens/gate_screen.dart';
import 'screens/game_flow.dart';

// ════════════════════════════════════════════════════════════
// NeonFlowApp — root widget
// ════════════════════════════════════════════════════════════
//
// gateEnabled=true  → shows GateScreen (gray flow: attribution →
//                       WebView or game)
// gateEnabled=false → shows GameFlow directly (pure white build,
//                       or credentials not yet provisioned)
//
// All white-part routes MUST be registered in routes: below.
// If GameFlow uses named routes, add them here or navigation crashes.
// ════════════════════════════════════════════════════════════
class NeonFlowApp extends StatelessWidget {
  final DataVault vault;
  final NetProbe probe;
  final AttributionBeacon signal;
  final RouteDispatch dispatch;
  final NotifyRelay pulse;
  final bool gateEnabled;

  const NeonFlowApp({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.pulse,
    required this.gateEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final Widget home = gateEnabled
        ? GateScreen(
            vault: vault,
            probe: probe,
            signal: signal,
            dispatch: dispatch,
            pulse: pulse,
          )
        : const GameFlow();

    return MaterialApp(
      title: 'DropBall: Neon Edition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: home,
      routes: {
        '/game': (_) => const GameFlow(),
      },
    );
  }
}
