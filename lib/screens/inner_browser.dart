import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Simple in-app browser used for Privacy Policy and Support pages.
class InnerBrowser extends StatefulWidget {
  final String title;
  final String url;

  const InnerBrowser({super.key, required this.title, required this.url});

  @override
  State<InnerBrowser> createState() => _InnerBrowserState();
}

class _InnerBrowserState extends State<InnerBrowser> {
  late final WebViewController _ctrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF08091A),
        elevation: 0,
        title: Text(widget.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _ctrl),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
        ],
      ),
    );
  }
}
