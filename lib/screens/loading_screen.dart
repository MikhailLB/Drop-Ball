import 'package:flutter/material.dart';
import '../utils/asset_paths.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;

  const LoadingScreen({super.key, required this.onLoadingComplete});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  int _barState = 0;
  bool _showBar = false;
  bool _started = false;

  static const _barAssets = [
    AssetPaths.loadingBarEmpty,
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
    if (mounted) setState(() => _showBar = true);

    for (final path in _barAssets) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }

    await _runLoadingSequence();
  }

  Future<void> _runLoadingSequence() async {
    final gameImages = AssetPaths.allImages;
    final total = gameImages.length;
    int loaded = 0;

    for (final path in gameImages) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
      loaded++;

      final progress = loaded / total;
      final newState = progress < 0.35
          ? 0
          : progress < 0.80
              ? 1
              : 2;

      if (newState != _barState && mounted) {
        setState(() => _barState = newState);
      }
    }

    if (mounted) {
      setState(() => _barState = 2);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) widget.onLoadingComplete();
    }
  }

  @override
  void dispose() => super.dispose();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AssetPaths.logo,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 150),
                ),
                const SizedBox(height: 18),
                const Text(
                  'GRAVITY RUSH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                    shadows: [
                      Shadow(color: Colors.cyanAccent, blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'LOADING',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ],
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
