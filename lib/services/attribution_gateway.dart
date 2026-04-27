import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../config/brand_config.dart';
import '../config/endpoint_registry.dart';
import 'browser_http.dart';

class AttributionGateway {
  AppsflyerSdk? _provider;
  Map<String, dynamic>? _conversion;
  Map<String, dynamic>? _deepLink;
  Map<String, dynamic>? _reopen;
  final Completer<Map<String, dynamic>> _conversionReady = Completer();
  final Completer<void> _deepLinkReady = Completer();
  bool _started = false;

  Future<void> warmup() async {
    if (_started) return;
    _started = true;

    // iOS 14.5+ requires explicit ATT before any tracking SDK can read IDFA.
    // AppsFlyer waits for the decision (timeToWaitForATTUserAuthorization),
    // but the prompt itself has to be triggered by the host app.
    await _requestTrackingAuthorization();

    final opts = AppsFlyerOptions(
      afDevKey: BrandConfig.attributionDevKey,
      appId: BrandConfig.iosAppId,
      showDebug: false,
      timeToWaitForATTUserAuthorization: 10,
    );
    _provider = AppsflyerSdk(opts);

    _provider!.onInstallConversionData(_onConversion);
    _provider!.onAppOpenAttribution(_onReopen);
    _provider!.onDeepLinking(_onDeepLink);

    await _provider!.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    if (kDebugMode) {
      await _dumpTrackingDebugInfo();
    }
  }

  Future<void> _requestTrackingAuthorization() async {
    if (!Platform.isIOS) return;
    try {
      final current =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (kDebugMode) {
        debugPrint('[AG] ATT current status: $current');
      }
      if (current != TrackingStatus.notDetermined) return;

      // iOS only shows the ATT prompt when the app is in
      // UIApplicationStateActive. Calling it from initState() is too
      // early — the app is still inactive and the system silently
      // drops the prompt. Wait for the first frame, then add a small
      // breathing delay so we are guaranteed to be active.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final granted =
          await AppTrackingTransparency.requestTrackingAuthorization();
      if (kDebugMode) {
        debugPrint('[AG] ATT user decision: $granted');
      }
    } catch (err) {
      if (kDebugMode) {
        debugPrint('[AG] ATT request failed: $err');
      }
    }
  }

  /// Debug helper: print tracking status, IDFA and AppsFlyer UID so the
  /// device can be registered as an AppsFlyer Test Device and tracking
  /// links can be built with `&advertising_id=<IDFA>`.
  Future<void> _dumpTrackingDebugInfo() async {
    try {
      if (Platform.isIOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        debugPrint('[AG] tracking status (post-init): $status');
        final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
        debugPrint('[AG] IDFA: $idfa');
      }
      final uid = await _provider?.getAppsFlyerUID();
      debugPrint('[AG] AppsFlyer UID: $uid');
    } catch (err) {
      debugPrint('[AG] debug dump failed: $err');
    }
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    final inner = map['payload'];
    if (inner is Map) {
      return Map<String, dynamic>.from(inner);
    }
    return map;
  }

  void _onConversion(dynamic raw) async {
    final data = _unwrap(raw);

    if (kDebugMode) {
      debugPrint('[AG] conversion ${jsonEncode(data)}');
    }

    if (data['af_status'] == 'Organic') {
      await Future.delayed(
        Duration(seconds: BrandConfig.refreshDelaySeconds),
      );
      final fresh = await _fetchGcd();
      _conversion = fresh ?? data;
    } else {
      _conversion = data;
    }

    if (!_conversionReady.isCompleted) {
      _conversionReady.complete(_conversion);
    }
  }

  void _onReopen(dynamic raw) {
    _reopen = _unwrap(raw);
    if (kDebugMode) {
      debugPrint('[AG] reopen ${jsonEncode(_reopen)}');
    }
  }

  void _onDeepLink(DeepLinkResult result) {
    if (kDebugMode) {
      debugPrint(
        '[AG] deepLink status=${result.status}, link=${result.deepLink}',
      );
    }
    if (result.deepLink != null) {
      _deepLink = result.deepLink!.clickEvent;
    }
    if (!_deepLinkReady.isCompleted) {
      _deepLinkReady.complete();
    }
  }

  Future<Map<String, dynamic>?> _fetchGcd() async {
    try {
      final uid = await identifier();
      if (uid == null) return null;

      final appId = Platform.isIOS
          ? BrandConfig.iosAppId
          : BrandConfig.packageName;
      final uri = Uri.parse(gcdEndpoint(appId, uid));
      final response = await browserHttp.get(uri, headers: {
        'authorization': 'Bearer ${BrandConfig.attributionDevKey}',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> awaitConversion({
    Duration timeout = const Duration(seconds: 30),
  }) {
    return _conversionReady.future.timeout(
      timeout,
      onTimeout: () => <String, dynamic>{},
    );
  }

  Future<void> awaitDeepLink({
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _deepLinkReady.future
        .timeout(timeout, onTimeout: () {});
  }

  Future<String?> identifier() async {
    if (_provider == null) return null;
    try {
      return await _provider!.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> assembleRequest({
    required String locale,
    String? pushToken,
  }) async {
    final out = <String, dynamic>{};

    if (_conversion != null) out.addAll(_conversion!);
    if (_deepLink != null) {
      _deepLink!.forEach((k, v) => out.putIfAbsent(k, () => v));
    }
    if (_reopen != null) {
      _reopen!.forEach((k, v) => out.putIfAbsent(k, () => v));
    }

    final uid = await identifier();
    if (uid != null && uid.isNotEmpty) {
      out['af_id'] = uid;
    } else if ((out['af_id'] as String? ?? '').isEmpty) {
      out['af_id'] = '';
    }

    out['bundle_id'] = BrandConfig.packageName;
    out['store_id'] = BrandConfig.storeIdentifier;
    out['os'] = Platform.isAndroid ? 'Android' : 'iOS';
    out['locale'] = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      out['push_token'] = pushToken;
    }
    if (BrandConfig.cloudProjectId.isNotEmpty) {
      out['firebase_project_id'] = BrandConfig.cloudProjectId;
    }

    if (kDebugMode) {
      debugPrint('[AG] request body: ${jsonEncode(out)}');
    }
    return out;
  }
}
