import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/flow_cache.dart';
import '../services/net_sensor.dart';
import '../services/push_relay.dart';
import '../services/safe_http.dart';
import 'offline_screen.dart';

Future<void> prepareEngine() async {}

class WebContainer extends StatefulWidget {
  final String url;
  final FlowCache cache;
  final PushRelay push;
  final NetSensor sensor;

  const WebContainer({super.key, required this.url, required this.cache, required this.push, required this.sensor});
  @override State<WebContainer> createState() => _WebContainerState();
}

class _WebContainerState extends State<WebContainer> with WidgetsBindingObserver {
  late final WebViewController _wv;
  bool _loading = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _offlineRouted = false;
  String? _lastUrl;
  int _retries = 0;

  void _immersive() => SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _immersive();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _immersive();

    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(safeHttp.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) { if (mounted) setState(() => _loading = true); },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          _retries = 0;
          _injectSafeArea();
          _injectKeyboardFix();
          _injectWindowOpenFix();
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            _wv.runJavaScript('window.dispatchEvent(new Event("resize"));');
            _injectSafeArea();
          });
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame != true) return;
          final d = e.description.toLowerCase();
          final loop = d.contains('too_many_redirects') || d.contains('too many redirects') || e.errorCode == -1007 || e.errorCode == -9;
          if (loop && _lastUrl != null && _retries < 3) { _retries++; _wv.loadRequest(Uri.parse(_lastUrl!)); return; }
          _checkOffline();
        },
        onHttpError: (_) {},
        onNavigationRequest: (req) {
          final uri = Uri.tryParse(req.url);
          if (uri == null) return NavigationDecision.prevent;
          final s = uri.scheme;
          if (s == 'http' || s == 'https' || s == 'about' || s == 'data' || s == 'blob') {
            if (req.isMainFrame) _lastUrl = req.url;
            return NavigationDecision.navigate;
          }
          _openExternal(uri);
          return NavigationDecision.prevent;
        },
      ));

    _configurePlatform();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _wv.loadRequest(Uri.parse(widget.url));
      });
    });

    widget.push.onPushDestination = (url) {
      if (mounted) _wv.loadRequest(Uri.parse(url));
    };

    _connSub = widget.sensor.onChange.listen((r) {
      if (r.every((s) => s == ConnectivityResult.none)) _checkOffline();
    });
  }

  Future<void> _checkOffline() async {
    if (_offlineRouted) return;
    final ok = await widget.sensor.hasInternet();
    if (ok || !mounted) return;
    _offlineRouted = true;
    final cur = await _wv.currentUrl() ?? widget.url;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineScreen(retryBuilder: (_) => WebContainer(url: cur, cache: widget.cache, push: widget.push, sensor: widget.sensor)),
    ));
  }

  void _configurePlatform() {
    if (Platform.isAndroid && _wv.platform is AndroidWebViewController) {
      final ac = _wv.platform as AndroidWebViewController;
      ac.setMediaPlaybackRequiresUserGesture(false);
      ac.setOnShowFileSelector(_pickFiles);
      final cm = AndroidWebViewCookieManager(AndroidWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(const PlatformWebViewCookieManagerCreationParams()));
      cm.setAcceptThirdPartyCookies(ac, true);
    }
  }

  Future<List<String>> _pickFiles(FileSelectorParams p) async {
    try {
      final r = await FilePicker.platform.pickFiles(allowMultiple: p.mode == FileSelectorMode.openMultiple, type: FileType.any);
      if (r != null) return r.files.where((f) => f.path != null).map((f) => Uri.file(f.path!).toString()).toList();
    } catch (_) {}
    return [];
  }

  void _openExternal(Uri uri) async {
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  void _injectSafeArea() {
    _wv.runJavaScript(r'''
(function(){if(window.__dbSa)return;window.__dbSa=true;var T=':root{--safe-area-inset-top:0px!important;--safe-area-inset-bottom:0px!important;--sat:0px!important;--sab:0px!important;}html,body,#app,#root{padding-top:0!important;margin-top:0!important;}';function apply(){var h=document.head||document.documentElement;if(!h)return;var s=document.getElementById('__dbSa');if(!s){s=document.createElement('style');s.id='__dbSa';h.appendChild(s);}if(s.textContent!==T)s.textContent=T;}apply();setInterval(apply,2500);})();
''');
  }

  void _injectKeyboardFix() {
    _wv.runJavaScript(r'''
(function(){if(window.__dbKb)return;window.__dbKb=true;function iL(n){return n&&(n.tagName==='INPUT'||n.tagName==='TEXTAREA'||n.isContentEditable);}function roll(){var el=document.activeElement;if(!iL(el))return;var vp=window.visualViewport;if(vp){var r=el.getBoundingClientRect();if(r.bottom>vp.offsetTop+vp.height-20)el.scrollIntoView({behavior:'auto',block:'nearest'});}else{el.scrollIntoView({behavior:'auto',block:'nearest'});}}document.addEventListener('focusin',function(e){if(iL(e.target))setTimeout(roll,350);});if(window.visualViewport){var prev=window.visualViewport.height;window.visualViewport.addEventListener('resize',function(){var h=window.visualViewport.height;if(h<prev)setTimeout(roll,120);prev=h;});}})();
''');
  }

  void _injectWindowOpenFix() {
    _wv.runJavaScript(r'''
(function(){if(window.__dbWo)return;window.__dbWo=true;var _o=window.open;window.open=function(url,t,f){if(url&&(url.startsWith('http://')||url.startsWith('https://'))){window.location.href=url;return window;}return _o?_o.call(window,url,t,f):null;};document.addEventListener('click',function(e){var el=e.target;while(el&&el.tagName!=='A'){el=el.parentElement;}if(el&&el.getAttribute('target')==='_blank'&&el.href){e.preventDefault();window.location.href=el.href;}},true);})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    widget.push.onPushDestination = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Future<bool> _onPop() async {
    if (await _wv.canGoBack()) { await _wv.goBack(); return false; }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async { if (!didPop) await _onPop(); },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(fit: StackFit.expand, children: [
          WebViewWidget(controller: _wv),
          if (_loading) Container(color: Colors.black.withValues(alpha: 0.5),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))),
        ]),
      ),
    );
  }
}
