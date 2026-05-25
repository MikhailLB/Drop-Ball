import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class SafeHttp extends http.BaseClient {
  final http.Client _inner = http.Client();
  String? _ua;

  Future<void> warmup() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        _ua = 'Mozilla/5.0 (Linux; Android ${a.version.sdkInt}; '
            '${a.brand} ${a.model} Build/${a.display.isNotEmpty ? a.display : a.id}) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/136.0.7103.93 Mobile Safari/537.36';
      } else {
        final i = await info.iosInfo;
        final ver = i.systemVersion.replaceAll('.', '_');
        _ua = 'Mozilla/5.0 (iPhone; CPU iPhone OS $ver like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) '
            'Version/${i.systemVersion} Mobile/15E148 Safari/605.1.15';
      }
    } catch (_) {
      _ua = 'Mozilla/5.0 (Linux; Android 14; Pixel 9) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/136.0.7103.93 Mobile Safari/537.36';
    }
  }

  String get userAgent => _ua ?? 'Mozilla/5.0';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) {
    req.headers.putIfAbsent('User-Agent', () => userAgent);
    return _inner.send(req);
  }

  @override
  void close() => _inner.close();
}

final safeHttp = SafeHttp();
