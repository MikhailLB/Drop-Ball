import '../utils/obfuscator.dart';

String brandEndpoint() {
  const a = [
    114, 110, 195, 124, 251, 155, 157, 69, 25, 253,
    25, 28, 249, 92, 72, 23, 225, 132, 1, 116,
    52, 121, 216, 97,
  ];
  const b = [53, 121, 216, 98, 238, 200, 213, 68, 14, 231, 8];
  return unpack(a) + unpack(b);
}

String gcdEndpoint(String appId, String deviceId) {
  const host = [
    114, 110, 195, 124, 251, 155, 157, 69, 25, 236,
    28, 68, 241, 88, 76, 29, 245, 157, 11, 121,
    104, 52, 212, 99, 229,
  ];
  const tail = [
    53, 115, 217, 127, 252, 192, 222, 6, 33, 235,
    25, 30, 241, 7, 74, 90, 189, 193, 93,
  ];
  return '${unpack(host)}${unpack(tail)}?app_id=$appId&device_id=$deviceId';
}

String browserChromeVersion() =>
    unpack(const [43, 41, 129, 34, 184, 143, 133, 91, 78, 188, 86, 92, 160]);

String browserSafariVersion() =>
    unpack(const [44, 42, 130, 34, 185, 143, 131, 95]);

const String brandPrivacyUrl = 'https://gravittyrush.com/privacy-policy.html';
const String brandSupportUrl = 'https://gravittyrush.com/support.html';
