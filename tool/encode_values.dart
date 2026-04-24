// ignore_for_file: avoid_print
import 'dart:typed_data';

// Mirror of lib/utils/obfuscator.dart so we can produce encoded byte arrays.
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

List<int> pack(String value) {
  final n = value.length;
  final k = _keyStream;
  final kn = k.length;
  final out = <int>[];
  for (var i = 0; i < n; i++) {
    out.add(value.codeUnitAt(i) ^ k[i % kn]);
  }
  return out;
}

String unpack(List<int> bytes) {
  final n = bytes.length;
  final k = _keyStream;
  final kn = k.length;
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = bytes[i] ^ k[i % kn];
  }
  return String.fromCharCodes(out);
}

void dump(String name, String value) {
  final bytes = pack(value);
  final round = unpack(bytes);
  if (round != value) {
    throw StateError('Round-trip failed for $name: "$value" -> "$round"');
  }
  final lines = <String>[];
  for (var i = 0; i < bytes.length; i += 10) {
    final end = (i + 10 < bytes.length) ? i + 10 : bytes.length;
    lines.add(bytes.sublist(i, end).join(', '));
  }
  print('// $name = "$value"');
  print('const _$name = [');
  for (final line in lines) {
    print('  $line,');
  }
  print('];');
  print('');
}

void main() {
  dump('attributionDevKey', 'EgnejHHYpFnKjB63kGcKLC');
  dump('cloudProjectId', 'gravityrush-3216d');
  dump('firebaseApiKey', 'AIzaSyC9t58hxloDiT4TK_vxdGiGI57J1GqwbtY');
  dump('firebaseAppId', '1:585000410227:android:493416808c8508cc4c9e06');
  dump('firebaseSenderId', '585000410227');
  dump('firebaseStorageBucket', 'gravityrush-3216d.firebasestorage.app');
}
