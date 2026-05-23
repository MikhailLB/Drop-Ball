import 'dart:typed_data';

// Cipher seed unique to DropBall: Neon Edition.
// Must NOT match any sibling project — byte arrays are not interchangeable.
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

/// Decode an XOR-encoded byte list back to its plaintext string.
/// Use tool/encode_keys.dart to produce byte arrays for new values.
String decode(List<int> raw) {
  if (raw.isEmpty) return '';
  final sn = _ks.length;
  final out = Uint8List(raw.length);
  for (var i = 0; i < raw.length; i++) {
    out[i] = raw[i] ^ _ks[i % sn];
  }
  return String.fromCharCodes(out);
}
