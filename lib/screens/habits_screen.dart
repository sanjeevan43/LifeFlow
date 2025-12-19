import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with AutomaticKeepAliveClientMixin {
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  bool get wantKeepAlive => true;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getUserHabits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading habits...'),
                ],
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }
          
          final habits = snapshot.data!.docs
              .map((doc) {
                try {
                  return Habit.fromFirestore(doc);
                } catch (e) {
                  // debugPrint('Error parsing habit: $e');
                  return null;
                }
              })
              .where((habit) => habit != null)
              .cast<Habit>()
              .toList();
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                return _buildHabitCard(habits[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: habit.isCompletedToday ? Colors.green : Colors.grey,
          child: Text('${habit.currentStreak}'),
        ),
        title: Text(habit.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (habit.description.isNotEmpty) Text(habit.description),
            Text('Streak: ${habit.currentStreak} days'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                habit.isCompletedToday ? Icons.check_circle : Icons.circle_outlined,
                color: habit.isCompletedToday ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleHabit(habit),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') _deleteHabit(habit.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No habits yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          Text('Tap + to add your first habit'),
        ],
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    _titleController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Habit Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.trim().isNotEmpty) {
                try {
                  await _addHabit(_titleController.text.trim(), _descriptionController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Habit added successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding habit: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addHabit(String title, String description) async {
    await FirebaseService.addHabit({
      'title': title,
      'description': description,
      'targetCount': 1,
      'currentStreak': 0,
    });
    
    // Schedule daily habit reminder
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await NotificationService.scheduleHabitReminder(title, tomorrow);
  }

  Future<void> _toggleHabit(Habit habit) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (habit.isCompletedToday) {
        // Uncomplete today
        await FirebaseService.updateHabit(habit.id, {
          'lastCompleted': null,
          'currentStreak': habit.currentStreak > 0 ? habit.currentStreak - 1 : 0,
        });
      } else {
        // Complete today
        int newStreak = habit.currentStreak;
        if (habit.lastCompleted != null) {
          final lastDate = DateTime(
            habit.lastCompleted!.year,
            habit.lastCompleted!.month,
            habit.lastCompleted!.day,
          );
          final yesterday = today.subtract(const Duration(days: 1));
          
          if (lastDate.isAtSameMomentAs(yesterday)) {
            newStreak += 1;
          } else {
            newStreak = 1;
          }
        } else {
          newStreak = 1;
        }
        
        await FirebaseService.updateHabit(habit.id, {
          'lastCompleted': Timestamp.fromDate(now),
          'currentStreak': newStreak,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating habit: $e')),
        );
      }
    }
  }

  Future<void> _deleteHabit(String habitId) async {
    try {
      await FirebaseService.deleteHabit(habitId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting habit: $e')),
        );
      }
    }
  }
}