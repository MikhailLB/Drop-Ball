import 'dart:io';
import '../utils/obfuscator.dart';
import 'endpoint_registry.dart';

// Android AppsFlyer dev key
const _attributionDevKeyAndroid = [
  95, 125, 217, 105, 226, 233, 250, 51, 14, 201,
  22, 33, 250, 106, 10, 93, 248, 182, 17, 87,
  86, 89,
];

// iOS AppsFlyer dev key
const _attributionDevKeyIos = [
  74, 110, 221, 100, 207, 212, 200, 95, 20, 184,
  61, 95, 227, 112, 116, 41, 221, 135, 23, 122,
  106, 116,
];

// Android Firebase project number: 585000410227
const _cloudProjectIdAndroid = [
  47, 34, 130, 60, 184, 145, 134, 91, 78, 189, 74, 93,
];

// iOS Firebase project number: 525746744899
const _cloudProjectIdIos = [
  47, 40, 130, 59, 188, 151, 133, 94, 74, 183, 65, 83,
];

abstract final class BrandConfig {
  static const packageName = 'com.gsteamgsgames.gravityrush';
  static const storeIdentifier = 'com.gsteamgsgames.gravityrush';
  static const displayTitle = 'Gravity Rush';
  static const iosAppId = '6763416861';

  static const cooldownSeconds = 259200;
  static const refreshDelaySeconds = 5;

  static String get attributionDevKey => Platform.isIOS
      ? unpack(_attributionDevKeyIos)
      : unpack(_attributionDevKeyAndroid);

  static String get cloudProjectId => Platform.isIOS
      ? unpack(_cloudProjectIdIos)
      : unpack(_cloudProjectIdAndroid);

  static String get configUrl => brandEndpoint();
  static String get chromeVersion => browserChromeVersion();
  static String get safariVersion => browserSafariVersion();
  static String get privacyUrl => brandPrivacyUrl;
  static String get supportUrl => brandSupportUrl;
}
