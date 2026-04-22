import 'package:flutter/material.dart';
import '../utils/asset_paths.dart';

class NoInternetScreen extends StatefulWidget {
  final WidgetBuilder retryScreenBuilder;

  const NoInternetScreen({super.key, required this.retryScreenBuilder});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  bool _isRetrying = false;
  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _btnCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRetry() async {
    if (_isRetrying) return;
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryScreenBuilder),
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
                padding: const EdgeInsets.only(bottom: 60, left: 36, right: 36),
                child: ScaleTransition(
                  scale: _btnScale,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _isRetrying
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF00E5FF),
                                  Color(0xFF00BCD4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: _isRetrying
                            ? Colors.cyanAccent.withValues(alpha: 0.3)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isRetrying
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.cyanAccent
                                      .withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isRetrying ? null : _onRetry,
                          child: Center(
                            child: _isRetrying
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
