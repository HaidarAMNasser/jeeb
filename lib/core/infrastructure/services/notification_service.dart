import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/pages/delivery_home_page.dart';
import '../../presentation/routes/navigation_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep lightweight: Firebase handles message delivery and tap launch.
}

class NotificationService {
  NotificationService(this._navigationService);

  final NavigationService _navigationService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'jeeb_high_importance',
        'High Importance Notifications',
        description: 'Used for important app notifications.',
        importance: Importance.high, 
      );

  Future<void> initialize({
    required void Function(String token) onToken,
  }) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _initializeLocalNotifications();
    await _configureForegroundMessages();
    await _configureNotificationClickHandling();
    await _loadInitialToken(onToken);
    _listenToTokenRefresh(onToken);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleLocalNotificationClick(details.payload);
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _configureForegroundMessages() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onMessage.listen((message) async {
      await _showForegroundNotification(message);
    });
  }

  Future<void> _configureNotificationClickHandling() async {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageClick);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageClick(initialMessage);
    }
  }

  Future<void> _loadInitialToken(void Function(String token) onToken) async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      onToken(token);
    }
  }

  void _listenToTokenRefresh(void Function(String token) onToken) {
    _messaging.onTokenRefresh.listen((token) {
      if (token.isNotEmpty) {
        onToken(token);
      }
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final payload = jsonEncode(message.data);
    await _localNotificationsPlugin.show(
      message.hashCode,
      notification.title ?? '',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _handleRemoteMessageClick(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _handleLocalNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _navigateFromData(decoded);
      } else if (decoded is Map) {
        _navigateFromData(decoded.cast<String, dynamic>());
      }
    } catch (_) {
      // Ignore malformed payloads silently.
    }
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'];
    String? id = data['id'];

    if (type == null) return;

    switch (type) {
      case 'order':
        _navigationService.pushNamed(
          Routes.orderDetails,
          arguments: {"orderId": id ?? ""},
        );
        break;

      case 'delivery':
        _navigationService.push(DeliveryHomePage());
        break;

      default:
        print("Unknown notification type: $type");
    }
  }
}
//  one fc mtoken for every account 
// list of fcm token for every account