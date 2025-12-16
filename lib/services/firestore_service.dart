import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // User operations
  static Future<void> createUserProfile(Map<String, dynamic> userData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _db.collection('users').doc(currentUserId).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': true,
    });
  }

  static Future<DocumentSnapshot> getUserProfile() async {
    if (currentUserId == null) throw Exception('User not authenticated');
    return await _db.collection('users').doc(currentUserId).get();
  }

  // Task operations
  static Future<void> addTask(Map<String, dynamic> taskData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _db.collection('tasks').add({
      ...taskData,
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getTasks() {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await _db.collection('tasks').doc(taskId).update(updates);
  }

  static Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  // Habit operations
  static Future<void> addHabit(Map<String, dynamic> habitData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _db.collection('habits').add({
      ...habitData,
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getHabits() {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    return _db
        .collection('habits')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateHabit(String habitId, Map<String, dynamic> updates) async {
    await _db.collection('habits').doc(habitId).update(updates);
  }

  static Future<void> deleteHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).delete();
  }

  // Water tracking operations
  static Future<void> addWaterIntake(int amount) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    await _db.collection('water').doc('${currentUserId}_$dateKey').set({
      'userId': currentUserId,
      'date': dateKey,
      'amount': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot> getTodayWaterIntake() {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _db.collection('water').doc('${currentUserId}_$dateKey').snapshots();
  }
}