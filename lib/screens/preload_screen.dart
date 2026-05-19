import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/media_lib.dart';

class PreloadScreen extends StatefulWidget {
  final VoidCallback onReady;

  const PreloadScreen({super.key, required this.onReady});

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen> {
  VideoPlayerController? _videoCtrl;
  int _barState = 0;
  bool _videoReady = false;
  bool _showBar = false;
  bool _started = false;

  static const _barFrames = [
    MediaLib.loadingBarStart,
    MediaLib.loadingBarHalf,
    MediaLib.loadingBarAlmostFull,
    MediaLib.loadingBarFull,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _boot();
    }
  }

  Future<void> _boot() async {
    await _initVideo();

    for (final path in _barFrames) {
      if (!mounted) return;
      await precacheImage(AssetImage(path), context);
    }
    if (!mounted) return;
    setState(() => _showBar = true);

    await _preloadAssets();
  }

  Future<void> _initVideo() async {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final asset = size.width > size.height
        ? MediaLib.loadingHorizontal
        : MediaLib.loadingVertical;

    _videoCtrl = VideoPlayerController.asset(asset);
    try {
      await _videoCtrl!.initialize();
      _videoCtrl!.setLooping(true);
      _videoCtrl!.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {}
  }

  Future<void> _preloadAssets() async {
    final images = MediaLib.allImages;
    final total = images.length;
    int done = 0;

    for (final path in images) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
      done++;

      final progress = done / total;
      final next = progress < 0.25
          ? 0
          : progress < 0.55
              ? 1
              : progress < 0.80
                  ? 2
                  : 3;

      if (next != _barState && mounted) {
        setState(() => _barState = next);
      }
    }

    if (mounted) {
      setState(() => _barState = 3);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) widget.onReady();
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoReady && _videoCtrl != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoCtrl!.value.size.width,
                height: _videoCtrl!.value.size.height,
                child: VideoPlayer(_videoCtrl!),
              ),
            ),
          if (_showBar)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Image.asset(
                    _barFrames[_barState],
                    key: ValueKey(_barState),
                    width: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
