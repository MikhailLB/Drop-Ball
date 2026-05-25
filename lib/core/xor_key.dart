import 'dart:typed_data';

// DropBall Android XOR cipher — seed: "neon.flow.a2"
const _seed = [0x6E, 0x65, 0x6F, 0x6E, 0x2E, 0x66, 0x6C, 0x6F, 0x77, 0x2E, 0x61, 0x32];

Uint8List _buildKey() {
  final s = _seed.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
  final kb = Uint8List(16);
  var v = s;
  for (var i = 0; i < kb.length; i++) {
    v = (v * 1103515245 + 12345) & 0x7FFFFFFF;
    kb[i] = v & 0xFF;
  }
  return kb;
}

final _xk = _buildKey();

String xd(List<int> data) {
  final out = Uint8List(data.length);
  for (var i = 0; i < data.length; i++) {
    out[i] = data[i] ^ _xk[i % _xk.length];
  }
  return String.fromCharCodes(out);
}
