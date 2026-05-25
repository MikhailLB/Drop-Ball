import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import '../config/app_brand.dart';
import '../config/api_endpoints.dart';
import 'safe_http.dart';

class AttributeClient {
  AppsflyerSdk? _sdk;
  Map<String, dynamic>? _attrData;
  Map<String, dynamic>? _deepLink;
  Map<String, dynamic>? _reopenData;
  final Completer<Map<String, dynamic>> _attrDone = Completer();
  final Completer<void> _dlDone = Completer();
  bool _ready = false;

  bool _looksLikeAttr(Map<String, dynamic> p) =>
      p.containsKey('af_status') || p.containsKey('media_source') ||
      p.containsKey('campaign') || p.containsKey('is_first_launch');

  Future<void> warmup() async {
    if (_ready) return;
    _ready = true;
    final opts = AppsFlyerOptions(
      afDevKey: AppBrand.installKey,
      appId: AppBrand.analyticsId,
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 10,
    );
    _sdk = AppsflyerSdk(opts);
    _sdk!.onInstallConversionData((raw) async {
      final data = raw['payload'] != null
          ? Map<String, dynamic>.from(raw['payload'] as Map)
          : Map<String, dynamic>.from(raw);
      if (!_looksLikeAttr(data)) { _attrData = {}; _attrDone.complete({}); return; }
      if (data['af_status'] == 'Organic') {
        await Future.delayed(Duration(seconds: AppBrand.gcdRetrySecs));
        final retry = await _fetchGcd();
        _attrData = retry ?? data;
      } else {
        _attrData = data;
      }
      if (!_attrDone.isCompleted) _attrDone.complete(_attrData);
    });
    _sdk!.onAppOpenAttribution((raw) {
      _reopenData = raw['payload'] != null
          ? Map<String, dynamic>.from(raw['payload'] as Map)
          : Map<String, dynamic>.from(raw);
    });
    _sdk!.onDeepLinking((r) {
      if (r.deepLink != null) {
        final ev = Map<String, dynamic>.from(r.deepLink!.clickEvent);
        final dlv = r.deepLink!.deepLinkValue;
        if (dlv != null && dlv.isNotEmpty) ev['deep_link_value'] = dlv;
        _deepLink = ev;
      }
      if (!_dlDone.isCompleted) _dlDone.complete();
    });
    await _sdk!.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
  }

  Future<Map<String, dynamic>?> _fetchGcd() async {
    try {
      final uid = await getUid();
      if (uid == null) return null;
      final uri = Uri.parse('${ApiEndpoints.gcdBase}${AppBrand.packageName}?device_id=$uid');
      final resp = await safeHttp.get(uri,
          headers: {'authorization': 'Bearer ${AppBrand.installKey}'})
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> waitForAttr() =>
      _attrDone.future.timeout(const Duration(seconds: 10), onTimeout: () => {});
  Future<void> waitForDl() =>
      _dlDone.future.timeout(const Duration(seconds: 3), onTimeout: () {});

  Future<String?> getUid() async {
    try { return await _sdk?.getAppsFlyerUID(); } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> buildPayload({
    required String locale,
    String? pushToken,
  }) async {
    final body = <String, dynamic>{};
    if (_attrData != null) body.addAll(_attrData!);
    if (_deepLink != null) _deepLink!.forEach((k, v) => body.putIfAbsent(k, () => v));
    if (_reopenData != null) _reopenData!.forEach((k, v) => body.putIfAbsent(k, () => v));
    body['af_id']     = (await getUid()) ?? '';
    body['bundle_id'] = AppBrand.packageName;
    body['os']        = Platform.isAndroid ? 'Android' : 'iOS';
    body['store_id']  = AppBrand.storeId;
    body['locale']    = locale;
    if (pushToken?.isNotEmpty == true) body['push_token'] = pushToken!;
    if (AppBrand.firebaseProject.isNotEmpty) body['firebase_project_id'] = AppBrand.firebaseProject;
    return body;
  }
}
