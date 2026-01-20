import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder.dart';
import 'notification_service.dart';

class ReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _userId => _auth.currentUser?.uid ?? '';

  static Stream<List<Reminder>> getReminderStream() {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _userId)
        .orderBy('remindAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  static Stream<List<Reminder>> getReminders() => getReminderStream();

  static Future<List<Reminder>> fetchUserReminders() async {
    final snapshot = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _userId)
        .orderBy('remindAt')
        .get();
    return snapshot.docs
        .map((doc) => Reminder.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  static Future<Reminder?> getNextUpcomingReminder() async {
    final reminders = await fetchUserReminders();
    final upcoming = reminders
        .where((r) => !r.isDone && r.remindAt.isAfter(DateTime.now()))
        .toList();
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  static Future<void> createReminder(Reminder reminder) async {
    final docRef = await _firestore.collection('reminders').add(reminder.toFirestore());
    await NotificationService.scheduleLocalNotification(docRef.id, reminder.title, reminder.remindAt);
  }

  static Future<void> updateReminder(Reminder reminder) async {
    await _firestore.collection('reminders').doc(reminder.id).update(reminder.toFirestore());
    await NotificationService.rescheduleNotification(reminder.id, reminder.title, reminder.remindAt);
  }

  static Future<void> deleteReminder(String id) async {
    await _firestore.collection('reminders').doc(id).delete();
    await NotificationService.cancelLocalNotification(id);
  }

  static Future<void> markReminderAsDone(String id, bool isDone) async {
    await _firestore.collection('reminders').doc(id).update({'isDone': isDone});
  }

  static Future<void> updateReminderStatus(String id, bool isDone) async {
    await markReminderAsDone(id, isDone);
  }
}