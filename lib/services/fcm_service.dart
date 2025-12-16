import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeFCM() async {
    await requestNotificationPermission();
    await generateAndSaveFCMToken();
  }

  static Future<void> requestNotificationPermission() async {
    // Request notification permission
  }

  static Future<void> generateAndSaveFCMToken() async {
    const token = 'mock_fcm_token';
    await saveFCMToken(token);
  }

  static Future<void> saveFCMToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> deleteFCMTokenOnLogout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }
  }
}