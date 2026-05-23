import '../../core/byte_mask.dart';

// ════════════════════════════════════════════════════════════
// ⚠️  PLACEHOLDER — run tool/encode_keys.dart after credentials
//     are provided to generate real byte arrays.
// ════════════════════════════════════════════════════════════

/// AppsFlyer Dev Key — empty until encoded.
String appsflyerKey() {
  const v = <int>[]; // TODO: encode AppsFlyer dev key
  return v.isEmpty ? '' : decode(v);
}

/// Firebase Project Number — empty until encoded.
String firebaseProjectNum() {
  const v = <int>[]; // TODO: encode Firebase project number
  return v.isEmpty ? '' : decode(v);
}
