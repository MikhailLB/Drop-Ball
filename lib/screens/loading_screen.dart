import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  double _progress = 0;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _loadAssets();
  }

  Future<void> _initVideo() async {
    final orientation = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).orientation;

    final videoAsset = orientation == Orientation.landscape
        ? AssetPaths.loadingHorizontal
        : AssetPaths.loadingVertical;

    _videoController = VideoPlayerController.asset(videoAsset);
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      // Video may fail on some platforms; proceed without it
    }
  }

  Future<void> _loadAssets() async {
    final totalImages = AssetPaths.allImages.length;
    int loaded = 0;

    for (final path in AssetPaths.allImages) {
      try {
        final bytes = await rootBundle.load(path);
        await precacheImage(
          MemoryImage(bytes.buffer.asUint8List()),
          // ignore: use_build_context_synchronously
          context,
        );
      } catch (_) {
        // Some assets may not precache; that's OK
      }
      loaded++;
      if (mounted) {
        setState(() => _progress = loaded / totalImages);
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) widget.onLoadingComplete();
  }

  String get _currentBarAsset {
    if (_progress < 0.25) return AssetPaths.loadingBarStart;
    if (_progress < 0.50) return AssetPaths.loadingBarHalf;
    if (_progress < 0.75) return AssetPaths.loadingBarAlmostFull;
    return AssetPaths.loadingBarFull;
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
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                _currentBarAsset,
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
