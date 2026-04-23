import 'endpoint_registry.dart';

abstract final class BrandConfig {
  static const packageName = 'com.gsteamgsgames.gravityrush';
  static const storeIdentifier = 'com.gsteamgsgames.gravityrush';
  static const displayTitle = 'Gravity Rush';
  static const iosAppId = '';
  static const attributionDevKey = '';
  static const cloudProjectId = '';

  static const cooldownSeconds = 259200;
  static const refreshDelaySeconds = 5;

  static String get configUrl => brandEndpoint();
  static String get chromeVersion => browserChromeVersion();
  static String get safariVersion => browserSafariVersion();
  static String get privacyUrl => brandPrivacyUrl;
  static String get supportUrl => brandSupportUrl;
}
