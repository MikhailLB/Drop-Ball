import '../../core/xor_key.dart';
import 'api_endpoints.dart';

const _afKeyMask    = [102, 102, 121, 59, 44, 46, 189, 176, 119, 103, 212, 123, 146, 135, 116, 49, 15, 101, 105, 31, 8, 49];
const _fbProjMask   = [105, 14, 63, 108, 93, 109, 204, 228, 1, 14, 157, 61];

class AppBrand {
  static const String packageName  = 'com.neonfall.dropball';
  static const String displayTitle = 'DropBall';
  static const int    notifCooldownSecs = 259200;
  static const int    gcdRetrySecs      = 2;

  static String get installKey    => xd(_afKeyMask);
  static String get firebaseProject => xd(_fbProjMask);
  static String get analyticsId   => packageName;
  static String get storeId       => packageName;
  static String get configUrl     => ApiEndpoints.configUrl;
  static String get privacyUrl    => ApiEndpoints.privacyUrl;
  static String get supportUrl    => ApiEndpoints.supportUrl;
  static bool   get gateEnabled   => installKey.isNotEmpty && configUrl.isNotEmpty;
}
