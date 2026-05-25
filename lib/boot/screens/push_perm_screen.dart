import 'package:flutter/material.dart';
import '../config/app_brand.dart';
import '../services/flow_cache.dart';
import '../services/push_relay.dart';
import '../services/net_sensor.dart';
import 'web_container.dart' deferred as wc;

class PushPermScreen extends StatefulWidget {
  final FlowCache cache;
  final PushRelay push;
  final NetSensor sensor;
  final String targetUrl;

  const PushPermScreen({super.key, required this.cache, required this.push, required this.sensor, required this.targetUrl});
  @override State<PushPermScreen> createState() => _PushPermScreenState();
}

class _PushPermScreenState extends State<PushPermScreen> {
  void _accept() async {
    final ok = await widget.push.askConsent();
    if (!mounted) return;
    if (!ok) {
      final skip = DateTime.now().millisecondsSinceEpoch ~/ 1000 + AppBrand.notifCooldownSecs;
      await widget.cache.setNotifSkip(skip);
    }
    _goContent();
  }

  void _skip() async {
    final skip = DateTime.now().millisecondsSinceEpoch ~/ 1000 + AppBrand.notifCooldownSecs;
    await widget.cache.setNotifSkip(skip);
    if (!mounted) return;
    _goContent();
  }

  Future<void> _goContent() async {
    await wc.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => wc.WebContainer(url: widget.targetUrl, cache: widget.cache, push: widget.push, sensor: widget.sensor),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final land = sz.width > sz.height;
    final bg = land ? 'assets/Notifications/16x9_Notifications.webp' : 'assets/Notifications/9x16_Notifications.webp';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(width: sz.width, height: sz.height, child: Stack(fit: StackFit.expand, children: [
        Image.asset(bg, fit: BoxFit.cover, errorBuilder: (c, e, s) => const ColoredBox(color: Color(0xFF08091A))),
        Positioned(
          left: 0, right: 0, bottom: sz.height * 0.04,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: SizedBox(
              width: land ? sz.width * 0.32 : sz.width * 0.68,
              child: _AcceptBtn(onTap: _accept, compact: land),
            )),
            const SizedBox(height: 10),
            _SkipBtn(onTap: _skip, compact: land),
          ]),
        ),
      ])),
    );
  }
}

class _AcceptBtn extends StatefulWidget {
  final VoidCallback onTap; final bool compact;
  const _AcceptBtn({required this.onTap, this.compact = false});
  @override State<_AcceptBtn> createState() => _AcceptBtnState();
}
class _AcceptBtnState extends State<_AcceptBtn> with SingleTickerProviderStateMixin {
  bool _p = false; late AnimationController _g; late Animation<double> _ga;
  @override void initState() { super.initState(); _g = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); _ga = Tween<double>(begin: 0.3, end: 0.7).animate(_g); }
  @override void dispose() { _g.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTapDown: (_) => setState(() => _p = true),
    onTapUp: (_) { setState(() => _p = false); widget.onTap(); },
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedBuilder(animation: _ga, builder: (c, ch) => AnimatedScale(scale: _p ? 0.96 : 1.0, duration: const Duration(milliseconds: 80), child: Container(
      width: double.infinity, padding: EdgeInsets.symmetric(vertical: widget.compact ? 10 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _p ? const [Color(0xFF0099CC), Color(0xFF003399)] : const [Color(0xFF00E5FF), Color(0xFF0055CC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: _p ? 0.2 : _ga.value), blurRadius: _p ? 8 : 14 + _ga.value * 18, offset: const Offset(0, 4))],
      ),
      child: Center(child: Text('Allow', style: TextStyle(color: Colors.white, fontSize: widget.compact ? 16 : 20, fontWeight: FontWeight.w800))),
    ))),
  );
}

class _SkipBtn extends StatefulWidget {
  final VoidCallback onTap; final bool compact;
  const _SkipBtn({required this.onTap, this.compact = false});
  @override State<_SkipBtn> createState() => _SkipBtnState();
}
class _SkipBtnState extends State<_SkipBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTapDown: (_) => setState(() => _p = true),
    onTapUp: (_) { setState(() => _p = false); widget.onTap(); },
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedOpacity(opacity: _p ? 0.5 : 0.85, duration: const Duration(milliseconds: 80), child: Padding(
      padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 8),
      child: Center(child: Text('Skip', style: TextStyle(color: Colors.white, fontSize: widget.compact ? 16 : 22, fontWeight: FontWeight.w700, shadows: const [Shadow(color: Colors.black54, blurRadius: 6)]))),
    )),
  );
}
