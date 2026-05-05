import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

      await _msg!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _token = await _readTokenWithApnsReady(reason: 'bootstrap');

      _msg!.onTokenRefresh.listen((fresh) {
        _token = fresh;
        if (kDebugMode) {
          _debugToken('onTokenRefresh', fresh);
        }
        onTokenRotate?.call(fresh);
      });

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onBackgroundTap);

      final cold = await _msg!.getInitialMessage();
      if (cold != null) await _onColdStart(cold);

      _ready = true;
      if (kDebugMode) {
        debugPrint('[PUSH] bootstrap OK');
      }
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[PUSH] bootstrap FAILED: $err');
        debugPrint('$st');
      }
    }
  }

  Future<String?> refreshToken({bool notify = true}) async {
    if (_msg == null) {
      if (kDebugMode) {
        debugPrint('[PUSH] refreshToken skipped: Firebase not initialized');
      }
      return null;
    }
    try {
      _token = await _readTokenWithApnsReady(reason: 'manual_refresh');
      final fresh = _token;
      if (notify && fresh != null && fresh.isNotEmpty) {
        onTokenRotate?.call(fresh);
      }
      return fresh;
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[PUSH] refreshToken FAILED: $err');
        debugPrint('$st');
      }
      return null;
    }
  }

  Future<String?> _readTokenWithApnsReady({required String reason}) async {
    if (_msg == null) return null;

    if (Platform.isIOS) {
      String? apnsToken;
      for (var attempt = 1; attempt <= 6; attempt++) {
        apnsToken = await _msg!.getAPNSToken();
        if (kDebugMode) {
          debugPrint(
            '[PUSH] $reason APNs token attempt $attempt: '
            '${apnsToken == null || apnsToken.isEmpty ? 'null' : apnsToken}',
          );
        }
        if (apnsToken != null && apnsToken.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }

    final settings = await _msg!.getNotificationSettings();
    if (kDebugMode) {
      debugPrint(
        '[PUSH] $reason notification status='
        '${settings.authorizationStatus}',
      );
    }

    final token = await _msg!.getToken();
    if (kDebugMode) {
      _debugToken('$reason FCM token', token);
    }
    return token;
  }

  void _debugToken(String label, String? token) {
    if (!kDebugMode) return;
    if (token == null || token.isEmpty) {
      debugPrint('[PUSH] $label=null');
      return;
    }
    // Full token is intentionally printed in debug builds so it can be pasted
    // into Firebase Console -> Cloud Messaging -> Send test message.
    debugPrint('[PUSH] $label=$token');
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
      final impl = _tray
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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

  /// True only if the OS will actually surface a permission prompt when
  /// `askConsent()` is called. Once the user denies notifications at the
  /// system level, iOS / Android won't show the prompt again, so our
  /// custom opt-in screen becomes a dead end (ALLOW just closes it).
  /// We use this to skip the opt-in entirely in that situation.
  Future<bool> canShowSystemPrompt() async {
    if (_msg == null) return false;
    try {
      final settings = await _msg!.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.notDetermined;
    } catch (_) {
      return false;
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
    final androidImpl = _tray
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
    final ok =
        result.authorizationStatus == AuthorizationStatus.authorized ||
        result.authorizationStatus == AuthorizationStatus.provisional;
    await _store.writePushConsent(ok);
    return ok;
  }

  void _onForeground(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    // On iOS the system already presents the FCM notification in foreground
    // (alert/badge/sound enabled in bootstrap) and the Notification Service
    // Extension attaches the image before display. Scheduling our own
    // flutter_local_notifications copy here used to produce a duplicate
    // banner and broke tap routing because Firebase's swizzled
    // UNUserNotificationCenter delegate intercepts taps on locally-scheduled
    // notifications differently from FCM-displayed ones. Taps on the system
    // notification flow through onMessageOpenedApp which onRemoteTarget
    // subscribers already handle.
    if (Platform.isIOS) return;

    final imageUrl = notif.android?.imageUrl;

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
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
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

    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;

    await _tray.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  Future<void> _onColdStart(RemoteMessage message) async {
    final url = _extractUrl(message);
    if (url != null && url.isNotEmpty) {
      // Persist BEFORE bootstrap returns so BootScreen's takePushTarget()
      // sees the target. Without await we used to race the writer against
      // the reader and silently fall through to the cached config target.
      await _store.writePushTarget(url);
    }
  }

  String? _extractUrl(RemoteMessage message) {
    final data = message.data;
    final candidates = [
      data['url'],
      data['link'],
      data['target'],
      data['deeplink'],
      data['deep_link'],
    ];
    for (final raw in candidates) {
      if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    }
    return null;
  }

  void _onBackgroundTap(RemoteMessage message) {
    final url = _extractUrl(message);
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
