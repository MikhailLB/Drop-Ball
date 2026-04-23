import 'package:flutter/material.dart';
import '../utils/asset_paths.dart';

class ConnectionLostScreen extends StatefulWidget {
  final WidgetBuilder retryBuilder;

  const ConnectionLostScreen({super.key, required this.retryBuilder});

  @override
  State<ConnectionLostScreen> createState() => _ConnectionLostScreenState();
}

class _ConnectionLostScreenState extends State<ConnectionLostScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_busy) return;
    await _pulse.forward();
    await _pulse.reverse();
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.noWifi,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => const ColoredBox(color: Colors.black),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                    bottom: 60, left: 36, right: 36),
                child: ScaleTransition(
                  scale: _scale,
                  child: _buildButton(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _busy
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00BCD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _busy ? Colors.cyanAccent.withValues(alpha: 0.3) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _busy
              ? const []
              : [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _busy ? null : _retry,
            child: Center(
              child: _busy
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Connecting...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
