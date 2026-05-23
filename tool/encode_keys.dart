// ignore_for_file: avoid_print
import 'dart:typed_data';

// ════════════════════════════════════════════════════════════
// DropBall: Neon Edition — credential encoder
// ════════════════════════════════════════════════════════════
//
// HOW TO USE:
//   1. Fill in your real values in the constants below.
//   2. Run: dart run tool/encode_keys.dart
//      ⚠️  ALWAYS use `dart run` — NEVER PowerShell foreach loops.
//         PowerShell overflows 32-bit integers producing wrong bytes.
//   3. Paste the printed byte arrays into lib/flow/cfg/:
//        HOST + PATH → route_vault.dart
//        GCD         → route_vault.dart
//        AF_KEY      → signal_data.dart
//        FB_NUM      → signal_data.dart
//        PRIV + SUPP → page_links.dart
//
// SEED must match _seedBytes in lib/core/byte_mask.dart exactly.
// ════════════════════════════════════════════════════════════

const _seedBytes = <int>[
  0x64, 0x72, 0x6F, 0x70, 0x62, 0x61, 0x6C, 0x6C,
  0x2E, 0x6E, 0x65, 0x6F, 0x6E, 0x2E, 0x76, 0x31,
]; // "dropball.neon.v1"

Uint8List _buildStream(int size) {
  var hash = 0x811C9DC5;
  for (final b in _seedBytes) {
    hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  final out = Uint8List(size);
  var state = hash == 0 ? 0xDEADBEEF : hash;
  for (var i = 0; i < size; i++) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    out[i] = (state >> 7) & 0xFF;
  }
  return out;
}

final _ks = _buildStream(64);

List<int> enc(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    out.add(s.codeUnitAt(i) ^ _ks[i % _ks.length]);
  }
  return out;
}

String fmt(List<int> v) => '[${v.join(', ')}]';

void main() {
  // ── TODO: Fill your real values below ────────────────────
  const configHost  = 'TODO_CONFIG_HOST';   // e.g. https://example.com
  const configPath  = 'TODO_CONFIG_PATH';   // e.g. /config.php
  const gcdHost     = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';
  const afKey       = 'TODO_APPSFLYER_KEY';
  const fbNumber    = 'TODO_FIREBASE_PROJECT_NUMBER';
  const privacyUrl  = 'https://dropballneonedition.com/privacy-policy.html';
  const supportUrl  = 'https://dropballneonedition.com/support.html';
  // ─────────────────────────────────────────────────────────

  print('// route_vault.dart');
  print('HOST : ${fmt(enc(configHost))}');
  print('PATH : ${fmt(enc(configPath))}');
  print('GCD  : ${fmt(enc(gcdHost))}');
  print('');
  print('// signal_data.dart');
  print('AF_KEY  : ${fmt(enc(afKey))}');
  print('FB_NUM  : ${fmt(enc(fbNumber))}');
  print('');
  print('// page_links.dart');
  print('PRIV : ${fmt(enc(privacyUrl))}');
  print('SUPP : ${fmt(enc(supportUrl))}');
}
