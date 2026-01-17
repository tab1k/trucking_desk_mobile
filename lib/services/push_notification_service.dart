import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fura24.kz/core/config/app_config.dart';
import 'package:fura24.kz/core/config/firebase_web_options.dart';
import 'package:fura24.kz/features/auth/repositories/auth_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to initialize and handle FCM + local notifications.
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static String _appVersion = '';
  static Function(Map<String, dynamic>)? _onNotificationClick;

  static Future<void> initialize({
    Function(Map<String, dynamic>)? onNotificationClick,
  }) async {
    if (_initialized) return;

    _onNotificationClick = onNotificationClick;

    // Must be set before `runApp` for background handling to work reliably.
    if (!kIsWeb && _supportsPushOnPlatform()) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    if (kIsWeb) {
      final options = FirebaseWebOptions.web();
      if (options == null) {
        debugPrint(
          '[PushNotificationService] Firebase web options are missing. Push notifications are disabled on web.',
        );
        _initialized = true;
        return;
      }

      await Firebase.initializeApp(options: options);
      // Web push flow (service worker, VAPID key, etc.) is not wired yet.
      _initialized = true;
      return;
    }

    if (!_supportsPushOnPlatform()) {
      debugPrint(
        '[PushNotificationService] Push not initialized: unsupported platform (${defaultTargetPlatform.name}).',
      );
      _initialized = true;
      return;
    }

    final firebaseReady = await _initializeNativeFirebase();
    if (!firebaseReady) {
      _initialized = true;
      return;
    }
    await _loadAppVersion();
    await _configureLocalNotifications();
    await _requestPermissions();
    await _createNotificationChannel();
    await _setupMessageHandlers();
    await _refreshToken();

    // Listen for token refresh and push to backend.
    _fcm.onTokenRefresh.listen(_sendTokenToBackend);

    _initialized = true;
  }

  static bool _supportsPushOnPlatform() {
    // Firebase Messaging officially supports Android/iOS. Desktop is skipped.
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<bool> _initializeNativeFirebase() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (error, _) {
      debugPrint(
        '[PushNotificationService] Firebase init failed on ${defaultTargetPlatform.name}: $error',
      );
      return false;
    }
  }

  static Future<void> _configureLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationPayload(response.payload);
      },
    );
  }

  static Future<void> _requestPermissions() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // iOS: allow showing banner/sound in foreground.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _createNotificationChannel() async {
    final channel = AndroidNotificationChannel(
      'fura24_channel',
      'notifications.channel_name'.tr(),
      description: 'notifications.channel_description'.tr(),
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _setupMessageHandlers() async {
    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Background/opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
    });
  }

  static Future<void> _refreshToken() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    debugPrint('[PushNotificationService] FCM token: $token');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    await prefs.setBool('fcm_token_sent', false);
    await _sendTokenToBackend(token);
  }

  static Future<void> _sendTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();

    final session = await SharedPrefsAuthStorage().readSession();
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl.endsWith('/')
            ? AppConfig.apiBaseUrl
            : '${AppConfig.apiBaseUrl}/',
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    try {
      final response = await dio.post(
        'notifications/register/',
        data: {
          'token': token,
          'platform': _currentPlatformLabel(),
          'app_version': _appVersion,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setBool('fcm_token_sent', true);
        debugPrint(
          '[PushNotificationService] Token sent to backend (platform=${_currentPlatformLabel()}, version=$_appVersion)',
        );
      } else {
        await prefs.setBool('fcm_token_sent', false);
      }
    } catch (_) {
      // Токен попробуем отправить позже
      debugPrint(
        '[PushNotificationService] Failed to send token, will retry later',
      );
      await prefs.setBool('fcm_token_sent', false);
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'fura24_channel',
      'notifications.channel_name'.tr(),
      channelDescription: 'notifications.channel_description'.tr(),
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      styleInformation: BigTextStyleInformation(
        message.notification?.body ?? '',
        htmlFormatBigText: true,
        contentTitle:
            message.notification?.title ?? 'notifications.default_title'.tr(),
        htmlFormatContentTitle: true,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'notifications.default_title'.tr(),
      message.notification?.body ?? 'notifications.default_body'.tr(),
      details,
      payload: json.encode(message.data),
    );
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    _onNotificationClick?.call(data);
  }

  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final map = json.decode(payload) as Map<String, dynamic>;
      _handleNotificationClick(map);
    } catch (e) {
      debugPrint('[PushNotificationService] Payload parse error: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) =>
      _fcm.subscribeToTopic(topic);

  static Future<void> unsubscribeFromTopic(String topic) =>
      _fcm.unsubscribeFromTopic(topic);

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    final existingToken = prefs.getString('fcm_token');

    try {
      if (existingToken != null && existingToken.isNotEmpty) {
        final session = await SharedPrefsAuthStorage().readSession();
        final accessToken = session?.accessToken;
        if (accessToken != null && accessToken.isNotEmpty) {
          final dio = Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl.endsWith('/')
                  ? AppConfig.apiBaseUrl
                  : '${AppConfig.apiBaseUrl}/',
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Accept': 'application/json',
              },
            ),
          );
          await dio.delete(
            'notifications/register/',
            data: {'token': existingToken},
          );
        }
      }
    } catch (_) {
      // Если не удалось удалить на сервере, просто продолжаем очистку локально.
    }

    await _fcm.deleteToken();
    await prefs.remove('fcm_token');
    await prefs.remove('fcm_token_sent');
    await prefs.remove('fcm_topics');
  }

  /// Отправить уже сохраненный токен, если он ещё не был отправлен.
  /// Вызываем после успешной авторизации, чтобы токен сразу ушёл на бэк.
  static Future<void> syncTokenWithBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    final sent = prefs.getBool('fcm_token_sent') ?? false;
    if (token == null || token.isEmpty || sent) return;
    await _sendTokenToBackend(token);
  }

  static Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
    } catch (_) {
      _appVersion = '';
    }
  }

  static String _currentPlatformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'DESKTOP';
      default:
        return 'ANDROID';
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  const channel = AndroidNotificationChannel(
    'fura24_channel',
    'Fura24 уведомления', // TODO: Localize (requires separate locale init in background isolate)
    description: 'Канал для push-уведомлений Fura24.kz',
    importance: Importance.max,
  );

  final local = FlutterLocalNotificationsPlugin();
  await local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  const androidDetails = AndroidNotificationDetails(
    'fura24_channel',
    'Fura24 уведомления',
    channelDescription: 'Канал для push-уведомлений Fura24.kz',
    importance: Importance.max,
    priority: Priority.high,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await local.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? 'Fura24.kz', // TODO: Localize
    message.notification?.body ?? 'Новое уведомление', // TODO: Localize
    details,
    payload: json.encode(message.data),
  );
}
