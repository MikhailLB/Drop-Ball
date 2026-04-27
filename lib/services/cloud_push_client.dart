import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'browser_http.dart';
import 'local_store.dart';

const String pushChannelId = 'gr_priority_alerts';
const String pushChannelLabel = 'Gravity Rush Alerts';
const String pushIconRes = '@drawable/ic_notification';

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage _) async {}

class CloudPushClient {
  final FlutterLocalNotificationsPlugin _tray =
      FlutterLocalNotificationsPlugin();
  final LocalStore _store;
  FirebaseMessaging? _msg;
  String? _token;
  bool _ready = false;
  Future<bool>? _permissionFlow;

  void Function(String url)? onRemoteTarget;
  void Function(String token)? onTokenRotate;

  CloudPushClient(this._store);

  String? get token => _token;

  Future<void> bootstrap() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      _msg = FirebaseMessaging.instance;

      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
      await _configureLocalTray();

      _token = await _msg!.getToken();

      _msg!.onTokenRefresh.listen((fresh) {
        _token = fresh;
        onTokenRotate?.call(fresh);
      });

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onBackgroundTap);

      final cold = await _msg!.getInitialMessage();
      if (cold != null) _onColdStart(cold);

      _ready = true;
      if (kDebugMode) {
        debugPrint('[PUSH] bootstrap OK, token=${_token?.substring(0, 12)}...');
      }
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[PUSH] bootstrap FAILED: $err');
        debugPrint('$st');
      }
    }
  }

  Future<void> _configureLocalTray() async {
    const androidInit = AndroidInitializationSettings(pushIconRes);
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _tray.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map && decoded['url'] is String) {
            final url = decoded['url'] as String;
            if (url.isNotEmpty) onRemoteTarget?.call(url);
          }
        } catch (_) {}
      },
    );

    if (Platform.isAndroid) {
      final impl = _tray.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.createNotificationChannel(
        const AndroidNotificationChannel(
          pushChannelId,
          pushChannelLabel,
          description: 'Priority push channel',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<bool> askConsent() async {
    if (_msg == null) {
      if (kDebugMode) {
        debugPrint('[PUSH] askConsent skipped: Firebase not initialized');
      }
      return false;
    }
    final pending = _permissionFlow;
    if (pending != null) return pending;

    final future = _askConsentImpl();
    _permissionFlow = future;
    try {
      return await future;
    } finally {
      _permissionFlow = null;
    }
  }

  Future<bool> _askConsentImpl() async {
    try {
      if (Platform.isAndroid) {
        return await _askConsentAndroid();
      }
      return await _askConsentIOS();
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[PUSH] askConsent error: $err');
        debugPrint('$st');
      }
      return false;
    }
  }

  Future<bool> _askConsentAndroid() async {
    final androidImpl = _tray.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) {
      if (kDebugMode) {
        debugPrint('[PUSH] android plugin impl missing — fallback to firebase');
      }
      return _askConsentIOS();
    }

    final alreadyEnabled = await androidImpl.areNotificationsEnabled();
    if (kDebugMode) {
      debugPrint('[PUSH] android areNotificationsEnabled=$alreadyEnabled');
    }
    if (alreadyEnabled == true) {
      await _store.writePushConsent(true);
      return true;
    }

    final granted = await androidImpl.requestNotificationsPermission();
    if (kDebugMode) {
      debugPrint('[PUSH] android requestNotificationsPermission=$granted');
    }
    final ok = granted ?? false;
    await _store.writePushConsent(ok);
    return ok;
  }

  Future<bool> _askConsentIOS() async {
    final current = await _msg!.getNotificationSettings();
    if (kDebugMode) {
      debugPrint('[PUSH] ios current status=${current.authorizationStatus}');
    }
    if (current.authorizationStatus != AuthorizationStatus.notDetermined) {
      final ok =
          current.authorizationStatus == AuthorizationStatus.authorized ||
              current.authorizationStatus == AuthorizationStatus.provisional;
      await _store.writePushConsent(ok);
      return ok;
    }

    final result = await _msg!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('[PUSH] ios requestPermission=${result.authorizationStatus}');
    }
    final ok = result.authorizationStatus == AuthorizationStatus.authorized ||
        result.authorizationStatus == AuthorizationStatus.provisional;
    await _store.writePushConsent(ok);
    return ok;
  }

  void _onForeground(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    String? imageUrl;
    if (Platform.isAndroid) {
      imageUrl = notif.android?.imageUrl;
    } else {
      imageUrl = notif.apple?.imageUrl;
    }

    AndroidNotificationDetails? androidDetails;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final bytes = await _downloadPicture(imageUrl);
      if (bytes != null) {
        androidDetails = AndroidNotificationDetails(
          pushChannelId,
          pushChannelLabel,
          importance: Importance.high,
          priority: Priority.high,
          icon: pushIconRes,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon:
                const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }

    androidDetails ??= const AndroidNotificationDetails(
      pushChannelId,
      pushChannelLabel,
      importance: Importance.high,
      priority: Priority.high,
      icon: pushIconRes,
    );

    final payload =
        message.data.isNotEmpty ? jsonEncode(message.data) : null;

    await _tray.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _onColdStart(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) {
      _store.writePushTarget(url);
    }
  }

  void _onBackgroundTap(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) {
      onRemoteTarget?.call(url);
    }
  }

  Future<Uint8List?> _downloadPicture(String url) async {
    try {
      final response = await browserHttp
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }
}
