import 'dart:typed_data';

const _saltBytes = [
  0x67, 0x72, 0x61, 0x76, 0x69, 0x74, 0x79, 0x72, 0x75, 0x73,
  0x68, 0x2E, 0x62, 0x72, 0x61, 0x6E, 0x64,
];

Uint8List _buildKeyStream([int size = 20]) {
  var hash = 2166136261;
  for (final b in _saltBytes) {
    hash = ((hash ^ b) * 16777619) & 0xFFFFFFFF;
  }

  final out = Uint8List(size);
  var state = hash;
  for (var i = 0; i < size; i++) {
    state = (state * 214013 + 2531011) & 0x7FFFFFFF;
    out[i] = (state >> 8) & 0xFF;
  }
  return out;
}

final _keyStream = _buildKeyStream();

String decode(List<int> bytes) {
  final n = bytes.length;
  final k = _keyStream;
  final kn = k.length;
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = bytes[i] ^ k[i % kn];
  }
  return String.fromCharCodes(out);
}
