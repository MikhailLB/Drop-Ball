import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'flow_cache.dart';
import 'safe_http.dart';

@pragma('vm:entry-point')
Future<void> _bgMsgHandler(RemoteMessage _) async {}

String? _extractUrl(Map<String, dynamic> data) {
  for (final k in ['url', 'link', 'target', 'deeplink', 'deep_link']) {
    final v = data[k] as String?;
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

class PushRelay {
  final FlutterLocalNotificationsPlugin _tray = FlutterLocalNotificationsPlugin();
  final FlowCache _cache;
  FirebaseMessaging? _fcm;
  String? _token;
  bool _initialized = false;
  bool _consentBusy = false;

  Function(String url)?   onPushDestination;
  Function(String token)? onTokenRefresh;

  PushRelay(this._cache);
  String? get token => _token;

  Future<void> bootstrap() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_bgMsgHandler);
      await _initTray();
      _token = await _fcm!.getToken();
      _fcm!.onTokenRefresh.listen((t) { _token = t; onTokenRefresh?.call(t); });
      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onBgTap);
      final init = await _fcm!.getInitialMessage();
      if (init != null) {
        final url = _extractUrl(init.data);
        if (url != null) _cache.stashPushUrl(url);
      }
      _initialized = true;
    } catch (_) {}
  }

  Future<void> _initTray() async {
    const android = AndroidInitializationSettings('@drawable/ic_db_notify');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
    await _tray.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload == null) return;
        try {
          final url = _extractUrl(jsonDecode(r.payload!) as Map<String, dynamic>);
          if (url != null) onPushDestination?.call(url);
        } catch (_) {}
      },
    );
    if (Platform.isAndroid) {
      final ap = _tray.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await ap?.createNotificationChannel(const AndroidNotificationChannel(
        'db_notify_ch', 'Drop Ball Alerts',
        description: 'Push notifications',
        importance: Importance.high,
      ));
    }
  }

  Future<bool> askConsent() async {
    if (_fcm == null || _consentBusy) return false;
    _consentBusy = true;
    try {
      final s = await _fcm!.requestPermission(alert: true, badge: true, sound: true);
      final ok = s.authorizationStatus == AuthorizationStatus.authorized ||
                 s.authorizationStatus == AuthorizationStatus.provisional;
      await _cache.setNotifGranted(ok);
      await _cache.setNotifDenied(!ok);
      return ok;
    } catch (_) { return false; } finally { _consentBusy = false; }
  }

  void _onForeground(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;
    final imgUrl = msg.notification?.android?.imageUrl;
    AndroidNotificationDetails? details;
    if (imgUrl != null && imgUrl.isNotEmpty) {
      final bytes = await _fetchImage(imgUrl);
      if (bytes != null) {
        details = AndroidNotificationDetails(
          'db_notify_ch', 'Drop Ball Alerts',
          importance: Importance.high, priority: Priority.high,
          icon: '@drawable/ic_db_notify',
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }
    details ??= const AndroidNotificationDetails(
      'db_notify_ch', 'Drop Ball Alerts',
      importance: Importance.high, priority: Priority.high, icon: '@drawable/ic_db_notify');
    final payload = msg.data.isNotEmpty ? jsonEncode(msg.data) : null;
    await _tray.show(n.hashCode, n.title, n.body,
        NotificationDetails(android: details, iOS: const DarwinNotificationDetails()),
        payload: payload);
  }

  void _onBgTap(RemoteMessage msg) {
    final url = _extractUrl(msg.data);
    if (url != null) onPushDestination?.call(url);
  }

  Future<Uint8List?> _fetchImage(String url) async {
    try {
      final r = await safeHttp.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) return r.bodyBytes;
    } catch (_) {}
    return null;
  }
}
