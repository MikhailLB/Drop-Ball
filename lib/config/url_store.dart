import '../utils/cipher.dart';

String brandEndpoint() {
  const a = [
    114, 110, 195, 124, 251, 155, 157, 69, 25, 253,
    25, 28, 249, 92, 72, 23, 225, 132, 1, 116,
    52, 121, 216, 97,
  ];
  const b = [53, 121, 216, 98, 238, 200, 213, 68, 14, 231, 8];
  return decode(a) + decode(b);
}

/// AppsFlyer GCD (Get Conversion Data) public endpoint.
String gcdEndpoint(String appId, String deviceId, {required String devKey}) {
  return 'https://gcd.appsflyer.com/install_data/v4.0/$appId'
      '?devkey=$devKey&device_id=$deviceId';
}

String browserChromeVersion() =>
    decode(const [43, 41, 129, 34, 184, 143, 133, 91, 78, 188, 86, 92, 160]);

String browserSafariVersion() =>
    decode(const [44, 42, 130, 34, 185, 143, 131, 95]);

const String brandPrivacyUrl = 'https://gravittyrush.com/privacy-policy.html';
const String brandSupportUrl = 'https://gravittyrush.com/support.html';
