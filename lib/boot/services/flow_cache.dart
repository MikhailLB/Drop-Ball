import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_mode.dart';

class FlowCache {
  static const _kRoute         = 'db_route';
  static const _kSavedUrl      = 'db_sv_u';
  static const _kUrlExp        = 'db_url_exp';
  static const _kNotifSkip     = 'db_notif_skip';
  static const _kNotifGranted  = 'db_notif_ok';
  static const _kNotifDenied   = 'db_notif_denied';
  static const _kPushUrl       = 'db_push_u';

  late SharedPreferences _prefs;
  final FlutterSecureStorage _safe = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  RouteMode readRoute() => RouteMode.fromString(_prefs.getString(_kRoute));
  Future<void> writeRoute(RouteMode r) => _prefs.setString(_kRoute, r.toKey());

  Future<String?> getSavedUrl()         => _safe.read(key: _kSavedUrl);
  Future<void>    setSavedUrl(String u)  => _safe.write(key: _kSavedUrl, value: u);

  int?            getUrlExp()             => _prefs.getInt(_kUrlExp);
  Future<void>    setUrlExp(int ts)       => _prefs.setInt(_kUrlExp, ts);

  bool isUrlExpired() {
    final e = getUrlExp();
    if (e == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= e;
  }

  bool            isNotifGranted()        => _prefs.getBool(_kNotifGranted) ?? false;
  Future<void>    setNotifGranted(bool v) => _prefs.setBool(_kNotifGranted, v);

  bool            isNotifDenied()         => _prefs.getBool(_kNotifDenied) ?? false;
  Future<void>    setNotifDenied(bool v)  => _prefs.setBool(_kNotifDenied, v);

  int?            getNotifSkip()          => _prefs.getInt(_kNotifSkip);
  Future<void>    setNotifSkip(int ts)    => _prefs.setInt(_kNotifSkip, ts);

  bool shouldShowNotifPrompt() {
    if (isNotifDenied() || isNotifGranted()) return false;
    final s = getNotifSkip();
    if (s == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= s;
  }

  Future<String?> getPushUrl()           => _safe.read(key: _kPushUrl);
  Future<void>    stashPushUrl(String u) => _safe.write(key: _kPushUrl, value: u);
  Future<String?> consumePushUrl() async {
    final v = await getPushUrl();
    if (v != null) await _safe.delete(key: _kPushUrl);
    return v;
  }
}
