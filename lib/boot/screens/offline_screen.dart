import 'dart:io';
import 'package:flutter/material.dart';

Future<bool> _checkNet() async {
  try {
    final r = await InternetAddress.lookup('cloudflare.com').timeout(const Duration(seconds: 4));
    return r.isNotEmpty && r[0].rawAddress.isNotEmpty;
  } catch (_) { return false; }
}

class OfflineScreen extends StatefulWidget {
  final WidgetBuilder retryBuilder;
  const OfflineScreen({super.key, required this.retryBuilder});
  @override State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> with SingleTickerProviderStateMixin {
  bool _retrying = false;
  bool _showBanner = false;
  late AnimationController _bannerCtrl;
  late Animation<double> _bannerFade;

  @override
  void initState() {
    super.initState();
    _bannerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 280), reverseDuration: const Duration(milliseconds: 220));
    _bannerFade = CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _bannerCtrl.dispose(); super.dispose(); }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final ok = await _checkNet();
    if (!mounted) return;
    if (ok) { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: widget.retryBuilder)); return; }
    setState(() => _retrying = false);
    if (_showBanner) return;
    setState(() => _showBanner = true);
    await _bannerCtrl.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _bannerCtrl.reverse();
    if (mounted) setState(() => _showBanner = false);
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final land = sz.width > sz.height;
    final bg = land ? 'assets/NoWifi/16x9_NoWifi_Screen.webp' : 'assets/NoWifi/9x16_NoWifi_Screen.webp';
    final top = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        Image.asset(bg, fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const ColoredBox(color: Color(0xFF08091A))),
        Positioned(
          left: 0, right: 0, bottom: sz.height * 0.06,
          child: Center(child: SizedBox(
            width: land ? sz.width * 0.32 : sz.width * 0.68,
            child: _RetryBtn(onTap: _retry, busy: _retrying, compact: land),
          )),
        ),
        if (_showBanner)
          Positioned(top: top + 12, left: 20, right: 20,
            child: FadeTransition(opacity: _bannerFade,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF060614).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.wifi_off_rounded, color: Color(0xFF00E5FF), size: 18),
                  SizedBox(width: 8),
                  Text('Still no internet', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _RetryBtn extends StatefulWidget {
  final VoidCallback onTap;
  final bool busy, compact;
  const _RetryBtn({required this.onTap, required this.busy, required this.compact});
  @override State<_RetryBtn> createState() => _RetryBtnState();
}

class _RetryBtnState extends State<_RetryBtn> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glow;
  late Animation<double> _glowAnim;
  @override void initState() { super.initState(); _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(_glow); }
  @override void dispose() { _glow.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(animation: _glowAnim, builder: (c, ch) => AnimatedScale(
        scale: _pressed ? 0.96 : 1.0, duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity, padding: EdgeInsets.symmetric(vertical: widget.compact ? 10 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _pressed ? const [Color(0xFF0099CC), Color(0xFF003399)] : const [Color(0xFF00E5FF), Color(0xFF0055CC)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: _pressed ? 0.2 : _glowAnim.value),
              blurRadius: _pressed ? 8 : 14 + _glowAnim.value * 18, offset: const Offset(0, 4))],
          ),
          child: Center(child: widget.busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text('Retry', style: TextStyle(color: Colors.white, fontSize: widget.compact ? 16 : 18, fontWeight: FontWeight.w800))),
        ),
      )),
    );
  }
}
