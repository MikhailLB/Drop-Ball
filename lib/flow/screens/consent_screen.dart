import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cfg/flow_config.dart';
import '../infra/data_vault.dart';
import '../infra/net_probe.dart';
import '../infra/notify_relay.dart';
import 'web_shell.dart';

/// Push permission offer screen. Shows a static branded background
/// (portrait or landscape) with Accept / Skip buttons in DropBall neon theme.
class ConsentScreen extends StatefulWidget {
  final DataVault vault;
  final NotifyRelay pulse;
  final NetProbe probe;
  final String destination;
  final Future<void> Function(String token)? onTokenReady;

  const ConsentScreen({
    super.key,
    required this.vault,
    required this.pulse,
    required this.probe,
    required this.destination,
    this.onTokenReady,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen>
    with TickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final granted = await widget.pulse.askConsent();
      if (granted) {
        final token = await widget.pulse.refreshTokenAfterConsent();
        if (token != null && token.isNotEmpty) {
          await widget.onTokenReady?.call(token);
        }
      } else {
        await _setCooldown();
      }
      _openShell();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    await _setCooldown();
    _openShell();
  }

  Future<void> _setCooldown() async {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        FlowConfig.pushCooldownSecs;
    await widget.vault.writePushCooldown(until);
  }

  void _openShell() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WebShell(
        destination: widget.destination,
        vault: widget.vault,
        pulse: widget.pulse,
        probe: widget.probe,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final landscape = mq.size.width > mq.size.height;
    final bgAsset = landscape
        ? 'assets/Notifications/16x9_Notifications.webp'
        : 'assets/Notifications/9x16_Notifications.webp';
    final btnW = landscape
        ? (mq.size.width * 0.30).clamp(220.0, 360.0)
        : mq.size.width * 0.76;
    final bottomGap = mq.size.height * (landscape ? 0.05 : 0.07);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(bgAsset, fit: BoxFit.cover),
            SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: 0, right: 0, bottom: bottomGap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AcceptBtn(
                          width: btnW,
                          busy: _busy,
                          glow: _glow,
                          onTap: _accept,
                          compact: landscape,
                        ),
                        SizedBox(height: mq.size.height * 0.022),
                        _SkipBtn(onTap: _skip, compact: landscape),
                      ],
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

// ── Accept button — neon cyan→blue gradient ───────────────────────────────

class _AcceptBtn extends StatefulWidget {
  final double width;
  final bool busy;
  final bool compact;
  final AnimationController glow;
  final VoidCallback onTap;

  const _AcceptBtn({
    required this.width, required this.busy, required this.glow,
    required this.onTap, this.compact = false,
  });

  @override
  State<_AcceptBtn> createState() => _AcceptBtnState();
}

class _AcceptBtnState extends State<_AcceptBtn>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 90),
  );

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fs = widget.compact ? 16.0 : 20.0;
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); _press.forward(); },
      onTapUp: (_) { setState(() => _pressed = false); _press.reverse(); widget.onTap(); },
      onTapCancel: () { setState(() => _pressed = false); _press.reverse(); },
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, widget.glow]),
        builder: (_, ch) => Transform.scale(
          scale: 1.0 - 0.04 * _press.value,
          child: Container(
            width: widget.width,
            padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? [const Color(0xFF0099CC), const Color(0xFF003399)]
                    : [const Color(0xFF00E5FF), const Color(0xFF0055CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(
                      alpha: _pressed ? 0.2 : 0.3 + 0.2 * widget.glow.value),
                  blurRadius: _pressed ? 6 : 16 + widget.glow.value * 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.busy
                  ? SizedBox(
                      width: fs + 4, height: fs + 4,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text('Allow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fs,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                      )),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Skip button — minimal white text ──────────────────────────────────────

class _SkipBtn extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _SkipBtn({required this.onTap, this.compact = false});

  @override
  State<_SkipBtn> createState() => _SkipBtnState();
}

class _SkipBtnState extends State<_SkipBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.4 : 0.75,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 8),
          child: Text('Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 16 : 21,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
              )),
        ),
      ),
    );
  }
}
