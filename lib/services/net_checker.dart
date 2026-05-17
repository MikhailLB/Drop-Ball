import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetChecker {
  final Connectivity _probe = Connectivity();

  Future<bool> isOnline() async {
    final statuses = await _probe.checkConnectivity();
    final anyActive = statuses.any((s) => s != ConnectivityResult.none);
    if (!anyActive) return false;

    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (lookup.isEmpty) return false;
      return lookup.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Stream<List<ConnectivityResult>> watch() => _probe.onConnectivityChanged;
}
