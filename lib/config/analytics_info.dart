import '../utils/codec.dart';

String resolveAnalyticsKey() {
  return '';
}

String resolveMessagingProject() {
  return '';
}

String resolveGcdEndpoint(String appId, String deviceId) {
  const host = [15, 96, 201, 194, 112, 186, 150, 209, 56, 207, 17, 36, 26, 232, 129, 165, 1, 120, 196, 215, 113, 174, 218, 145, 50];
  const path = [72, 125, 211, 193, 119, 225, 213, 146, 0, 200, 20, 126, 26, 183, 135, 226, 73, 36, 146];
  return '${d(host)}${d(path)}?app_id=$appId&device_id=$deviceId';
}
