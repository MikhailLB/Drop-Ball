import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/server_response.dart';
import 'web_client.dart';
import 'app_storage.dart';

class RemoteConfig {
  final AppStorage _store;

  RemoteConfig(this._store);

  Future<ServerResponse> dispatch(Map<String, dynamic> body) async {
    final endpoint = AppConfig.configUrl;
    if (endpoint.isEmpty) {
      if (kDebugMode) debugPrint('[CFG] endpoint empty — refused');
      return ServerResponse.refused('endpoint_not_configured');
    }

    try {
      final uri = Uri.parse(endpoint);
      if (kDebugMode) debugPrint('[CFG] POST $uri');
      final response = await webClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        debugPrint('[CFG] status=${response.statusCode}');
        final preview = response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body;
        debugPrint('[CFG] body=$preview');
      }

      if (response.statusCode != 200) {
        return ServerResponse.refused('http_${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        if (kDebugMode) debugPrint('[CFG] response is not JSON object');
        return ServerResponse.refused('bad_json');
      }

      final payload = ServerResponse.fromJson(decoded);
      if (kDebugMode) {
        debugPrint(
          '[CFG] parsed accepted=${payload.accepted} target=${payload.target} note=${payload.note}',
        );
      }
      if (payload.accepted && payload.target != null) {
        await _store.writeCachedTarget(payload.target!);
        final ttl = payload.validUntil;
        if (ttl != null) {
          await _store.writeTargetExpire(ttl);
        }
      }
      return payload;
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[CFG] dispatch error: $err');
        debugPrint('$st');
      }
      return ServerResponse.refused(err.toString());
    }
  }

  Future<String?> loadTargetOrCached() async {
    return _store.readCachedTarget();
  }
}
