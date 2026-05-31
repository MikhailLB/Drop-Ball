import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../utils/asset_paths.dart';
import '../widgets/aurora_background.dart';

/// Lightweight splash: loads progress, precaches orb art, then continues.
/// No video, no network — just a self-contained animated intro.
class LaunchScreen extends StatefulWidget {
  final VoidCallback onReady;
  const LaunchScreen({super.key, required this.onReady});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  double _progress = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _boot();
    }
  }

  Future<void> _boot() async {
    await ProgressStore.instance.load();

    final assets = AssetPaths.preload;
    for (var i = 0; i < assets.length; i++) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(assets[i]), context);
      } catch (_) {}
      if (mounted) setState(() => _progress = (i + 1) / assets.length);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) widget.onReady();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      tint: const Color(0xFF4FC3F7),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _intro,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Image.asset(AssetPaths.logoTitle, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 48,
              right: 48,
              bottom: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4FC3F7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'LOADING',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
