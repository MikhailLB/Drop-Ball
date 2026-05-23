import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../screens/game_flow.dart';
import '../infra/attribution_beacon.dart';
import '../infra/cold_tap_reader.dart';
import '../infra/data_vault.dart';
import '../infra/net_probe.dart';
import '../infra/notify_relay.dart';
import '../infra/route_dispatch.dart';
import '../models/app_route.dart';
import 'consent_screen.dart';
import 'offline_view.dart';
import 'web_shell.dart';

enum _BarPhase { empty, half, almost, full }

/// ★ Core gray gate screen. Shows the Drop Ball loading video while running
/// attribution + config pipeline, then routes to WebView or the game.
class GateScreen extends StatefulWidget {
  final DataVault vault;
  final NetProbe probe;
  final AttributionBeacon signal;
  final RouteDispatch dispatch;
  final NotifyRelay pulse;

  const GateScreen({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.pulse,
  });

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  VideoPlayerController? _vid;
  bool _vidReady = false;
  _BarPhase _bar = _BarPhase.empty;
  bool _navigated = false;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.of(context).orientation;
    if (o != _lastOrientation) { _lastOrientation = o; _switchVideo(o); }
  }

  Future<void> _switchVideo(Orientation o) async {
    final asset = o == Orientation.landscape
        ? 'assets/Loading/16x9_Loading_Screen.mp4'
        : 'assets/Loading/9x16_Loading_Screen.mp4';
    final old = _vid;
    final ctrl = VideoPlayerController.asset(asset);
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      ctrl.play();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _vid = ctrl; _vidReady = true; });
      old?.dispose();
    } catch (_) {
      ctrl.dispose();
    }
  }

  void _setBar(_BarPhase p) { if (mounted) setState(() => _bar = p); }

  Future<void> _boot() async {
    widget.pulse.onTokenRefresh = _onTokenRefresh;

    // ── HIGHEST PRIORITY: SceneDelegate cold-start URL ──────────────────
    // When the app is KILLED and the user taps a push notification, iOS
    // delivers the tap through SceneDelegate before Dart starts.
    // Firebase's getInitialMessage() does NOT receive this tap on
    // scene-based apps. SceneDelegate writes the URL to UserDefaults
    // under flutter.db_flow_tap_url. Read it before anything else.
    final coldUrl = await ColdTapReader.consumeTapUrl();
    if (coldUrl != null && coldUrl.isNotEmpty) {
      debugPrint('[DB.GS] native cold-start url → $coldUrl');
      await widget.vault.writeRoute(AppRoute.web);
      await widget.vault.consumeOneShotUrl();
      unawaited(_dispatchBackground());
      _goContent(coldUrl);
      return;
    }

    _setBar(_BarPhase.empty);
    final route = widget.vault.readRoute();

    switch (route) {
      case AppRoute.web:
        _setBar(_BarPhase.half);
        final pushFut = widget.pulse.bootstrap().catchError((_) {});
        await _handleWebRoute(pushFuture: pushFut);
      case AppRoute.game:
        _setBar(_BarPhase.half);
        unawaited(widget.pulse.bootstrap().catchError((_) {}));
        final recovered = await _tryRecoverWeb();
        if (recovered) return;
        _setBar(_BarPhase.full);
        await Future.delayed(const Duration(milliseconds: 600));
        _goGame();
      case AppRoute.fresh:
        await widget.pulse.bootstrap().catchError((_) {});
        await _handleFreshRoute();
    }
  }

  @override
  void dispose() {
    widget.pulse.onTokenRefresh = null;
    _vid?.dispose();
    super.dispose();
  }

  Future<void> _dispatchBackground() async {
    try {
      await Future.wait([
        widget.pulse.bootstrap().catchError((_) {}),
        widget.signal.warmup().catchError((_) {}),
      ]);
      await Future.wait([
        widget.signal.awaitConversion(timeout: const Duration(seconds: 6)),
        widget.signal.awaitDeepLink(),
      ]);
      final body = await widget.signal.buildPayload(
        locale: Platform.localeName.replaceAll('-', '_'),
        pushToken: widget.pulse.token,
      );
      await widget.dispatch.send(body);
    } catch (e) {
      debugPrint('[DB.GS] background dispatch error: $e');
    }
  }

  void _onTokenRefresh(String token) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(locale: locale, pushToken: token);
    widget.dispatch.send(body);
  }

  Future<void> _handleFreshRoute() async {
    _setBar(_BarPhase.empty);
    final online = await widget.probe.isOnline();
    if (!online) { if (mounted) _goOffline(fresh: true); return; }

    _setBar(_BarPhase.half);
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.pulse.token,
    );
    final reply = await widget.dispatch.send(body);

    _setBar(_BarPhase.almost);
    if (reply.granted && reply.destination != null) {
      await widget.vault.writeRoute(AppRoute.web);
      _setBar(_BarPhase.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goContent(reply.destination!);
    } else {
      await widget.vault.writeRoute(AppRoute.game);
      _setBar(_BarPhase.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goGame();
    }
  }

  Future<void> _handleWebRoute({Future<void>? pushFuture}) async {
    final netFut = widget.probe.isOnline();
    if (pushFuture != null) await Future.wait([netFut, pushFuture]);
    final online = await netFut;

    if (!online) {
      _setBar(_BarPhase.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goOffline(fresh: false);
      return;
    }

    final oneShotUrl = await widget.vault.consumeOneShotUrl();
    if (oneShotUrl != null) {
      _setBar(_BarPhase.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goContent(oneShotUrl);
      return;
    }

    final sigFut = widget.signal.warmup();
    final savedUrl = await widget.vault.readSavedUrl();
    await sigFut;
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 5)),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.pulse.token,
    );
    final reply = await widget.dispatch.send(body);

    _setBar(_BarPhase.full);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (reply.granted && reply.destination != null) {
      _goContent(reply.destination!);
      return;
    }
    if (savedUrl != null) {
      _goContent(savedUrl);
    } else {
      _goOffline(fresh: false);
    }
  }

  Future<bool> _tryRecoverWeb() async {
    final online = await widget.probe.isOnline();
    if (!online) return false;
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 8)),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.pulse.token,
    );
    final reply = await widget.dispatch.send(body);
    if (!(reply.granted && reply.destination != null)) return false;
    await widget.vault.writeRoute(AppRoute.web);
    _setBar(_BarPhase.full);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return true;
    _goContent(reply.destination!);
    return true;
  }

  void _goContent(String url) {
    if (_navigated) return;
    _navigated = true;
    if (widget.vault.needsPushPrompt()) {
      widget.pulse.shouldOfferConsent().then((canAsk) {
        if (!mounted) return;
        if (canAsk) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => ConsentScreen(
              vault: widget.vault,
              pulse: widget.pulse,
              probe: widget.probe,
              destination: url,
              onTokenReady: (token) async {
                final locale = Platform.localeName.replaceAll('-', '_');
                final body = await widget.signal.buildPayload(
                  locale: locale, pushToken: token,
                );
                widget.dispatch.send(body);
              },
            ),
          ));
        } else {
          _directShell(url);
        }
      });
    } else {
      _directShell(url);
    }
  }

  void _directShell(String url) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WebShell(
        destination: url,
        vault: widget.vault,
        pulse: widget.pulse,
        probe: widget.probe,
      ),
    ));
  }

  // ── WHITE PART INTEGRATION ─────────────────────────────────
  // Navigates to the Drop Ball game when gate decides organic user.
  // Does NOT show the game's loading screen — GateScreen is the loading
  // experience. Goes straight to GameFlow (shop → level select → game).
  void _goGame() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameFlow()),
    );
  }

  void _goOffline({required bool fresh}) {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineView(
        probe: widget.probe,
        retryBuilder: (_) => GateScreen(
          vault: widget.vault,
          probe: widget.probe,
          signal: widget.signal,
          dispatch: widget.dispatch,
          pulse: widget.pulse,
        ),
      ),
    ));
  }

  String _barAsset() => switch (_bar) {
    _BarPhase.empty  => 'assets/Loading/loading_bar_empty.webp',
    _BarPhase.half   => 'assets/Loading/loading_bar_half.webp',
    _BarPhase.almost => 'assets/Loading/loading_bar_almost.webp',
    _BarPhase.full   => 'assets/Loading/loading_bar_full.webp',
  };

  @override
  Widget build(BuildContext context) {
    final barAsset = _barAsset();
    final mq = MediaQuery.of(context);
    final landscape = mq.orientation == Orientation.landscape;
    final barW = landscape
        ? (mq.size.height * 0.35).clamp(0.0, 180.0)
        : (mq.size.width * 0.70).clamp(0.0, 340.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          AnimatedOpacity(
            opacity: _vidReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _vid != null && _vidReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _vid!.value.size.width,
                        height: _vid!.value.size.height,
                        child: VideoPlayer(_vid!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_vidReady)
            Positioned(
              left: 0, right: 0,
              bottom: 30,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    barAsset,
                    key: ValueKey(barAsset),
                    width: barW,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (ctx, e, st) =>
                        const SizedBox(height: 32),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
