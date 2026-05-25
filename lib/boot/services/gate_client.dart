import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_brand.dart';
import '../models/server_reply.dart';
import 'flow_cache.dart';
import 'safe_http.dart';

class GateClient {
  final FlowCache _cache;
  GateClient(this._cache);

  Future<ServerReply> dispatch(Map<String, dynamic> body) async {
    if (AppBrand.configUrl.isEmpty) return ServerReply.fail('no_endpoint');
    try {
      final uri = Uri.parse(AppBrand.configUrl);
      if (kDebugMode) debugPrint('[DB.GC] POST $uri');
      final resp = await safeHttp
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 18));
      if (kDebugMode) debugPrint('[DB.GC] ${resp.statusCode} ${resp.body.substring(0, resp.body.length.clamp(0, 300))}');
      if (resp.statusCode != 200) return ServerReply.fail('http_${resp.statusCode}');
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final reply = ServerReply.fromJson(json);
      if (reply.ok && reply.url != null) {
        await _cache.setSavedUrl(reply.url!);
        if (reply.expires != null) await _cache.setUrlExp(reply.expires!);
      }
      return reply;
    } catch (e) {
      if (kDebugMode) debugPrint('[DB.GC] error: $e');
      return ServerReply.fail(e.toString());
    }
  }
}
