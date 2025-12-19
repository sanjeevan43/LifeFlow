import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize notifications - call this on app start
  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return; // User denied permissions
    }

    // Get and save FCM Token automatically
    await _getAndSaveFCMToken();
    
    // Listen for token refresh (tokens can change)
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveFCMTokenToFirestore(newToken);
    });
    
    // Initialize local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
    
    // Handle background click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation based on message data
    });
  }

  /// Get FCM token and save to Firestore
  static Future<void> _getAndSaveFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMTokenToFirestore(token);
      }
    } catch (e) {
      // Token fetch failed - will retry on next app start
    }
  }

  /// Save FCM token to user's Firestore document
  static Future<void> _saveFCMTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': true,
      }, SetOptions(merge: true));
    } catch (e) {
      // Firestore save failed - will retry on next app start
    }
  }

  /// Call this after user logs in to ensure token is saved
  static Future<void> registerUserForNotifications() async {
    await _getAndSaveFCMToken();
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification
    // Note: on Web, Firebase Messaging automatically supports foreground notifications if configured,
    // but showing a manual one is also possible if the automatic one doesn't trigger.
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.
    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'lifeflow_channel',
            'LifeFlow Notifications',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  static Future<void> scheduleTaskReminder(String taskTitle, DateTime dateTime) async {
    await _localNotifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Task Reminder',
      taskTitle,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: Importance.high,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleHabitReminder(String habitTitle, DateTime dateTime) async {
    await _localNotifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Habit Reminder',
      "Don't forget: $habitTitle",
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          importance: Importance.high,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}