import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String title;
  final String description;
  final int targetCount;
  final int currentStreak;
  final DateTime createdAt;
  final DateTime? lastCompleted;
  final String userId;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    this.targetCount = 1,
    this.currentStreak = 0,
    required this.createdAt,
    this.lastCompleted,
    required this.userId,
  });

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Habit data is null for document ${doc.id}');
    }
    
    return Habit(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      targetCount: (data['targetCount'] as num?)?.toInt() ?? 1,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastCompleted: data['lastCompleted'] != null 
          ? (data['lastCompleted'] as Timestamp).toDate() 
          : null,
      userId: data['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'targetCount': targetCount,
      'currentStreak': currentStreak,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastCompleted': lastCompleted != null ? Timestamp.fromDate(lastCompleted!) : null,
      'userId': userId,
    };
  }

  bool get isCompletedToday {
    if (lastCompleted == null) return false;
    final today = DateTime.now();
    final lastCompletedDate = lastCompleted!;
    return lastCompletedDate.year == today.year &&
           lastCompletedDate.month == today.month &&
           lastCompletedDate.day == today.day;
  }

  Habit copyWith({
    String? title,
    String? description,
    int? targetCount,
    int? currentStreak,
    DateTime? lastCompleted,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetCount: targetCount ?? this.targetCount,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      userId: userId,
    );
  }
}