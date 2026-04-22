import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../utils/codec.dart';

String get _fallbackCv => d(const [86, 39, 139, 156, 51, 174, 142, 207, 111, 159, 91, 60, 75]);
String get _sv => d(const [81, 36, 136, 156, 50, 174, 136, 203]);

class AppHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  String? _userAgent;

  Future<void> init() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        final sdk = a.version.sdkInt;
        final model = a.model;
        final brand = a.brand;
        final build = a.display.isNotEmpty ? a.display : a.id;
        _userAgent = 'Mozilla/5.0 (Linux; Android $sdk; $brand $model '
            'Build/$build) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/$_fallbackCv Mobile Safari/537.36';
      } else {
        final i = await info.iosInfo;
        final ver = i.systemVersion.replaceAll('.', '_');
        _userAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS $ver like Mac OS X) '
            'AppleWebKit/$_sv (KHTML, like Gecko) '
            'Version/${i.systemVersion} Mobile/15E148 Safari/$_sv';
      }
    } catch (_) {
      _userAgent = Platform.isAndroid
          ? 'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/$_fallbackCv Mobile Safari/537.36'
          : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
              'AppleWebKit/$_sv (KHTML, like Gecko) '
              'Version/17.0 Mobile/15E148 Safari/$_sv';
    }
  }

  String get userAgent => _userAgent ?? 'Mozilla/5.0';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => userAgent);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final appHttpClient = AppHttpClient();
