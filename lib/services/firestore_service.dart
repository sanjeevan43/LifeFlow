// Optimized FirestoreService - now uses FirebaseService for better performance
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight wrapper around FirebaseService for backward compatibility
/// All methods now delegate to the optimized FirebaseService
class FirestoreService {
  // Delegate all methods to FirebaseService for consistency and performance
  
  static String? get currentUserId => FirebaseService.currentUserId;

  // User operations
  static Future<void> createUserProfile(Map<String, dynamic> userData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    await FirebaseService.createUserProfile(currentUserId!, userData);
  }

  static Future<DocumentSnapshot> getUserProfile() async {
    if (currentUserId == null) throw Exception('User not authenticated');
    return await FirebaseService.getUserProfile(currentUserId!);
  }

  // Task operations - delegate to FirebaseService
  static Future<void> addTask(Map<String, dynamic> taskData) async {
    await FirebaseService.addTask(taskData);
  }

  static Stream<QuerySnapshot> getTasks() {
    return FirebaseService.getUserTasks();
  }

  static Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await FirebaseService.updateTask(taskId, updates);
  }

  static Future<void> deleteTask(String taskId) async {
    await FirebaseService.deleteTask(taskId);
  }

  // Habit operations - delegate to FirebaseService
  static Future<void> addHabit(Map<String, dynamic> habitData) async {
    await FirebaseService.addHabit(habitData);
  }

  static Stream<QuerySnapshot> getHabits() {
    return FirebaseService.getUserHabits();
  }

  static Future<void> updateHabit(String habitId, Map<String, dynamic> updates) async {
    await FirebaseService.updateHabit(habitId, updates);
  }

  static Future<void> deleteHabit(String habitId) async {
    await FirebaseService.deleteHabit(habitId);
  }

  // Water tracking operations - delegate to FirebaseService
  static Future<void> addWaterIntake(int amount) async {
    await FirebaseService.addWaterIntake(amount);
  }

  static Stream<DocumentSnapshot> getTodayWaterIntake() {
    return FirebaseService.getTodayWaterIntake();
  }
}