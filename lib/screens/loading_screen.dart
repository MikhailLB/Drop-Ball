import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/asset_paths.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;

  const LoadingScreen({super.key, required this.onLoadingComplete});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  VideoPlayerController? _videoController;
  int _barState = 0;
  bool _videoReady = false;
  bool _barImagesCached = false;
  bool _started = false;

  static const _barAssets = [
    AssetPaths.loadingBarStart,
    AssetPaths.loadingBarHalf,
    AssetPaths.loadingBarAlmostFull,
    AssetPaths.loadingBarFull,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  Future<void> _start() async {
    await _precacheBarImages();
    if (!mounted) return;
    setState(() => _barImagesCached = true);

    _initVideo();
    _runLoadingSequence();
  }

  Future<void> _precacheBarImages() async {
    for (final path in _barAssets) {
      if (!mounted) return;
      await precacheImage(AssetImage(path), context);
    }
  }

  Future<void> _initVideo() async {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    final videoAsset = isLandscape
        ? AssetPaths.loadingHorizontal
        : AssetPaths.loadingVertical;

    _videoController = VideoPlayerController.asset(videoAsset);
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {}
  }

  Future<void> _runLoadingSequence() async {
    final gameImages = AssetPaths.allImages;
    final totalSteps = gameImages.length;
    int loaded = 0;

    for (final path in gameImages) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
      loaded++;

      final progress = loaded / totalSteps;
      final newState = progress < 0.25
          ? 0
          : progress < 0.55
              ? 1
              : progress < 0.80
                  ? 2
                  : 3;

      if (newState != _barState && mounted) {
        setState(() => _barState = newState);
      }
    }

    if (mounted) {
      setState(() => _barState = 3);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onLoadingComplete();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoReady && _videoController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          if (_barImagesCached)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Image.asset(
                    _barAssets[_barState],
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
