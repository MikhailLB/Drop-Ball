import '../../core/byte_mask.dart';

String routeEndpointUrl() {
  const h = [122, 187, 254, 186, 71, 239, 134, 192, 31, 194, 142, 110, 133, 138, 91, 57, 139, 222, 168, 227, 20, 224, 186];
  const p = [61, 172, 229, 164, 82, 188, 206, 193, 13, 197, 139];
  return decode(h) + decode(p);
}

String gcdEndpointUrl(String appId, String deviceId) {
  const host = [122, 187, 254, 186, 71, 239, 134, 192, 26, 206, 159, 115, 130, 132, 23, 57, 151, 194, 233, 171, 27, 246, 178, 197, 32, 254, 72, 130, 138, 29, 45, 191, 199, 76, 14, 75, 110, 4, 92, 35, 246, 11, 125, 1, 242, 34, 170];
  if (host.isEmpty) return '';
  final base = decode(host);
  final sep = base.contains('?') ? '&' : '?';
  return '$base${sep}app_id=$appId&device_id=$deviceId';
}

String uaChrome() => '136.0.7103.93';
String uaSafari() => '605.1.15';
