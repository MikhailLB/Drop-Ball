import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../utils/asset_paths.dart';

class LaunchScreen extends StatefulWidget {
  final VoidCallback onReady;
  const LaunchScreen({super.key, required this.onReady});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  int _bar = 0;
  bool _started = false;
  VideoPlayerController? _vid;
  bool _vidReady = false;
  Orientation? _lastOri;

  static const _bars = [
    AssetPaths.barEmpty,
    AssetPaths.barHalf,
    AssetPaths.barAlmost,
    AssetPaths.barFull,
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) { _started = true; _initVideo(MediaQuery.of(context).orientation); }
  }

  Future<void> _initVideo(Orientation ori) async {
    _lastOri = ori;
    final path = ori == Orientation.landscape ? AssetPaths.videoLandscape : AssetPaths.videoPortrait;
    final ctrl = VideoPlayerController.asset(path);
    await ctrl.initialize();
    ctrl.setLooping(true); ctrl.setVolume(0); ctrl.play();
    if (!mounted) { ctrl.dispose(); return; }
    final old = _vid;
    setState(() { _vid = ctrl; _vidReady = true; });
    await old?.dispose();
    _preload();
  }

  Future<void> _swapVideo(Orientation ori) async {
    _lastOri = ori;
    final path = ori == Orientation.landscape ? AssetPaths.videoLandscape : AssetPaths.videoPortrait;
    final ctrl = VideoPlayerController.asset(path);
    await ctrl.initialize();
    ctrl.setLooping(true); ctrl.setVolume(0); ctrl.play();
    if (!mounted) { ctrl.dispose(); return; }
    final old = _vid;
    setState(() { _vid = ctrl; _vidReady = true; });
    await old?.dispose();
  }

  Future<void> _preload() async {
    final imgs = AssetPaths.preloadImages;
    for (int i = 0; i < imgs.length; i++) {
      if (!mounted) return;
      try { await precacheImage(AssetImage(imgs[i]), context); } catch (_) {}
      final p = (i + 1) / imgs.length;
      final ns = p < 0.30 ? 0 : p < 0.60 ? 1 : p < 0.85 ? 2 : 3;
      if (ns != _bar && mounted) setState(() => _bar = ns);
    }
    if (mounted) {
      setState(() => _bar = 3);
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) {
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        widget.onReady();
      }
    }
  }

  @override
  void dispose() { _vid?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (ctx, ori) {
      if (_started && ori != _lastOri) {
        _lastOri = ori;
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _swapVideo(ori); });
      }
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          if (_vidReady && _vid != null)
            SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(
              width: _vid!.value.size.width, height: _vid!.value.size.height,
              child: VideoPlayer(_vid!),
            )))
          else
            const DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(
              center: Alignment.center, radius: 1.1,
              colors: [Color(0xFF17134A), Color(0xFF070714), Colors.black],
            ))),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
            stops: const [0.6, 1.0],
          ))),
          Positioned(bottom: 30, left: 0, right: 0,
            child: Center(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
              child: Image.asset(_bars[_bar], key: ValueKey(_bar), width: 260,
                errorBuilder: (c2, e2, s2) => const SizedBox(width: 260, height: 20)),
            )),
          ),
        ]),
      );
    });
  }
}
