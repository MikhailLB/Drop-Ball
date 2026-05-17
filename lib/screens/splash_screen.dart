import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_mode.dart';
import '../services/startup.dart';
import '../services/tracker.dart';
import '../services/push_service.dart';
import '../services/remote_config.dart';
import '../services/app_storage.dart';
import '../services/push_bridge.dart';
import '../services/net_checker.dart';
import '../utils/media_paths.dart';
import 'flow_screen.dart';
import 'offline_screen.dart';
import 'notif_screen.dart';
import 'browser_host.dart' deferred as host;
import 'painters/bar_painter.dart';

enum _ProgressStage { start, midway, filled }

class SplashScreen extends StatefulWidget {
  final AppStorage store;
  final NetChecker net;
  final Tracker attribution;
  final RemoteConfig config;
  final PushService push;

  const SplashScreen({
    super.key,
    required this.store,
    required this.net,
    required this.attribution,
    required this.config,
    required this.push,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  _ProgressStage _stage = _ProgressStage.start;
  bool _leaving = false;

  late final AnimationController _barCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();

    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _kickoff();
  }

  Future<void> _kickoff() async {
    await runStartup(widget.store);

    widget.push.onTokenRotate = _onTokenRotate;

    final swNative = Stopwatch()..start();
    final nativeColdStartUrl = await PushBridge.consumeColdStartUrl();
    debugPrint(
        '[BOOT] native cold-start probe done in ${swNative.elapsedMilliseconds}ms,'
        ' url=${nativeColdStartUrl ?? 'null'}');

    final pushFuture = widget.push.bootstrap().catchError((err) {
      debugPrint('[BOOT] push.bootstrap failed: $err');
    });
    _setStage(_ProgressStage.start);

    if (nativeColdStartUrl != null && nativeColdStartUrl.isNotEmpty) {
      debugPrint('[BOOT] EXPRESS-LANE → BrowserHost @ $nativeColdStartUrl');
      await widget.store.writeRuntimeMode(AppMode.browser);
      unawaited(_dispatchExpressLane(pushFuture));
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goWebContent(nativeColdStartUrl);
      return;
    }

    final mode = widget.store.readRuntimeMode();
    switch (mode) {
      case AppMode.browser:
        await _runBrowserMode(pushFuture);
        break;
      case AppMode.arcade:
        await _runArcadeMode(pushFuture);
        break;
      case AppMode.undetermined:
        await _runFirstLaunch(pushFuture);
        break;
    }
  }

  Future<void> _dispatchExpressLane(Future<void> pushFuture) async {
    try {
      await widget.attribution.warmup();
      await Future.wait([
        widget.attribution
            .awaitConversion(timeout: const Duration(seconds: 10)),
        widget.attribution.awaitDeepLink(),
        pushFuture,
      ]);
      final locale = Platform.localeName.replaceAll('-', '_');
      final body = await widget.attribution.assembleRequest(
        locale: locale,
        pushToken: widget.push.token,
      );
      final reply = await widget.config.dispatch(body);
      debugPrint(
          '[BOOT] express-lane dispatch accepted=${reply.accepted}'
          ' target=${reply.target ?? 'null'}');
    } catch (err) {
      debugPrint('[BOOT] express-lane dispatch failed: $err');
    }
  }

  Future<void> _runArcadeMode(Future<void> pushFuture) async {
    _setStage(_ProgressStage.midway);

    final online = await widget.net.isOnline();
    if (!online) {
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goArcade();
      return;
    }

    final attributionFuture = (() async {
      await widget.attribution.warmup();
      await Future.wait([
        widget.attribution
            .awaitConversion(timeout: const Duration(seconds: 6)),
        widget.attribution
            .awaitDeepLink(timeout: const Duration(seconds: 4)),
      ]);
    })();

    await pushFuture;
    final pushTarget = await widget.store.takePushTarget();
    if (pushTarget != null) {
      await widget.store.writeRuntimeMode(AppMode.browser);
      unawaited(_dispatchInBackground(attributionFuture));
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goWebContent(pushTarget);
      return;
    }

    await attributionFuture;

    final hasFreshAttribution = widget.attribution.hasNonOrganicSignal;
    if (!hasFreshAttribution) {
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goArcade();
      return;
    }

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
      await widget.store.writeRuntimeMode(AppMode.browser);
      _goWebContent(reply.target!);
    } else {
      _goArcade();
    }
  }

  Future<void> _runFirstLaunch(Future<void> pushFuture) async {
    _setStage(_ProgressStage.start);

    final online = await widget.net.isOnline();
    if (!online) {
      if (!mounted) return;
      _goOffline(firstLaunch: true);
      return;
    }

    _setStage(_ProgressStage.midway);

    final attributionFuture = (() async {
      await widget.attribution.warmup();
      await Future.wait([
        widget.attribution.awaitConversion(),
        widget.attribution.awaitDeepLink(),
      ]);
    })();

    await pushFuture;
    final pushTarget = await widget.store.takePushTarget();
    if (pushTarget != null) {
      await widget.store.writeRuntimeMode(AppMode.browser);
      unawaited(_dispatchInBackground(attributionFuture));
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goWebContent(pushTarget);
      return;
    }

    await attributionFuture;

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
      await widget.store.writeRuntimeMode(AppMode.browser);
      _goWebContent(reply.target!);
      return;
    }

    if (widget.attribution.hasOrganicSignal) {
      await widget.store.writeRuntimeMode(AppMode.arcade);
    }
    _goArcade();
  }

  Future<void> _dispatchInBackground(Future<void> attributionFuture) async {
    try {
      await attributionFuture;
      final locale = Platform.localeName.replaceAll('-', '_');
      final body = await widget.attribution.assembleRequest(
        locale: locale,
        pushToken: widget.push.token,
      );
      await widget.config.dispatch(body);
    } catch (err) {
      debugPrint('[BOOT] background dispatch failed: $err');
    }
  }

  Future<void> _runBrowserMode(Future<void> pushFuture) async {
    _setStage(_ProgressStage.midway);

    final online = await widget.net.isOnline();
    if (!online) {
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goOffline(firstLaunch: false);
      return;
    }

    final attributionFuture = (() async {
      await widget.attribution.warmup();
      await Future.wait([
        widget.attribution
            .awaitConversion(timeout: const Duration(seconds: 10)),
        widget.attribution.awaitDeepLink(),
      ]);
    })();

    await pushFuture;
    final pushTarget = await widget.store.takePushTarget();
    if (pushTarget != null) {
      unawaited(_dispatchInBackground(attributionFuture));
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goWebContent(pushTarget);
      return;
    }

    await attributionFuture;

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
    final cached = await widget.store.readCachedTarget();
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
    if (!mounted) return;
    setState(() => _stage = s);
    final target = switch (s) {
      _ProgressStage.start => 0.15,
      _ProgressStage.midway => 0.55,
      _ProgressStage.filled => 1.0,
    };
    _barCtrl.animateTo(target,
        duration: const Duration(milliseconds: 900), curve: Curves.easeInOut);
  }

  Future<void> _goWebContent(String url) async {
    if (_leaving) return;
    _leaving = true;

    await host.loadLibrary();
    await primeHost();
    if (!mounted) return;

    final canPrompt =
        widget.store.needsPushPrompt() &&
        await widget.push.canShowSystemPrompt();

    if (canPrompt) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NotifScreen(
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
          builder: (_) => host.BrowserHost(
            target: url,
            store: widget.store,
            push: widget.push,
            net: widget.net,
          ),
        ),
      );
    }
  }

  Future<void> primeHost() async {}

  void _goOffline({required bool firstLaunch}) {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OfflineScreen(
          net: widget.net,
          retryBuilder: (_) => SplashScreen(
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
      MaterialPageRoute(builder: (_) => const FlowScreen()),
    );
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _glowCtrl.dispose();
    _dotsCtrl.dispose();
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
        alignment: landscape
            ? const Alignment(0, -0.55)
            : const Alignment(0, -0.2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              MediaPaths.logo,
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  SizedBox(width: logoSize, height: logoSize),
            ),
            SizedBox(height: landscape ? 4 : 18),
            Text(
              'BOUNCEBALL 2',
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
            _buildAnimatedLoadingText(loadingSize),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLoadingText(double fontSize) {
    return AnimatedBuilder(
      animation: _dotsCtrl,
      builder: (context, _) {
        final phase = (_dotsCtrl.value * 4).floor() % 4;
        final dots = '.' * phase;
        final hidden = '.' * (3 - phase);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LOADING',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            SizedBox(
              width: fontSize * 2,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: dots,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  TextSpan(
                    text: hidden,
                    style: TextStyle(
                      color: Colors.transparent,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar({
    required bool landscape,
    required MediaQueryData media,
  }) {
    final bottom = media.padding.bottom + (landscape ? 14.0 : 32.0);
    final barWidth = landscape
        ? (media.size.width * 0.25).clamp(160.0, 260.0)
        : (media.size.width * 0.6).clamp(200.0, 300.0);
    const barHeight = 14.0;
    const radius = 7.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_barCtrl, _glowCtrl]),
          builder: (context, _) {
            final progress = _barCtrl.value;
            final glowPulse = 0.4 + 0.6 * _glowCtrl.value;

            return SizedBox(
              width: barWidth + 8,
              height: barHeight + 8,
              child: CustomPaint(
                painter: BarPainter(
                  progress: progress,
                  glowIntensity: glowPulse,
                  barWidth: barWidth,
                  barHeight: barHeight,
                  radius: radius,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
