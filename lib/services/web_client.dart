import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

String _composeAndroidUa(
  int sdk,
  String brand,
  String model,
  String build,
) {
  final chrome = AppConfig.chromeVersion;
  return 'Mozilla/5.0 (Linux; Android $sdk; $brand $model Build/$build) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/$chrome Mobile Safari/537.36';
}

String _composeIosUa(String systemVersion) {
  final safari = AppConfig.safariVersion;
  final dotless = systemVersion.replaceAll('.', '_');
  return 'Mozilla/5.0 (iPhone; CPU iPhone OS $dotless like Mac OS X) '
      'AppleWebKit/$safari (KHTML, like Gecko) '
      'Version/$systemVersion Mobile/15E148 Safari/$safari';
}

String _fallbackUa() {
  if (Platform.isAndroid) {
    return _composeAndroidUa(14, 'Google', 'Pixel 8', 'UD1A.230803.041');
  }
  return _composeIosUa('17.0');
}

class WebClient extends http.BaseClient {
  final http.Client _delegate = http.Client();
  String _ua = '';

  Future<void> bootstrap() async {
    try {
      final probe = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await probe.androidInfo;
        final buildTag =
            info.display.isNotEmpty ? info.display : info.id;
        _ua = _composeAndroidUa(
          info.version.sdkInt,
          info.brand,
          info.model,
          buildTag,
        );
      } else if (Platform.isIOS) {
        final info = await probe.iosInfo;
        _ua = _composeIosUa(info.systemVersion);
      } else {
        _ua = _fallbackUa();
      }
    } catch (_) {
      _ua = _fallbackUa();
    }
  }

  String get userAgent => _ua.isNotEmpty ? _ua : _fallbackUa();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final headers = request.headers;
    if (!headers.containsKey('User-Agent') &&
        !headers.containsKey('user-agent')) {
      headers['User-Agent'] = userAgent;
    }
    return _delegate.send(request);
  }

  @override
  void close() => _delegate.close();
}

final webClient = WebClient();
