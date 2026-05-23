import 'package:flutter/material.dart';
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
  bool _locked = false;

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
        }
      } else {
        final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
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
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
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
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final landscape = orientation == Orientation.landscape;
        final bgAsset =
            landscape ? MediaPaths.notifLandscape : MediaPaths.notifPortrait;
        final size = MediaQuery.of(context).size;
        final acceptWidth = landscape ? size.width * 0.26 : size.width * 0.58;
        final skipWidth = landscape ? size.width * 0.18 : size.width * 0.40;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final bottomPadding =
            (landscape ? size.height * 0.04 : size.height * 0.08) +
                bottomInset;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                bgAsset,
                fit: BoxFit.cover,
                errorBuilder: (context2, err2, stack2) =>
                    const ColoredBox(color: Colors.black),
              ),
              Positioned(
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
                    DismissButton(
                        width: skipWidth,
                        compact: landscape,
                        onTap: _skip),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
