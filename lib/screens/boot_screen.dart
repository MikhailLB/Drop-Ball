import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/runtime_mode.dart';
import '../services/app_bootstrap.dart';
import '../services/attribution_gateway.dart';
import '../services/cloud_push_client.dart';
import '../services/config_api.dart';
import '../services/local_store.dart';
import '../services/network_monitor.dart';
import '../utils/asset_paths.dart';
import 'game_flow_screen.dart';
import 'connection_lost_screen.dart';
import 'push_optin_screen.dart';
import 'web_host.dart' deferred as host;

enum _ProgressStage { start, midway, filled }

class BootScreen extends StatefulWidget {
  final LocalStore store;
  final NetworkMonitor net;
  final AttributionGateway attribution;
  final ConfigApi config;
  final CloudPushClient push;

  const BootScreen({
    super.key,
    required this.store,
    required this.net,
    required this.attribution,
    required this.config,
    required this.push,
  });

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  _ProgressStage _stage = _ProgressStage.start;
  bool _leaving = false;
  bool _assetsPrecached = false;

  @override
  void initState() {
    super.initState();
    // Other screens (game flow) lock portrait. When BootScreen is
    // entered after them (e.g. retry from offline), make sure the
    // splash itself can be shown in any orientation.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _kickoff();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsPrecached) return;
    _assetsPrecached = true;
    // Pre-warm progress-bar frames so AnimatedOpacity doesn't flash to a
    // blank cell on the first stage transition (assets are decoded lazily
    // otherwise and the user sees a one-frame gap mid-animation).
    precacheImage(const AssetImage(AssetPaths.loadingBarEmpty), context);
    precacheImage(const AssetImage(AssetPaths.loadingBarAlmostFull), context);
    precacheImage(const AssetImage(AssetPaths.loadingBarFull), context);
  }

  Future<void> _kickoff() async {
    // Heavy first-launch bootstrap (Firebase, App Check, UA probe,
    // SharedPreferences) used to live in main(). Running it here lets
    // the branded splash render first so iOS reviewers never see a
    // long blank screen between LaunchScreen and the first frame.
    await appBootstrap(widget.store);

    widget.push.onTokenRotate = _onTokenRotate;
    await widget.push.bootstrap().catchError((_) {});
    _setStage(_ProgressStage.start);

    final mode = widget.store.readRuntimeMode();
    switch (mode) {
      case RuntimeMode.browser:
        await _runBrowserMode();
        break;
      case RuntimeMode.arcade:
        _setStage(_ProgressStage.midway);
        _setStage(_ProgressStage.filled);
        await Future.delayed(const Duration(milliseconds: 600));
        _goArcade();
        break;
      case RuntimeMode.undetermined:
        await _runFirstLaunch();
        break;
    }
  }

  Future<void> _runFirstLaunch() async {
    _setStage(_ProgressStage.start);

    final online = await widget.net.isOnline();
    if (!online) {
      if (!mounted) return;
      _goOffline(firstLaunch: true);
      return;
    }

    _setStage(_ProgressStage.midway);
    await widget.attribution.warmup();
    await Future.wait([
      widget.attribution.awaitConversion(),
      widget.attribution.awaitDeepLink(),
    ]);

    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.attribution.assembleRequest(
      locale: locale,
      pushToken: widget.push.token,
    );
    final reply = await widget.config.dispatch(body);

    if (reply.accepted && reply.target != null) {
      await widget.store.writeRuntimeMode(RuntimeMode.browser);
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goWebContent(reply.target!);
    } else {
      await widget.store.writeRuntimeMode(RuntimeMode.arcade);
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goArcade();
    }
  }

  Future<void> _runBrowserMode() async {
    _setStage(_ProgressStage.midway);

    final online = await widget.net.isOnline();
    if (!online) {
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goOffline(firstLaunch: false);
      return;
    }

    final pushTarget = await widget.store.takePushTarget();
    if (pushTarget != null) {
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goWebContent(pushTarget);
      return;
    }

    final cached = await widget.store.readCachedTarget();

    await widget.attribution.warmup();
    await Future.wait([
      widget.attribution.awaitConversion(timeout: const Duration(seconds: 10)),
      widget.attribution.awaitDeepLink(),
    ]);

    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.attribution.assembleRequest(
      locale: locale,
      pushToken: widget.push.token,
    );
    final reply = await widget.config.dispatch(body);
    _setStage(_ProgressStage.filled);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (reply.accepted && reply.target != null) {
      _goWebContent(reply.target!);
      return;
    }
    if (cached != null) {
      _goWebContent(cached);
    } else {
      _goOffline(firstLaunch: false);
    }
  }

  void _onTokenRotate(String newToken) {
    _sendPushTokenUpdate(newToken);
  }

  Future<void> _sendPushTokenUpdate(String newToken) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.attribution.assembleRequest(
      locale: locale,
      pushToken: newToken,
    );
    await widget.config.dispatch(body);
  }

  void _setStage(_ProgressStage s) {
    if (mounted) setState(() => _stage = s);
  }

  Future<void> _goWebContent(String url) async {
    if (_leaving) return;
    _leaving = true;

    await host.loadLibrary();
    await primeBrowser();
    if (!mounted) return;

    // Only show the opt-in screen if the OS will actually surface a
    // system prompt afterwards. If the user has already permanently
    // denied (or granted) notifications, the opt-in screen is a no-op
    // for ALLOW, so we skip straight to the WebHost.
    final canPrompt =
        widget.store.needsPushPrompt() &&
        await widget.push.canShowSystemPrompt();

    if (canPrompt) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PushOptInScreen(
            store: widget.store,
            push: widget.push,
            net: widget.net,
            target: url,
            onPushTokenReady: _sendPushTokenUpdate,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => host.WebHost(
            target: url,
            store: widget.store,
            push: widget.push,
            net: widget.net,
          ),
        ),
      );
    }
  }

  Future<void> primeBrowser() async {}

  void _goOffline({required bool firstLaunch}) {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConnectionLostScreen(
          net: widget.net,
          retryBuilder: (_) => BootScreen(
            store: widget.store,
            net: widget.net,
            attribution: widget.attribution,
            config: widget.config,
            push: widget.push,
          ),
        ),
      ),
    );
  }

  void _goArcade() {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameFlowScreen()),
    );
  }

  @override
  void dispose() {
    widget.push.onTokenRotate = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final landscape = orientation == Orientation.landscape;
          final media = MediaQuery.of(context);
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBrandedSplash(landscape, media),
              _buildProgressBar(landscape: landscape, media: media),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandedSplash(bool landscape, MediaQueryData media) {
    final shortest = media.size.shortestSide;
    final logoSize = landscape ? shortest * 0.22 : shortest * 0.42;
    final titleSize = landscape ? 18.0 : 30.0;
    final loadingSize = landscape ? 12.0 : 17.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [Color(0xFF17134A), Color(0xFF070714), Colors.black],
        ),
      ),
      child: Align(
        // In landscape lift the brand block well above the progress
        // bar so the LOADING caption never collides with it on short
        // screens (iPhone SE/mini measure only ~320 px tall in
        // landscape). Portrait keeps a softer offset.
        alignment: landscape
            ? const Alignment(0, -0.55)
            : const Alignment(0, -0.2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AssetPaths.logo,
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  SizedBox(width: logoSize, height: logoSize),
            ),
            SizedBox(height: landscape ? 4 : 18),
            Text(
              'GRAVITY RUSH',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: const [
                  Shadow(color: Colors.cyanAccent, blurRadius: 18),
                ],
              ),
            ),
            SizedBox(height: landscape ? 4 : 12),
            Text(
              'LOADING',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: loadingSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required bool landscape,
    required MediaQueryData media,
  }) {
    final bottom = media.padding.bottom + (landscape ? 14.0 : 32.0);
    final width = landscape
        ? (media.size.width * 0.22).clamp(140.0, 220.0)
        : (media.size.width * 0.6).clamp(180.0, 280.0);

    // Stack all three frames on top of each other and cross-fade by
    // opacity. AnimatedSwitcher used to recreate Image widgets between
    // stages, which produced a one-frame "blank" flash because each
    // asset was re-decoded. Now each frame keeps its element identity,
    // so the transition is buttery smooth.
    final stageIndex = _stage.index;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Center(
        child: SizedBox(
          width: width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _barFrame(AssetPaths.loadingBarEmpty, width, opacity: 1.0),
              _barFrame(
                AssetPaths.loadingBarAlmostFull,
                width,
                opacity: stageIndex >= 1 ? 1.0 : 0.0,
              ),
              _barFrame(
                AssetPaths.loadingBarFull,
                width,
                opacity: stageIndex >= 2 ? 1.0 : 0.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barFrame(String asset, double width, {required double opacity}) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      child: Image.asset(
        asset,
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            const SizedBox(height: 30),
      ),
    );
  }
}
