import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/runtime_mode.dart';
import '../services/app_bootstrap.dart';
import '../services/attribution_gateway.dart';
import '../services/cloud_push_client.dart';
import '../services/config_api.dart';
import '../services/local_store.dart';
import '../services/native_push_bridge.dart';
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

class _BootScreenState extends State<BootScreen>
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
    // Heavy first-launch bootstrap (Firebase, App Check, UA probe,
    // SharedPreferences) used to live in main(). Running it here lets
    // the branded splash render first so iOS reviewers never see a
    // long blank screen between LaunchScreen and the first frame.
    await appBootstrap(widget.store);

    widget.push.onTokenRotate = _onTokenRotate;

    // STEP 1 — HIGHEST PRIORITY: native cold-start URL.
    //
    // SceneDelegate captures the URL from a killed-app push tap BEFORE any
    // Dart code runs (Firebase swizzle misses these because scene-based apps
    // don't put the notification into launchOptions[remoteNotification] —
    // see firebase/flutterfire#8896). We read it the very first thing so it
    // overrides every other path — runtime mode cache, AppsFlyer offers,
    // gateway dispatch — and the user is routed to the push URL no matter
    // what state the gray flow is in.
    final swNative = Stopwatch()..start();
    final nativeColdStartUrl = await NativePushBridge.consumeColdStartUrl();
    debugPrint(
        '[BOOT] native cold-start probe done in ${swNative.elapsedMilliseconds}ms,'
        ' url=${nativeColdStartUrl ?? 'null'}');

    // Kick off push.bootstrap() concurrently — its main cost on iOS (APNs
    // token poll, FCM token retrieval, getInitialMessage round-trip) overlaps
    // fully with AppsFlyer warmup + conversion wait in the per-mode flows.
    // Sequential awaiting used to add 4–7 seconds to first paint.
    final pushFuture = widget.push.bootstrap().catchError((err) {
      debugPrint('[BOOT] push.bootstrap failed: $err');
    });
    _setStage(_ProgressStage.start);

    // Express lane: if SceneDelegate captured a URL, route there immediately
    // and dispatch the install signal in the background so attribution is
    // still recorded but the user never waits behind it.
    if (nativeColdStartUrl != null && nativeColdStartUrl.isNotEmpty) {
      debugPrint(
          '[BOOT] EXPRESS-LANE → WebHost @ $nativeColdStartUrl');
      await widget.store.writeRuntimeMode(RuntimeMode.browser);
      unawaited(_dispatchExpressLane(pushFuture));
      _setStage(_ProgressStage.filled);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goWebContent(nativeColdStartUrl);
      return;
    }

    final mode = widget.store.readRuntimeMode();
    switch (mode) {
      case RuntimeMode.browser:
        await _runBrowserMode(pushFuture);
        break;
      case RuntimeMode.arcade:
        await _runArcadeMode(pushFuture);
        break;
      case RuntimeMode.undetermined:
        await _runFirstLaunch(pushFuture);
        break;
    }
  }

  /// Best-effort backend ping after we've already routed the user via a
  /// native cold-start URL. Warms up AppsFlyer, composes a payload and
  /// dispatches — failures are logged and swallowed.
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

  /// Even when the previous launch decided the app should run in arcade
  /// mode, we still want to give attribution one more chance. Reasons:
  ///   * the user might have installed organically and clicked a OneLink
  ///     only later — AppsFlyer fires a re-engagement event we should
  ///     react to.
  ///   * the very first dispatch can race against AppsFlyer's conversion
  ///     callback, returning accepted=false before the SDK even reported
  ///     attribution. Without this re-check the user is locked to arcade
  ///     forever.
  /// We only re-dispatch when there is online connectivity AND attribution
  /// data actually carries a non-organic / deep-link signal — otherwise
  /// arcade stays as configured.
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

    // Run AppsFlyer warmup in parallel with push.bootstrap.
    final attributionFuture = (() async {
      await widget.attribution.warmup();
      await Future.wait([
        widget.attribution
            .awaitConversion(timeout: const Duration(seconds: 6)),
        widget.attribution
            .awaitDeepLink(timeout: const Duration(seconds: 4)),
      ]);
    })();

    // Honor cold-start push tap before falling back to arcade — if the user
    // explicitly tapped a notification with a URL, never drop it.
    await pushFuture;
    final pushTarget = await widget.store.takePushTarget();
    if (pushTarget != null) {
      await widget.store.writeRuntimeMode(RuntimeMode.browser);
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
      // OneLink arrived after install — promote the user to browser mode.
      await widget.store.writeRuntimeMode(RuntimeMode.browser);
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

    // Run AppsFlyer warmup in parallel with push.bootstrap.
    final attributionFuture = (() async {
      await widget.attribution.warmup();
      await Future.wait([
        widget.attribution.awaitConversion(),
        widget.attribution.awaitDeepLink(),
      ]);
    })();

    // Honor cold-start push tap before paying the AppsFlyer / config-API
    // round-trip. The user explicitly opened the app from a notification —
    // we should never make them wait 10+ seconds before the link opens.
    await pushFuture;
    final pushTarget = await widget.store.takePushTarget();
    if (pushTarget != null) {
      await widget.store.writeRuntimeMode(RuntimeMode.browser);
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
      await widget.store.writeRuntimeMode(RuntimeMode.browser);
      _goWebContent(reply.target!);
      return;
    }

    // Only persist arcade if AppsFlyer definitively reported the install
    // as Organic. If conversion data never arrived (timeout, ATT denied,
    // SDK error) we leave runtime_mode = undetermined so the next launch
    // gets another chance — otherwise a OneLink that arrives after the
    // first cold start would be ignored forever.
    if (widget.attribution.hasOrganicSignal) {
      await widget.store.writeRuntimeMode(RuntimeMode.arcade);
    }
    _goArcade();
  }

  /// Best-effort install signal sent in the background after the user has
  /// already been routed via a cold-start push URL. Failures are logged
  /// and swallowed — they must never block the UI.
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

    // Run AppsFlyer warmup in parallel with push.bootstrap.
    final attributionFuture = (() async {
      await widget.attribution.warmup();
      await Future.wait([
        widget.attribution
            .awaitConversion(timeout: const Duration(seconds: 10)),
        widget.attribution.awaitDeepLink(),
      ]);
    })();

    // Pulse must finish before reading takePushTarget, otherwise we race
    // getInitialMessage() and lose the cold-start URL.
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
                painter: _NeonBarPainter(
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

class _NeonBarPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final double barWidth;
  final double barHeight;
  final double radius;

  _NeonBarPainter({
    required this.progress,
    required this.glowIntensity,
    required this.barWidth,
    required this.barHeight,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dx = (size.width - barWidth) / 2;
    final dy = (size.height - barHeight) / 2;
    final trackRect =
        RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, barWidth, barHeight), Radius.circular(radius));
    final fillWidth = barWidth * progress.clamp(0.0, 1.0);

    // Track background
    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = const Color(0xFF1A1A3E)
        ..style = PaintingStyle.fill,
    );

    // Track border
    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    if (fillWidth > 0) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, dy, fillWidth, barHeight),
        Radius.circular(radius),
      );

      // Glow behind fill
      canvas.drawRRect(
        fillRect.inflate(4 * glowIntensity),
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25 * glowIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Gradient fill
      final gradient = LinearGradient(
        colors: const [Color(0xFF00BCD4), Color(0xFF00E5FF), Color(0xFF76FF03)],
        stops: const [0.0, 0.6, 1.0],
      );
      canvas.drawRRect(
        fillRect,
        Paint()
          ..shader = gradient.createShader(
              Rect.fromLTWH(dx, dy, barWidth, barHeight))
          ..style = PaintingStyle.fill,
      );

      // Bright leading edge
      if (fillWidth > 3) {
        final edgeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(dx + fillWidth - 4, dy + 1, 4, barHeight - 2),
          const Radius.circular(2),
        );
        canvas.drawRRect(
          edgeRect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7 * glowIntensity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }

      // Shine highlight on top half
      final shineRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx + 2, dy + 1, fillWidth - 4, barHeight * 0.4),
        Radius.circular(radius),
      );
      canvas.drawRRect(
        shineRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(_NeonBarPainter old) =>
      progress != old.progress || glowIntensity != old.glowIntensity;
}
