import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../config/app_config.dart';
import '../config/url_store.dart';
import 'web_client.dart';

class Tracker {
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

    await _requestTrackingAuthorization();

    final opts = AppsFlyerOptions(
      afDevKey: AppConfig.attributionDevKey,
      appId: AppConfig.iosAppId,
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
      if (kDebugMode) {
        debugPrint(
          '[AG] Organic verdict — scheduling GCD re-query in '
          '${AppConfig.refreshDelaySeconds}s',
        );
      }
      await Future.delayed(
        Duration(seconds: AppConfig.refreshDelaySeconds),
      );
      final fresh = await _fetchGcd();
      if (fresh != null) {
        if (kDebugMode) {
          debugPrint(
            '[AG] GCD re-query result af_status=${fresh['af_status']}',
          );
        }
        _conversion = fresh;
      } else {
        if (kDebugMode) {
          debugPrint('[AG] GCD re-query returned nothing — keep original');
        }
        _conversion = data;
      }
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
      if (uid == null || uid.isEmpty) {
        if (kDebugMode) debugPrint('[AG] GCD retry skipped: empty AF UID');
        return null;
      }

      final appId = Platform.isIOS
          ? AppConfig.storeIdentifier
          : AppConfig.packageName;
      final uri = Uri.parse(
        gcdEndpoint(appId, uid, devKey: AppConfig.attributionDevKey),
      );

      if (kDebugMode) {
        debugPrint(
          '[AG] GCD retry GET https://gcd.appsflyer.com/install_data/v4.0/'
          '$appId?devkey=***&device_id=$uid',
        );
      }

      final response = await webClient
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('[AG] GCD retry status=${response.statusCode}');
        debugPrint('[AG] GCD retry body=${response.body}');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (err) {
      if (kDebugMode) debugPrint('[AG] GCD retry failed: $err');
    }
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

  bool get hasNonOrganicSignal {
    final status = (_conversion?['af_status'] as String?)?.toLowerCase();
    if (status == 'non-organic') return true;
    if (_deepLink != null && _deepLink!.isNotEmpty) return true;
    if (_reopen != null && _reopen!.isNotEmpty) {
      final reStatus = (_reopen!['af_status'] as String?)?.toLowerCase();
      if (reStatus == 'non-organic') return true;
    }
    return false;
  }

  bool get hasOrganicSignal {
    final status = (_conversion?['af_status'] as String?)?.toLowerCase();
    return status == 'organic';
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
    if (_reopen != null) {
      _reopen!.forEach((k, v) => out.putIfAbsent(k, () => v));
    }
    if (_deepLink != null) {
      out.addAll(_deepLink!);
    }

    final uid = await identifier();
    if (uid != null && uid.isNotEmpty) {
      out['af_id'] = uid;
    } else if ((out['af_id'] as String? ?? '').isEmpty) {
      out['af_id'] = '';
    }

    out['bundle_id'] = AppConfig.packageName;
    out['store_id'] = AppConfig.storeIdentifier;
    out['os'] = Platform.isAndroid ? 'Android' : 'iOS';
    out['locale'] = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      out['push_token'] = pushToken;
    }
    if (AppConfig.cloudProjectId.isNotEmpty) {
      out['firebase_project_id'] = AppConfig.cloudProjectId;
    }

    if (kDebugMode) {
      debugPrint('[AG] request body: ${jsonEncode(out)}');
    }
    return out;
  }
}
