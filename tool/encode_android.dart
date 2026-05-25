// ignore_for_file: avoid_print
import 'dart:typed_data';

// DropBall Android cipher seed — different from iOS seed
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

List<int> enc(String s) {
  final k = _buildKey();
  return [for (var i = 0; i < s.length; i++) s.codeUnitAt(i) ^ k[i % k.length]];
}

String fmt(List<int> v) => '[${v.join(', ')}]';

void main() {
  const afKey      = '8YunFuEaAPpvPTd8QZeJbj';
  const fbProject  = '713976457990';
  const gateHost   = 'https://droppball.com';
  const gatePath   = '/config.php';
  const gcdBase    = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';
  // const gcdPath = '/install_data/v4.0/'; // included in gcdBase
  const privacyUrl = 'https://droppball.com/privacy-policy.html';
  const supportUrl = 'https://droppball.com/support.html';

  print('AF_KEY   : ${fmt(enc(afKey))}');
  print('FB_PROJ  : ${fmt(enc(fbProject))}');
  print('GATE_HOST: ${fmt(enc(gateHost))}');
  print('GATE_PATH: ${fmt(enc(gatePath))}');
  print('GCD_BASE : ${fmt(enc(gcdBase))}');
  print('PRIVACY  : ${fmt(enc(privacyUrl))}');
  print('SUPPORT  : ${fmt(enc(supportUrl))}');
}
