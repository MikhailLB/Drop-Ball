import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_config.dart';
import '../services/push_service.dart';
import '../services/app_storage.dart';
import '../services/net_checker.dart';
import '../utils/media_paths.dart';
import 'browser_host.dart' deferred as host;
import 'widgets/notif_buttons.dart';

class NotifScreen extends StatefulWidget {
  final AppStorage store;
  final PushService push;
  final NetChecker net;
  final String target;
  final Future<void> Function(String token)? onPushTokenReady;

  const NotifScreen({
    super.key,
    required this.store,
    required this.push,
    required this.net,
    required this.target,
    this.onPushTokenReady,
  });

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> {
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
        ? MediaPaths.nfHorizontal
        : MediaPaths.nfVertical;
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
      if (ok) {
        final token = await widget.push.refreshToken(notify: false);
        if (token != null && token.isNotEmpty) {
          await widget.onPushTokenReady?.call(token);
        } else if (kDebugMode) {
          debugPrint('[PUSH] consent granted but FCM token is empty');
        }
      } else {
        final until =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 +
            AppConfig.cooldownSeconds;
        await widget.store.writePushCooldown(until);
      }
      _openBrowserHost();
    } finally {
      _locked = false;
    }
  }

  Future<void> _skip() async {
    if (_locked) return;
    _locked = true;
    final until =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        AppConfig.cooldownSeconds;
    await widget.store.writePushCooldown(until);
    if (!mounted) return;
    _openBrowserHost();
  }

  Future<void> _openBrowserHost() async {
    await host.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => host.BrowserHost(
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
    final acceptWidth = landscape ? size.width * 0.26 : size.width * 0.58;
    final skipWidth = landscape ? size.width * 0.18 : size.width * 0.40;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomPadding =
        (landscape ? size.height * 0.04 : size.height * 0.08) + bottomInset;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AcceptButton(
            width: acceptWidth,
            compact: landscape,
            onTap: _accept,
          ),
          SizedBox(height: landscape ? 8 : 12),
          DismissButton(width: skipWidth, compact: landscape, onTap: _skip),
        ],
      ),
    );
  }
}
