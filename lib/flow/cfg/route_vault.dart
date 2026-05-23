import '../../core/byte_mask.dart';

// ════════════════════════════════════════════════════════════
// ⚠️  PLACEHOLDER — run tool/encode_keys.dart after credentials
//     are provided to generate real byte arrays.
// ════════════════════════════════════════════════════════════

/// Config endpoint URL — host + path concatenated.
/// Returns empty string when not yet configured (gate disabled).
String routeEndpointUrl() {
  const h = <int>[]; // TODO: encode config host
  const p = <int>[]; // TODO: encode config path
  if (h.isEmpty) return '';
  return decode(h) + decode(p);
}

/// GCD (Get Conversion Data) URL builder.
/// Returns empty string when not configured.
String gcdEndpointUrl(String appId, String deviceId) {
  const host = <int>[]; // TODO: encode GCD host
  if (host.isEmpty) return '';
  final base = decode(host);
  final sep = base.contains('?') ? '&' : '?';
  return '$base${sep}app_id=$appId&device_id=$deviceId';
}

String uaChrome() => '136.0.7103.93';
String uaSafari() => '605.1.15';
