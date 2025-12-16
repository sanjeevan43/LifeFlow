import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _userId => _auth.currentUser?.uid ?? '';

  static Future<void> toggleNotifications(bool enabled) async {
    await _firestore.collection('users').doc(_userId).update({
      'notificationsEnabled': enabled,
      'settingsUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateNotificationPreference(bool enabled) async {
    await toggleNotifications(enabled);
  }

  static Future<bool> getNotificationPreference() async {
    final doc = await _firestore.collection('users').doc(_userId).get();
    return doc.data()?['notificationsEnabled'] ?? true;
  }
}