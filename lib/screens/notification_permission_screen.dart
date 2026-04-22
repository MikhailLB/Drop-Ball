import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_settings.dart';
import '../services/connectivity_service.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';
import '../utils/asset_paths.dart';
import 'content_screen.dart' deferred as content;

class NotificationPermissionScreen extends StatefulWidget {
  final StorageService storage;
  final PushNotificationService pushService;
  final ConnectivityService connectivity;
  final String contentUrl;

  const NotificationPermissionScreen({
    super.key,
    required this.storage,
    required this.pushService,
    required this.connectivity,
    required this.contentUrl,
  });

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  Orientation? _currentOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (orientation != _currentOrientation) {
      _currentOrientation = orientation;
      _initVideo(orientation);
    }
  }

  Future<void> _initVideo(Orientation orientation) async {
    final asset = orientation == Orientation.landscape
        ? AssetPaths.nfHorizontal
        : AssetPaths.nfVertical;

    final oldController = _controller;
    final newController = VideoPlayerController.asset(asset);

    try {
      await newController.initialize();
      newController.setLooping(true);
      newController.setVolume(0);
      newController.play();

      if (!mounted) {
        newController.dispose();
        return;
      }

      setState(() {
        _controller = newController;
        _videoReady = true;
      });

      oldController?.dispose();
    } catch (_) {
      newController.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onAccept() async {
    final granted = await widget.pushService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      final skipUntil = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
          AppSettings.notificationRetryDelaySeconds;
      await widget.storage.setNotificationSkipUntil(skipUntil);
    }
    _goToContent();
  }

  void _onSkip() async {
    final skipUntil = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        AppSettings.notificationRetryDelaySeconds;
    await widget.storage.setNotificationSkipUntil(skipUntil);
    if (!mounted) return;
    _goToContent();
  }

  Future<void> _goToContent() async {
    await content.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => content.ContentScreen(
          url: widget.contentUrl,
          storage: widget.storage,
          pushService: widget.pushService,
          connectivity: widget.connectivity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = _currentOrientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_videoReady && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            else
              Container(color: Colors.black),

            if (!isLandscape)
              Positioned(
                left: size.width * 0.08,
                right: size.width * 0.08,
                bottom: size.height * 0.07,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AcceptButton(onTap: _onAccept),
                    const SizedBox(height: 14),
                    _SkipButton(onTap: _onSkip),
                  ],
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                bottom: size.height * 0.06,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: size.width * 0.35,
                      child: _AcceptButton(onTap: _onAccept, compact: true),
                    ),
                    const SizedBox(height: 8),
                    _SkipButton(onTap: _onSkip, compact: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AcceptButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _AcceptButton({required this.onTap, this.compact = false});
  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.35, end: 0.8).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, _) => AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent
                      .withValues(alpha: _pressed ? 0.2 : _glowAnim.value),
                  blurRadius: _pressed ? 8 : 18 + _glowAnim.value * 14,
                  spreadRadius: _pressed ? 0 : _glowAnim.value * 3,
                ),
              ],
            ),
            child: Image.asset(
              AssetPaths.bonus,
              height: widget.compact ? 54 : 78,
              fit: BoxFit.contain,
              errorBuilder: (_, e, s) => _FallbackButton(
                label: 'Accept',
                color: const Color(0xFF00E5FF),
                compact: widget.compact,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _SkipButton({required this.onTap, this.compact = false});
  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.5 : 0.9,
        duration: const Duration(milliseconds: 80),
        child: Image.asset(
          AssetPaths.skip,
          height: widget.compact ? 34 : 50,
          fit: BoxFit.contain,
          errorBuilder: (_, e, s) => _FallbackButton(
            label: 'Skip',
            color: Colors.white,
            compact: widget.compact,
            transparent: true,
          ),
        ),
      ),
    );
  }
}

class _FallbackButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;
  final bool transparent;

  const _FallbackButton({
    required this.label,
    required this.color,
    this.compact = false,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 10 : 16,
        horizontal: compact ? 24 : 40,
      ),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: transparent ? Border.all(color: color, width: 2) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: transparent ? color : Colors.black,
          fontSize: compact ? 16 : 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
