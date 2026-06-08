import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifikasi Penting',
      description: 'Channel untuk notifikasi pesanan realtime',
      importance: Importance.max,
    );
    
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: null,
    );
    
    await localNotifications.initialize(
      settings: initSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notifikasi diklik: ${response.payload}');
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        localNotifications.show(
          id: 0, 
          title: message.notification!.title ?? "Notifikasi", 
          body: message.notification!.body ?? "", 
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notifikasi Penting',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ), 
        );
      }
    });
  }
}