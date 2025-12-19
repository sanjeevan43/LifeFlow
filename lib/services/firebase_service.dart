import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Minimal cache for critical data only
  static final Map<String, dynamic> _cache = {};
  // static DateTime? _lastCacheUpdate;
  static const int _maxCacheSize = 10;
  
  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Enable offline persistence
      await _firestore.enableNetwork();
      
      // debugPrint('✅ Firebase initialized successfully');
      // debugPrint('✅ Project ID: ${_firestore.app.options.projectId}');
      // debugPrint('✅ Auth Domain: ${_firestore.app.options.authDomain}');
      
    } catch (e) {
      // debugPrint('❌ Firebase initialization error: $e');
      rethrow;
    }
  }

  // Test Firebase connection (optimized)
  static Future<bool> testConnection() async {
    try {
      // Lightweight connection test
      await _firestore.enableNetwork();
      // debugPrint('✅ Firestore connection successful');
      return true;
    } catch (e) {
      // debugPrint('❌ Firebase connection failed: $e');
      return false;
    }
  }

  // Auth methods
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<UserCredential> createUserWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // User Profile methods
  static Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set({
      ...data,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  static Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Tasks methods (optimized with caching)
  static Future<DocumentReference> addTask(Map<String, dynamic> taskData) async {
    if (currentUserId == null) {
      throw Exception('Please sign in to add tasks');
    }
    
    try {
      _clearCache('tasks');
      return await _firestore.collection('tasks').add({
        ...taskData,
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getUserTasks() {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .limit(50)
        .snapshots()
        .handleError((error) {
          // debugPrint('Tasks error: $error');
          return const Stream.empty();
        });
  }

  static Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    _clearCache('tasks');
    await _firestore.collection('tasks').doc(taskId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteTask(String taskId) async {
    _clearCache('tasks');
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // Habits methods (optimized)
  static Future<DocumentReference> addHabit(Map<String, dynamic> habitData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    _clearCache('habits');
    return await _firestore.collection('habits').add({
      ...habitData,
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getUserHabits() {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: currentUserId)
        .limit(30)
        .snapshots()
        .handleError((error) {
          // debugPrint('Habits error: $error');
          return const Stream.empty();
        });
  }

  static Future<void> updateHabit(String habitId, Map<String, dynamic> updates) async {
    _clearCache('habits');
    await _firestore.collection('habits').doc(habitId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteHabit(String habitId) async {
    _clearCache('habits');
    await _firestore.collection('habits').doc(habitId).delete();
  }

  // Water tracking methods (optimized)
  static Future<void> addWaterIntake(int amount) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final docId = '${currentUserId}_$dateKey';
    
    _clearCache('water');
    await _firestore.collection('water_intake').doc(docId).set({
      'userId': currentUserId,
      'date': dateKey,
      'amount': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot> getTodayWaterIntake() {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final docId = '${currentUserId}_$dateKey';
    
    return _firestore.collection('water_intake').doc(docId).snapshots()
        .handleError((error) {
          // debugPrint('Water error: $error');
          return const Stream.empty();
        });
  }

  static Future<void> resetWaterIntake() async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final docId = '${currentUserId}_$dateKey';
    
    await _firestore.collection('water_intake').doc(docId).set({
      'userId': currentUserId,
      'date': dateKey,
      'amount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Statistics methods
  static Future<Map<String, int>> getUserStats() async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    try {
      // Get tasks count
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      // Get habits count
      final habitsSnapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      // Get today's water intake
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final waterDoc = await _firestore
          .collection('water_intake')
          .doc('${currentUserId}_$dateKey')
          .get();
      
      final completedTasks = tasksSnapshot.docs.where((doc) => 
        (doc.data())['isCompleted'] == true
      ).length;
      
      final completedHabits = habitsSnapshot.docs.where((doc) {
        final data = doc.data();
        final lastCompleted = data['lastCompleted'] as Timestamp?;
        if (lastCompleted == null) return false;
        
        final lastDate = lastCompleted.toDate();
        return lastDate.year == today.year &&
               lastDate.month == today.month &&
               lastDate.day == today.day;
      }).length;
      
      return {
        'totalTasks': tasksSnapshot.docs.length,
        'completedTasks': completedTasks,
        'totalHabits': habitsSnapshot.docs.length,
        'completedHabits': completedHabits,
        'waterIntake': waterDoc.data()?['amount'] ?? 0,
      };
    } catch (e) {
      // debugPrint('Error getting user stats: $e');
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalHabits': 0,
        'completedHabits': 0,
        'waterIntake': 0,
      };
    }
  }

  // Cache management with size limit
  static void _clearCache(String key) {
    _cache.remove(key);
    _limitCacheSize();
  }

  static void clearAllCache() {
    _cache.clear();
    // _lastCacheUpdate = null;
  }
  
  static void _limitCacheSize() {
    if (_cache.length > _maxCacheSize) {
      final keys = _cache.keys.toList();
      for (int i = 0; i < keys.length - _maxCacheSize; i++) {
        _cache.remove(keys[i]);
      }
    }
  }

  // Batch operations for better performance
  static Future<void> batchUpdate(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();
    
    for (final operation in operations) {
      final collection = operation['collection'] as String;
      final docId = operation['docId'] as String;
      final data = operation['data'] as Map<String, dynamic>;
      
      batch.update(_firestore.collection(collection).doc(docId), data);
    }
    
    await batch.commit();
    clearAllCache();
  }
}