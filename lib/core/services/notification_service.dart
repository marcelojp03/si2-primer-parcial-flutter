import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log('📩 [FCM Background] ${message.messageId}', name: 'FCM');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'auxilio_mecanico_alerts',
    'Alertas Auxilio Mecánico',
    description: 'Notificaciones de estado del incidente',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermissions();
    await _setupLocalNotifications();
    _setupMessageHandlers();
    final token = await getToken();
    developer.log('📱 FCM Token: $token', name: 'FCM');
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    developer.log(
      '📩 FCM Permission: ${settings.authorizationStatus}',
      name: 'FCM',
    );
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    // Crear canal Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  void _setupMessageHandlers() {
    // Foreground
    FirebaseMessaging.onMessage.listen((message) {
      developer.log(
        '📩 [FCM Foreground] ${message.notification?.title}',
        name: 'FCM',
      );
      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<String?> getToken() async {
    return _messaging.getToken();
  }
}
