import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../cfg/flow_config.dart';
import '../models/server_reply.dart';
import 'http_shield.dart';
import 'data_vault.dart';

/// POSTs the install/launch payload to the remote config endpoint and
/// caches the returned destination URL. Returns [ServerReply.declined]
/// when the endpoint is not configured.
class RouteDispatch {
  final DataVault _vault;

  RouteDispatch(this._vault);

  Future<ServerReply> send(Map<String, dynamic> body) async {
    final endpoint = FlowConfig.configEndpoint;
    debugPrint('[DB.RD] send endpoint="$endpoint"');
    if (endpoint.isEmpty) {
      debugPrint('[DB.RD] endpoint not configured — declined');
      return ServerReply.declined('endpoint_missing');
    }
    try {
      final uri = Uri.parse(endpoint);
      debugPrint('[DB.RD] POST $uri  body=${jsonEncode(body)}');
      final resp = await httpShield
          .post(uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      debugPrint('[DB.RD] HTTP ${resp.statusCode}');
      final preview = resp.body.length > 500
          ? '${resp.body.substring(0, 500)}…'
          : resp.body;
      debugPrint('[DB.RD] body=$preview');

      if (resp.statusCode != 200) {
        return ServerReply.declined('http_${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return ServerReply.declined('bad_json');
      }
      final reply = ServerReply.fromMap(decoded);
      debugPrint('[DB.RD] reply granted=${reply.granted} dest=${reply.destination}');
      if (reply.granted && reply.destination != null) {
        await _vault.writeSavedUrl(reply.destination!);
        if (reply.expiresAt != null) {
          await _vault.writeSavedTtl(reply.expiresAt!);
        }
      }
      return reply;
    } catch (err, st) {
      debugPrint('[DB.RD] error: $err\n$st');
      return ServerReply.declined(err.toString());
    }
  }
}
