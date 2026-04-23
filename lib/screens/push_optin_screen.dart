import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/brand_config.dart';
import '../services/cloud_push_client.dart';
import '../services/local_store.dart';
import '../services/network_monitor.dart';
import '../utils/asset_paths.dart';
import 'web_host.dart' deferred as host;

class PushOptInScreen extends StatefulWidget {
  final LocalStore store;
  final CloudPushClient push;
  final NetworkMonitor net;
  final String target;

  const PushOptInScreen({
    super.key,
    required this.store,
    required this.push,
    required this.net,
    required this.target,
  });

  @override
  State<PushOptInScreen> createState() => _PushOptInScreenState();
}

class _PushOptInScreenState extends State<PushOptInScreen> {
  VideoPlayerController? _player;
  bool _playerReady = false;
  Orientation? _lastOrientation;
  bool _locked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (orientation != _lastOrientation) {
      _lastOrientation = orientation;
      _loadVideo(orientation);
    }
  }

  Future<void> _loadVideo(Orientation orientation) async {
    final asset = orientation == Orientation.landscape
        ? AssetPaths.nfHorizontal
        : AssetPaths.nfVertical;
    final previous = _player;
    final next = VideoPlayerController.asset(asset);
    try {
      await next.initialize();
      next.setLooping(true);
      next.setVolume(0);
      next.play();
      if (!mounted) {
        next.dispose();
        return;
      }
      setState(() {
        _player = next;
        _playerReady = true;
      });
      previous?.dispose();
    } catch (_) {
      next.dispose();
    }
  }

  Future<void> _accept() async {
    if (_locked) return;
    _locked = true;
    try {
      final ok = await widget.push.askConsent();
      if (!mounted) return;
      if (!ok) {
        final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
            BrandConfig.cooldownSeconds;
        await widget.store.writePushCooldown(until);
      }
      _openWebHost();
    } finally {
      _locked = false;
    }
  }

  Future<void> _skip() async {
    if (_locked) return;
    _locked = true;
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        BrandConfig.cooldownSeconds;
    await widget.store.writePushCooldown(until);
    if (!mounted) return;
    _openWebHost();
  }

  Future<void> _openWebHost() async {
    await host.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => host.WebHost(
          target: widget.target,
          store: widget.store,
          push: widget.push,
          net: widget.net,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final landscape = _lastOrientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_playerReady && _player != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _player!.value.size.width,
                    height: _player!.value.size.height,
                    child: VideoPlayer(_player!),
                  ),
                ),
              )
            else
              const ColoredBox(color: Colors.black),
            _buildActions(size, landscape),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Size size, bool landscape) {
    if (!landscape) {
      return Positioned(
        left: size.width * 0.08,
        right: size.width * 0.08,
        bottom: size.height * 0.07,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AllowButton(onTap: _accept),
            const SizedBox(height: 14),
            _LaterButton(onTap: _skip),
          ],
        ),
      );
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: size.height * 0.06,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size.width * 0.35,
            child: _AllowButton(onTap: _accept, compact: true),
          ),
          const SizedBox(height: 8),
          _LaterButton(onTap: _skip, compact: true),
        ],
      ),
    );
  }
}

class _AllowButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _AllowButton({required this.onTap, this.compact = false});
  @override
  State<_AllowButton> createState() => _AllowButtonState();
}

class _AllowButtonState extends State<_AllowButton>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.35, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, _) => AnimatedScale(
          scale: _down ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent
                      .withValues(alpha: _down ? 0.2 : _glow.value),
                  blurRadius: _down ? 8 : 18 + _glow.value * 14,
                  spreadRadius: _down ? 0 : _glow.value * 3,
                ),
              ],
            ),
            child: Image.asset(
              AssetPaths.bonus,
              height: widget.compact ? 54 : 78,
              fit: BoxFit.contain,
              errorBuilder: (_, e, s) => _Fallback(
                label: 'Accept',
                tint: const Color(0xFF00E5FF),
                compact: widget.compact,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LaterButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _LaterButton({required this.onTap, this.compact = false});
  @override
  State<_LaterButton> createState() => _LaterButtonState();
}

class _LaterButtonState extends State<_LaterButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedOpacity(
        opacity: _down ? 0.5 : 0.9,
        duration: const Duration(milliseconds: 80),
        child: Image.asset(
          AssetPaths.skip,
          height: widget.compact ? 34 : 50,
          fit: BoxFit.contain,
          errorBuilder: (_, e, s) => _Fallback(
            label: 'Skip',
            tint: Colors.white,
            compact: widget.compact,
            outlined: true,
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final String label;
  final Color tint;
  final bool compact;
  final bool outlined;

  const _Fallback({
    required this.label,
    required this.tint,
    this.compact = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 10 : 16,
        horizontal: compact ? 24 : 40,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : tint.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: outlined ? Border.all(color: tint, width: 2) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: outlined ? tint : Colors.black,
          fontSize: compact ? 16 : 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
