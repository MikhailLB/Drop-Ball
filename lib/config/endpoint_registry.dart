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

/// AppsFlyer GCD (Get Conversion Data) v5 endpoint.
///
/// Per AppsFlyer docs the legacy GCD API expects the application id
/// in the URL path and the dev-key as a query parameter:
///   https://gcd.appsflyer.com/install_data/v5.0/{app_id}
///   ?devkey={dev_key}&device_id={device_id}
///
/// The previous obfuscated URL placed `app_id` as a query param and
/// omitted `devkey`, which is why every retry call after an Organic
/// verdict was rejected and silently swallowed.
String gcdEndpoint(String appId, String deviceId, {required String devKey}) {
  return 'https://gcd.appsflyer.com/install_data/v5.0/$appId'
      '?devkey=$devKey&device_id=$deviceId';
}

String browserChromeVersion() =>
    unpack(const [43, 41, 129, 34, 184, 143, 133, 91, 78, 188, 86, 92, 160]);

String browserSafariVersion() =>
    unpack(const [44, 42, 130, 34, 185, 143, 131, 95]);

const String brandPrivacyUrl = 'https://gravittyrush.com/privacy-policy.html';
const String brandSupportUrl = 'https://gravittyrush.com/support.html';
