import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import '../edit_reminder_screen.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onEdit;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: reminder.isDone,
          onChanged: (value) => markReminderAsDone(value ?? false),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration: reminder.isDone ? TextDecoration.lineThrough : null,
            color: reminder.isDone ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy - hh:mm a').format(reminder.remindAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reminder.isRepeating)
              const Icon(Icons.repeat, size: 16, color: Colors.blue),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => navigateToEdit(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> markReminderAsDone(bool isDone) async {
    await ReminderService.markReminderAsDone(reminder.id, isDone);
  }

  void navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReminderScreen(reminder: reminder),
      ),
    );
  }

  void confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteReminder();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteReminder() async {
    await ReminderService.deleteReminder(reminder.id);
  }
}