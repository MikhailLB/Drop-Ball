import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../services/browser_http.dart';
import '../services/cloud_push_client.dart';
import '../services/local_store.dart';
import '../services/network_monitor.dart';
import 'connection_lost_screen.dart';

Future<void> primeBrowser() async {}

class WebHost extends StatefulWidget {
  final String target;
  final LocalStore store;
  final CloudPushClient push;
  final NetworkMonitor net;

  const WebHost({
    super.key,
    required this.target,
    required this.store,
    required this.push,
    required this.net,
  });

  @override
  State<WebHost> createState() => _WebHostState();
}

class _WebHostState extends State<WebHost> with WidgetsBindingObserver {
  late final WebViewController _wv;
  bool _spinning = true;
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  bool _offlineRouted = false;
  String? _lastMainFrameUrl;
  int _redirectRetries = 0;
  String? _firstFinalUrl;

  // Fullscreen video overlay
  Widget? _fullscreenWidget;
  void Function()? _hideFullscreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockOrientations();
    _applyFullscreen();

    // Platform-specific creation params. iOS WKWebView REQUIRES these to
    // be set at construction time — calling setters later has no effect:
    //   * allowsInlineMediaPlayback: true  -> <video> doesn't force
    //     fullscreen QuickTime overlay on tap.
    //   * mediaTypesRequiringUserAction: {} -> autoplay (with muted)
    //     works without an initial tap, matching Android behaviour.
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _wv = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(browserHttp.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(_delegate());

    _setupPlatform();
    _wv.loadRequest(Uri.parse(widget.target));

    widget.push.onRemoteTarget = (url) {
      if (!mounted) return;
      _wv.loadRequest(Uri.parse(url));
    };

    _netSub = widget.net.watch().listen((statuses) {
      final allGone = statuses.every((s) => s == ConnectivityResult.none);
      if (allGone) _maybeRouteOffline();
    });
  }

  void _lockOrientations() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _applyFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyFullscreen();
  }

  NavigationDelegate _delegate() {
    return NavigationDelegate(
      onPageStarted: (_) {
        if (mounted) setState(() => _spinning = true);
      },
      onPageFinished: (url) {
        if (mounted) setState(() => _spinning = false);
        _redirectRetries = 0;
        _firstFinalUrl ??= url;
        _injectSafeAreaShim();
        _injectKeyboardScroll();
        _injectCameraBlocker();
        _injectMediaAutoplay();
      },
      onWebResourceError: (err) {
        if (err.isForMainFrame != true) return;
        final desc = err.description.toLowerCase();
        final loop =
            desc.contains('too_many_redirects') ||
            desc.contains('too many redirects') ||
            err.errorCode == -1007 ||
            err.errorCode == -9;
        if (loop && _lastMainFrameUrl != null && _redirectRetries < 3) {
          _redirectRetries++;
          _wv.loadRequest(Uri.parse(_lastMainFrameUrl!));
          return;
        }
        _maybeRouteOffline();
      },
      onHttpError: (_) {},
      onNavigationRequest: (req) {
        final uri = Uri.tryParse(req.url);
        if (uri == null) return NavigationDecision.prevent;
        final scheme = uri.scheme;
        final browserScheme =
            scheme == 'http' ||
            scheme == 'https' ||
            scheme == 'about' ||
            scheme == 'data' ||
            scheme == 'blob';
        if (browserScheme) {
          if (req.isMainFrame) _lastMainFrameUrl = req.url;
          return NavigationDecision.navigate;
        }
        _launchExternal(uri);
        return NavigationDecision.prevent;
      },
    );
  }

  void _setupPlatform() {
    if (Platform.isIOS && _wv.platform is WebKitWebViewController) {
      final ios = _wv.platform as WebKitWebViewController;
      // Native edge-swipe back/forward like Mobile Safari.
      ios.setAllowsBackForwardNavigationGestures(true);
    }
    if (Platform.isAndroid && _wv.platform is AndroidWebViewController) {
      final android = _wv.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setOnShowFileSelector(_pickFiles);

      // Grant only DRM-related permissions; deny camera/mic
      android.setOnPlatformPermissionRequest((
        PlatformWebViewPermissionRequest request,
      ) {
        final drmOnly = request.types.every(
          (t) =>
              t == AndroidWebViewPermissionResourceType.protectedMediaId ||
              t == AndroidWebViewPermissionResourceType.midiSysex,
        );
        if (drmOnly) {
          request.grant();
        } else {
          request.deny();
        }
      });

      // Fullscreen video overlay (casino video player fullscreen button)
      android.setCustomWidgetCallbacks(
        onShowCustomWidget: (Widget widget, void Function() hideCallback) {
          _hideFullscreen = hideCallback;
          if (mounted) setState(() => _fullscreenWidget = widget);
        },
        onHideCustomWidget: () {
          _hideFullscreen = null;
          if (mounted) setState(() => _fullscreenWidget = null);
        },
      );

      final cookies = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      cookies.setAcceptThirdPartyCookies(android, true);
    }
  }

  Future<List<String>> _pickFiles(FileSelectorParams params) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: FileType.any,
      );
      if (result == null) return const [];
      return result.files
          .where((f) => f.path != null)
          .map((f) => Uri.file(f.path!).toString())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _maybeRouteOffline() async {
    if (_offlineRouted) return;
    final hasNet = await widget.net.isOnline();
    if (hasNet || !mounted) return;
    _offlineRouted = true;
    final currentUrl = await _wv.currentUrl() ?? widget.target;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConnectionLostScreen(
          net: widget.net,
          retryBuilder: (_) => WebHost(
            target: currentUrl,
            store: widget.store,
            push: widget.push,
            net: widget.net,
          ),
        ),
      ),
    );
  }

  void _launchExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _injectKeyboardScroll() {
    _wv.runJavaScript(r'''
(function(){
  if (window.__grKbFix) return;
  window.__grKbFix = true;
  function inputLike(n){ return n && (n.tagName==='INPUT' || n.tagName==='TEXTAREA' || n.isContentEditable); }
  function focusRoll(){
    var el = document.activeElement;
    if (!inputLike(el)) return;
    var vp = window.visualViewport;
    if (vp){
      var r = el.getBoundingClientRect();
      if (r.bottom > vp.offsetTop + vp.height - 20 || r.top < vp.offsetTop){
        el.scrollIntoView({ behavior:'smooth', block:'center' });
      }
    } else {
      el.scrollIntoView({ behavior:'smooth', block:'center' });
    }
  }
  document.addEventListener('focusin', function(e){
    if (inputLike(e.target)){
      // Defeat iOS auto-zoom on small inputs by bumping the *computed*
      // font-size to >=16px while focused, then restoring on blur.
      try {
        var t = e.target;
        var cur = parseFloat(getComputedStyle(t).fontSize) || 0;
        if (cur < 16){
          t.dataset.__grPrevFs = t.style.fontSize || '';
          t.style.setProperty('font-size','16px','important');
        }
      } catch(_){}
      setTimeout(focusRoll,250);
      setTimeout(focusRoll,500);
      setTimeout(focusRoll,800);
    }
  });
  document.addEventListener('focusout', function(e){
    try {
      var t = e.target;
      if (t && t.dataset && '__grPrevFs' in t.dataset){
        if (t.dataset.__grPrevFs) t.style.fontSize = t.dataset.__grPrevFs;
        else t.style.removeProperty('font-size');
        delete t.dataset.__grPrevFs;
      }
    } catch(_){}
  });
  if (window.visualViewport){
    var prev = window.visualViewport.height;
    window.visualViewport.addEventListener('resize', function(){
      var h = window.visualViewport.height;
      if (h < prev){ setTimeout(focusRoll,80); setTimeout(focusRoll,300); }
      prev = h;
    });
  }
})();
''');
  }

  /// Strip the `capture` attribute from every `<input type="file">` and
  /// disable `navigator.mediaDevices.getUserMedia` so iOS WKWebView never
  /// reaches UIImagePicker's camera source. The app intentionally does not
  /// declare NSCameraUsageDescription / NSMicrophoneUsageDescription, so
  /// any request for camera or mic would crash the process. Photo Library
  /// uploads still work because the picker falls back to the gallery.
  void _injectCameraBlocker() {
    _wv.runJavaScript(r'''
(function(){
  if (window.__grNoCam) return;
  window.__grNoCam = true;

  function strip(el){
    if (!el || el.tagName !== 'INPUT') return;
    if ((el.type || '').toLowerCase() !== 'file') return;
    if (el.hasAttribute('capture')) el.removeAttribute('capture');
    var accept = (el.getAttribute('accept') || '').toLowerCase();
    if (accept.indexOf('video') !== -1 || accept.indexOf('audio') !== -1){
      el.setAttribute('accept', 'image/*');
    }
  }
  function sweep(){
    var nodes = document.querySelectorAll('input[type=file]');
    for (var i = 0; i < nodes.length; i++) strip(nodes[i]);
  }
  sweep();
  var mo = new MutationObserver(function(muts){
    for (var i = 0; i < muts.length; i++){
      var m = muts[i];
      if (m.type === 'attributes'){ strip(m.target); continue; }
      for (var j = 0; j < m.addedNodes.length; j++){
        var n = m.addedNodes[j];
        if (!n || n.nodeType !== 1) continue;
        strip(n);
        if (n.querySelectorAll){
          var sub = n.querySelectorAll('input[type=file]');
          for (var k = 0; k < sub.length; k++) strip(sub[k]);
        }
      }
    }
  });
  mo.observe(document.documentElement, {
    childList: true, subtree: true,
    attributes: true, attributeFilter: ['capture','accept','type']
  });

  // getUserMedia / mediaDevices are unavailable in WKWebView anyway, but
  // stub them defensively so any site code that probes them gets a
  // graceful rejection instead of throwing in the user's face.
  try {
    var blocked = function(){
      return Promise.reject(new DOMException('NotAllowedError'));
    };
    if (navigator.mediaDevices){
      navigator.mediaDevices.getUserMedia = blocked;
      navigator.mediaDevices.getDisplayMedia = blocked;
    } else {
      Object.defineProperty(navigator, 'mediaDevices', {
        configurable: true,
        value: { getUserMedia: blocked, getDisplayMedia: blocked }
      });
    }
    if (navigator.getUserMedia) navigator.getUserMedia = function(_, __, err){
      try { err && err(new Error('NotAllowedError')); } catch(_){}
    };
  } catch(_){}
})();
''');
  }

  /// Force every `<video>` on the page to autoplay inline + muted.
  ///
  /// Even with `mediaTypesRequiringUserAction: {}` on the WKWebView config,
  /// iOS will still NOT autoplay a video unless the element itself has
  /// `playsinline` set AND is muted at the moment `play()` is called. Web
  /// pages we don't control often ship `<video autoplay>` without those
  /// attributes — the result is a black box where the video should be.
  ///
  /// We:
  ///   1. Patch every existing <video> with playsinline / webkit-playsinline,
  ///      muted, and call play() (catching the rejection promise so a
  ///      single non-autoplay video doesn't throw uncaught).
  ///   2. Re-sweep on touchend (some sites gate autoplay behind a user
  ///      gesture; the first tap kicks off everything else).
  ///   3. Watch the DOM for new <video> elements added after page load
  ///      (SPAs, lazy-loaded carousels, casino-game iframes).
  ///   4. Backstop sweep every 1500ms in case MutationObserver misses a
  ///      shadow-root mounted video (rare but happens with some video
  ///      players).
  void _injectMediaAutoplay() {
    _wv.runJavaScript(r'''
(function(){
  if (window.__grVideoAuto) return;
  window.__grVideoAuto = true;
  function prep(v){
    try {
      v.setAttribute('playsinline',''); v.setAttribute('webkit-playsinline','');
      v.playsInline=true; v.muted=true; v.defaultMuted=true; v.autoplay=true;
      var p=v.play&&v.play(); if(p&&p.catch)p.catch(function(){});
    } catch(_){}
  }
  function sweep(root){
    try { var l=(root||document).querySelectorAll('video'); for(var i=0;i<l.length;i++)prep(l[i]); }catch(_){}
  }
  sweep(document);
  document.addEventListener('touchend',function(){sweep(document);},{passive:true});
  var mo=new MutationObserver(function(recs){
    for(var i=0;i<recs.length;i++){
      var nodes=recs[i].addedNodes||[];
      for(var j=0;j<nodes.length;j++){
        var n=nodes[j]; if(!n||n.nodeType!==1)continue;
        if(n.tagName==='VIDEO')prep(n); sweep(n);
      }
    }
  });
  mo.observe(document.documentElement,{childList:true,subtree:true});
  setInterval(function(){sweep(document);},1500);
})();
''');
  }

  void _injectSafeAreaShim() {
    _wv.runJavaScript(r'''
(function(){
  if (window.__grSaShim) return;
  window.__grSaShim = true;
  var ID = '__grSaShim';
  var CSS = ':root{'
    + '--safe-area-inset-top:0px!important;'
    + '--safe-area-inset-right:0px!important;'
    + '--safe-area-inset-bottom:0px!important;'
    + '--safe-area-inset-left:0px!important;'
    + '--sat:0px!important;--sar:0px!important;'
    + '--sab:0px!important;--sal:0px!important;'
    + '--safe-top:0px!important;--safe-right:0px!important;'
    + '--safe-bottom:0px!important;--safe-left:0px!important;'
    + '}'
    + 'html,body,#__nuxt,#__layout,#app,#root,.gameview-mobile-header{'
    + 'padding-top:0!important;padding-left:0!important;padding-right:0!important;margin-top:0!important;'
    + 'touch-action:pan-x pan-y!important;'
    + '}'
    + 'html{-webkit-text-size-adjust:100%!important;text-size-adjust:100%!important;}'
    // iOS Safari/WKWebView auto-zooms a focused field if its computed
    // font-size is < 16px. Forcing 16px on every editable element kills
    // that zoom-in jump without changing visible layout (browsers honor
    // the rule only at focus-time for inputs).
    + 'input,textarea,select,[contenteditable="true"]{'
    + 'font-size:16px!important;max-height:none;'
    + '-webkit-text-size-adjust:100%!important;'
    + '}';
  var WANT = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, viewport-fit=contain';
  function apply(){
    var head = document.head || document.documentElement;
    if (!head) return;
    var vp = document.querySelector('meta[name="viewport"]');
    if (!vp){
      vp = document.createElement('meta');
      vp.setAttribute('name', 'viewport');
      head.appendChild(vp);
    }
    if (vp.getAttribute('content') !== WANT){
      vp.setAttribute('content', WANT);
    }
    var s = document.getElementById(ID);
    if (!s){ s = document.createElement('style'); s.id = ID; head.appendChild(s); }
    if (s.textContent !== CSS) s.textContent = CSS;
    if (head.lastElementChild !== s) head.appendChild(s);
  }
  apply();
  // Kill multi-touch gestures (pinch-zoom) at the event level — works
  // even on pages that override the viewport meta after we set it.
  document.addEventListener('gesturestart', function(e){ e.preventDefault(); }, { passive: false });
  document.addEventListener('gesturechange', function(e){ e.preventDefault(); }, { passive: false });
  document.addEventListener('gestureend', function(e){ e.preventDefault(); }, { passive: false });
  document.addEventListener('touchmove', function(e){
    if (e.touches && e.touches.length > 1) e.preventDefault();
  }, { passive: false });
  // Block double-tap zoom (iOS Safari quirk).
  var lastTap = 0;
  document.addEventListener('touchend', function(e){
    var now = Date.now();
    if (now - lastTap < 350){ e.preventDefault(); }
    lastTap = now;
  }, { passive: false });
  ['pushState','replaceState'].forEach(function(name){
    var orig = history[name];
    history[name] = function(){
      var r = orig.apply(this, arguments);
      setTimeout(apply,80); setTimeout(apply,400);
      return r;
    };
  });
  window.addEventListener('popstate', function(){ setTimeout(apply,80); });
  setInterval(apply, 2500);
})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _netSub?.cancel();
    widget.push.onRemoteTarget = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _lockOrientations();
    super.dispose();
  }

  Future<bool> _handleBack() async {
    // Dismiss fullscreen video first if active
    if (_fullscreenWidget != null) {
      _hideFullscreen?.call();
      return false;
    }

    if (await _wv.canGoBack()) {
      final current = await _wv.currentUrl();
      // Don't navigate back past the first real page we landed on
      if (current != null &&
          _firstFinalUrl != null &&
          current == _firstFinalUrl) {
        return false;
      }
      await _wv.goBack();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // viewPadding (not padding) keeps safe-area insets stable even when the
    // soft keyboard is visible. We pad the WebView on every side so the
    // notch, status bar, home indicator and landscape sensor housing never
    // overlap the page content.
    final safe = media.viewPadding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: safe.top,
                bottom: safe.bottom,
                left: safe.left,
                right: safe.right,
              ),
              child: WebViewWidget(controller: _wv),
            ),
            if (_spinning)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
            if (_fullscreenWidget != null)
              Positioned.fill(child: _fullscreenWidget!),
          ],
        ),
      ),
    );
  }
}
