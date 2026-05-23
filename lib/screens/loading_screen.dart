import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../utils/media_paths.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;

  const LoadingScreen({super.key, required this.onLoadingComplete});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  // 0=empty, 1=half, 2=almost, 3=full
  int _barState = 0;
  bool _started = false;

  VideoPlayerController? _videoController;
  bool _videoReady = false;
  Orientation? _currentOrientation;

  static const _barAssets = [
    MediaPaths.loadingBarEmpty,
    MediaPaths.loadingBarHalf,
    MediaPaths.loadingBarAlmost,
    MediaPaths.loadingBarFull,
  ];

  @override
  void initState() {
    super.initState();
    // Allow all orientations while loading screen is active
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _initForOrientation(MediaQuery.of(context).orientation);
    }
  }

  Future<void> _initForOrientation(Orientation orientation) async {
    _currentOrientation = orientation;

    final videoPath = orientation == Orientation.landscape
        ? MediaPaths.loadingVideoLandscape
        : MediaPaths.loadingVideoPortrait;

    final controller = VideoPlayerController.asset(videoPath);
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(0);
    controller.play();

    if (!mounted) {
      controller.dispose();
      return;
    }

    final old = _videoController;
    setState(() {
      _videoController = controller;
      _videoReady = true;
    });
    await old?.dispose();

    _runLoadingSequence();
  }

  @override
  void didUpdateWidget(LoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _runLoadingSequence() async {
    final gameImages = MediaPaths.allImages;
    final total = gameImages.length;
    int loaded = 0;

    for (final path in gameImages) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
      loaded++;

      final progress = loaded / total;
      final newState = progress < 0.30
          ? 0
          : progress < 0.60
              ? 1
              : progress < 0.85
                  ? 2
                  : 3;

      if (newState != _barState && mounted) {
        setState(() => _barState = newState);
      }
    }

    if (mounted) {
      setState(() => _barState = 3);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        // Re-lock to portrait before leaving
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        widget.onLoadingComplete();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        // Hot-swap video when device rotates
        if (_started && orientation != _currentOrientation) {
          _currentOrientation = orientation;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _swapVideo(orientation);
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Video background
              if (_videoReady && _videoController != null)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
              else
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1,
                      colors: [
                        Color(0xFF17134A),
                        Color(0xFF070714),
                        Colors.black,
                      ],
                    ),
                  ),
                ),

              // Semi-transparent overlay so bar is visible on bright videos
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),

              // Loading bar — 30px from bottom
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Image.asset(
                      _barAssets[_barState],
                      key: ValueKey(_barState),
                      width: 260,
                      fit: BoxFit.contain,
                      errorBuilder: (context2, err2, stack2) => const SizedBox(
                        width: 260,
                        height: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _swapVideo(Orientation orientation) async {
    final videoPath = orientation == Orientation.landscape
        ? MediaPaths.loadingVideoLandscape
        : MediaPaths.loadingVideoPortrait;

    final controller = VideoPlayerController.asset(videoPath);
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(0);
    controller.play();

    if (!mounted) {
      controller.dispose();
      return;
    }

    final old = _videoController;
    setState(() {
      _videoController = controller;
      _videoReady = true;
    });
    await old?.dispose();
  }
}
