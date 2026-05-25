import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'config/app_brand.dart';
import 'models/route_mode.dart';
import 'screens/web_container.dart' deferred as wc;
import 'screens/offline_screen.dart';
import 'screens/push_perm_screen.dart';
import 'services/attribute_client.dart';
import 'services/flow_cache.dart';
import 'services/gate_client.dart';
import 'services/net_sensor.dart';
import 'services/push_relay.dart';
import 'services/safe_http.dart';

class FlowBoot {
  final FlowCache    _cache;
  final NetSensor    _sensor;
  final AttributeClient _attr;
  final GateClient   _gate;
  final PushRelay    _push;
  final bool         _enabled;

  FlowBoot._({required FlowCache cache, required NetSensor sensor,
      required AttributeClient attr, required GateClient gate,
      required PushRelay push, required bool enabled})
      : _cache = cache, _sensor = sensor, _attr = attr, _gate = gate, _push = push, _enabled = enabled;

  static Future<FlowBoot> prepare() async {
    if (kDebugMode) debugPrint('[DB.FB] gateEnabled=${AppBrand.gateEnabled}');
    try {
      await Firebase.initializeApp();
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );
    } catch (_) {}
    await safeHttp.warmup();
    final cache = FlowCache();
    await cache.init();
    final sensor = NetSensor();
    final attr   = AttributeClient();
    final gate   = GateClient(cache);
    final push   = PushRelay(cache);
    return FlowBoot._(cache: cache, sensor: sensor, attr: attr, gate: gate, push: push, enabled: AppBrand.gateEnabled);
  }

  Widget buildHome({required WidgetBuilder fallback}) {
    if (!_enabled) return Builder(builder: fallback);
    return _FlowPipeline(cache: _cache, sensor: _sensor, attr: _attr, gate: _gate, push: _push, fallback: fallback);
  }
}

// ─── Internal pipeline ────────────────────────────────────────────────────────

enum _BarStep { empty, half, almost, full }

class _FlowPipeline extends StatefulWidget {
  final FlowCache cache; final NetSensor sensor; final AttributeClient attr;
  final GateClient gate; final PushRelay push; final WidgetBuilder fallback;
  const _FlowPipeline({required this.cache, required this.sensor, required this.attr, required this.gate, required this.push, required this.fallback});
  @override State<_FlowPipeline> createState() => _FlowPipelineState();
}

class _FlowPipelineState extends State<_FlowPipeline> {
  VideoPlayerController? _vid;
  Orientation? _activeOri;
  bool _vidSwitching = false, _vidReady = false;
  int _vidToken = 0;
  _BarStep _bar = _BarStep.empty;
  bool _navigated = false;

  static const _bars = {
    _BarStep.empty:  'assets/Loading/loading_bar_empty.webp',
    _BarStep.half:   'assets/Loading/loading_bar_half.webp',
    _BarStep.almost: 'assets/Loading/loading_bar_almost.webp',
    _BarStep.full:   'assets/Loading/loading_bar_full.webp',
  };

  @override void initState() { super.initState(); _boot(); }
  @override void dispose() { widget.push.onTokenRefresh = null; _vid?.dispose(); super.dispose(); }
  @override void didChangeDependencies() { super.didChangeDependencies(); final o = MediaQuery.of(context).orientation; if (o != _activeOri) _loadVideo(o); }

  void _setBar(_BarStep b) { if (mounted) setState(() => _bar = b); }

  Future<void> _loadVideo(Orientation ori) async {
    if (_activeOri == ori || _vidSwitching) return;
    _vidSwitching = true; _activeOri = ori;
    final tok = ++_vidToken;
    final path = ori == Orientation.landscape ? 'assets/Loading/16x9_Loading_Screen.mp4' : 'assets/Loading/9x16_Loading_Screen.mp4';
    final old = _vid;
    final ctrl = VideoPlayerController.asset(path);
    _vid = ctrl;
    try {
      await old?.dispose();
      await ctrl.initialize(); ctrl.setLooping(true); ctrl.setVolume(0); ctrl.play();
      if (!mounted || _vid != ctrl || tok != _vidToken) { await ctrl.dispose(); return; }
      if (mounted) setState(() => _vidReady = true);
    } catch (_) { await ctrl.dispose(); } finally { _vidSwitching = false; }
  }

  Future<void> _boot() async {
    widget.push.onTokenRefresh = (t) async {
      final body = await widget.attr.buildPayload(locale: Platform.localeName.replaceAll('-', '_'), pushToken: t);
      widget.gate.dispatch(body);
    };
    await widget.push.bootstrap().catchError((_) {});
    _setBar(_BarStep.empty);
    switch (widget.cache.readRoute()) {
      case RouteMode.web:    _setBar(_BarStep.half); await _webFlow();
      case RouteMode.arcade: _setBar(_BarStep.half); await _restoreFlow();
      case RouteMode.pristine: await _freshFlow();
    }
  }

  Future<void> _freshFlow() async {
    _setBar(_BarStep.empty);
    if (!await widget.sensor.hasInternet()) { if (mounted) _goOffline(first: true); return; }
    _setBar(_BarStep.half);
    await widget.attr.warmup();
    await Future.wait([widget.attr.waitForAttr(), widget.attr.waitForDl()]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.attr.buildPayload(locale: locale, pushToken: widget.push.token);
    final reply = await widget.gate.dispatch(body);
    if (reply.ok && reply.url != null) {
      await widget.cache.writeRoute(RouteMode.web);
      _setBar(_BarStep.full); await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goContent(reply.url!);
    } else {
      await widget.cache.writeRoute(RouteMode.arcade);
      _setBar(_BarStep.full); await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goFallback();
    }
  }

  Future<void> _webFlow() async {
    if (!await widget.sensor.hasInternet()) { _setBar(_BarStep.full); await Future.delayed(const Duration(milliseconds: 400)); if (mounted) _goOffline(first: false); return; }
    final push = await widget.cache.consumePushUrl();
    if (push != null) { _setBar(_BarStep.full); await Future.delayed(const Duration(milliseconds: 400)); if (mounted) _goContent(push); return; }
    final saved = await widget.cache.getSavedUrl();
    await widget.attr.warmup();
    await Future.wait([widget.attr.waitForAttr().timeout(const Duration(seconds: 6), onTimeout: () => {}), widget.attr.waitForDl()]);
    final body = await widget.attr.buildPayload(locale: Platform.localeName.replaceAll('-', '_'), pushToken: widget.push.token);
    final reply = await widget.gate.dispatch(body);
    _setBar(_BarStep.full); await Future.delayed(const Duration(milliseconds: 400)); if (!mounted) return;
    if (reply.ok && reply.url != null) { _goContent(reply.url!); }
    else if (saved != null) { _goContent(saved); }
    else { _goOffline(first: false); }
  }

  Future<void> _restoreFlow() async {
    if (!await widget.sensor.hasInternet()) { _setBar(_BarStep.full); await Future.delayed(const Duration(milliseconds: 600)); if (mounted) _goFallback(); return; }
    await widget.attr.warmup();
    await Future.wait([widget.attr.waitForAttr().timeout(const Duration(seconds: 8), onTimeout: () => {}), widget.attr.waitForDl()]);
    final body = await widget.attr.buildPayload(locale: Platform.localeName.replaceAll('-', '_'), pushToken: widget.push.token);
    final reply = await widget.gate.dispatch(body);
    if (reply.ok && reply.url != null) { await widget.cache.writeRoute(RouteMode.web); _setBar(_BarStep.full); await Future.delayed(const Duration(milliseconds: 400)); if (mounted) _goContent(reply.url!); }
    else { _setBar(_BarStep.full); await Future.delayed(const Duration(milliseconds: 600)); if (mounted) _goFallback(); }
  }

  Future<void> _goContent(String url) async {
    if (_navigated || !mounted) return;
    _navigated = true;
    await wc.loadLibrary();
    await wc.prepareEngine();
    if (!mounted) return;
    if (widget.cache.shouldShowNotifPrompt()) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) =>
          PushPermScreen(cache: widget.cache, push: widget.push, sensor: widget.sensor, targetUrl: url)));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) =>
          wc.WebContainer(url: url, cache: widget.cache, push: widget.push, sensor: widget.sensor)));
    }
  }

  void _goOffline({required bool first}) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) =>
        OfflineScreen(retryBuilder: (_) => _FlowPipeline(cache: widget.cache, sensor: widget.sensor, attr: widget.attr, gate: widget.gate, push: widget.push, fallback: widget.fallback))));
  }

  void _goFallback() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: widget.fallback));
  }

  @override
  Widget build(BuildContext context) {
    final vid = _vid;
    final hasVid = vid != null && vid.value.isInitialized;
    final barAsset = _bars[_bar]!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        if (hasVid) FittedBox(fit: BoxFit.cover, child: SizedBox(width: vid.value.size.width, height: vid.value.size.height, child: VideoPlayer(vid)))
        else const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF111522), Color(0xFF05070D)]))),
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0.65)]))),
        SafeArea(minimum: const EdgeInsets.all(16), child: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).orientation == Orientation.landscape ? 48 : 24),
          child: Column(children: [
            const Spacer(),
            if (_vidReady) AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (ch, a) => FadeTransition(opacity: a, child: ch),
              child: Image.asset(barAsset, key: ValueKey(barAsset), width: 280, fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const SizedBox(height: 24)),
            ) else const SizedBox(height: 24),
            const SizedBox(height: 26),
          ]),
        )),
      ]),
    );
  }
}
