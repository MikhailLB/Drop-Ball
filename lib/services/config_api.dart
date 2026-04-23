import 'dart:convert';
import '../config/brand_config.dart';
import '../models/config_payload.dart';
import 'browser_http.dart';
import 'local_store.dart';

class ConfigApi {
  final LocalStore _store;

  ConfigApi(this._store);

  Future<ConfigPayload> dispatch(Map<String, dynamic> body) async {
    final endpoint = BrandConfig.configUrl;
    if (endpoint.isEmpty) {
      return ConfigPayload.refused('endpoint_not_configured');
    }

    try {
      final uri = Uri.parse(endpoint);
      final response = await browserHttp
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ConfigPayload.refused('http_${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return ConfigPayload.refused('bad_json');
      }

      final payload = ConfigPayload.fromJson(decoded);
      if (payload.accepted && payload.target != null) {
        await _store.writeCachedTarget(payload.target!);
        final ttl = payload.validUntil;
        if (ttl != null) {
          await _store.writeTargetExpire(ttl);
        }
      }
      return payload;
    } catch (err) {
      return ConfigPayload.refused(err.toString());
    }
  }

  Future<String?> loadTargetOrCached() async {
    return _store.readCachedTarget();
  }
}
