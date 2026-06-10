import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      // 1. Request notification permissions (required for Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      print('[FCM] Notification authorization status: ${settings.authorizationStatus}');

      // 2. Fetch and print the FCM token for debugging/testing purposes
      String? token = await _fcm.getToken();
      print('[FCM] Device Token: $token');

      // 3. Configure foreground presentation options to display banners and play default sounds
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Handle incoming messages when the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('[FCM] Foreground message received:');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
      });

      // 5. Handle notification tap when the app is in the background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('[FCM] Message opened app: ${message.notification?.title}');
      });

      // 6. Automatically subscribe to the topic if the user is already logged in
      await subscribeToUserTopic();

    } catch (e) {
      print('[FCM] Error initializing notification service: $e');
    }
  }

  /// Subscribe to the lowercase, sanitized username topic
  Future<void> subscribeToUserTopic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('feName');

      if (name != null && name.trim().isNotEmpty) {
        // Firebase topic rules: [a-zA-Z0-9-_.~%]{1,900}
        // Convert to lowercase and sanitize any invalid characters to underscores
        String sanitizedTopic = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');

        if (sanitizedTopic.isNotEmpty) {
          print('[FCM] Subscribing to topic: $sanitizedTopic');
          await _fcm.subscribeToTopic(sanitizedTopic);
          print('[FCM] Successfully subscribed to topic: $sanitizedTopic');
        }
      } else {
        print('[FCM] No username found in storage. Skipping topic subscription.');
      }
    } catch (e) {
      print('[FCM] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from the lowercase, sanitized username topic upon logout
  Future<void> unsubscribeFromUserTopic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('feName');

      if (name != null && name.trim().isNotEmpty) {
        String sanitizedTopic = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');

        if (sanitizedTopic.isNotEmpty) {
          print('[FCM] Unsubscribing from topic: $sanitizedTopic');
          await _fcm.unsubscribeFromTopic(sanitizedTopic);
          print('[FCM] Successfully unsubscribed from topic: $sanitizedTopic');
        }
      }
    } catch (e) {
      print('[FCM] Error unsubscribing from topic: $e');
    }
  }
}
