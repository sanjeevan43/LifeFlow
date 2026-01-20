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
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'lifeflow_channel',
            'LifeFlow Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  /// Schedule a generic local notification
  static Future<void> scheduleLocalNotification(String id, String title, DateTime dateTime) async {
    if (dateTime.isBefore(DateTime.now())) return;

    await _localNotifications.zonedSchedule(
      id.hashCode,
      'Reminder',
      title,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'General Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a specific local notification
  static Future<void> cancelLocalNotification(String id) async {
    await _localNotifications.cancel(id.hashCode);
  }

  /// Reschedule a specific local notification
  static Future<void> rescheduleNotification(String id, String title, DateTime dateTime) async {
    await cancelLocalNotification(id);
    await scheduleLocalNotification(id, title, dateTime);
  }

  static Future<void> scheduleTaskReminder(String id, String title, DateTime dateTime) async {
    if (dateTime.isBefore(DateTime.now())) return;

    await _localNotifications.zonedSchedule(
      id.hashCode,
      'Task Reminder',
      title,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleHabitReminder(String id, String title, DateTime dateTime) async {
    if (dateTime.isBefore(DateTime.now())) return;

    await _localNotifications.zonedSchedule(
      id.hashCode,
      'Habit Reminder',
      "Don't forget: $title",
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Clear FCM token on logout
  static Future<void> logout() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (e) {
        // Doc might not exist or field might already be missing
      }
    }
  }
}
