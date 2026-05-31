import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Simple in-app browser used only to display the app's own Privacy Policy
/// and Support pages.
class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final Color tint;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
    required this.tint,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF05030E))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05030E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0820),
        foregroundColor: widget.tint,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: widget.tint),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: widget.tint,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Center(
              child: CircularProgressIndicator(color: widget.tint),
            ),
        ],
      ),
    );
  }
}
