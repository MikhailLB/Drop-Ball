import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetSensor {
  final Connectivity _conn = Connectivity();

  Future<bool> hasInternet() async {
    final r = await _conn.checkConnectivity();
    if (!r.any((s) => s != ConnectivityResult.none)) return false;
    try {
      final res = await InternetAddress.lookup('cloudflare.com')
          .timeout(const Duration(seconds: 3));
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Stream<List<ConnectivityResult>> get onChange => _conn.onConnectivityChanged;
}
