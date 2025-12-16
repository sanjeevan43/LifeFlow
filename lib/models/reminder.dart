class Reminder {
  final String id;
  final String title;
  final DateTime remindAt;
  final bool isRepeating;
  final bool isDone;
  final String userId;

  Reminder({
    required this.id,
    required this.title,
    required this.remindAt,
    this.isRepeating = false,
    this.isDone = false,
    required this.userId,
  });

  factory Reminder.fromFirestore(Map<String, dynamic> data, String id) {
    return Reminder(
      id: id,
      title: data['title'] ?? '',
      remindAt: DateTime.parse(data['remindAt']),
      isRepeating: data['isRepeating'] ?? false,
      isDone: data['isDone'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'remindAt': remindAt.toIso8601String(),
      'isRepeating': isRepeating,
      'isDone': isDone,
      'userId': userId,
    };
  }
}