import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';
import 'focus_screen.dart';
import '../models/task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with AutomaticKeepAliveClientMixin {
  
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
        title: const Text('Tasks'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getUserTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading tasks...'),
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
          
          final tasks = snapshot.data!.docs
              .map((doc) {
                try {
                  return Task.fromFirestore(doc);
                } catch (e) {
                  // debugPrint('Error parsing task: $e');
                  return null;
                }
              })
              .where((task) => task != null)
              .cast<Task>()
              .toList();
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isCompleted = task.isCompleted;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: isCompleted,
                        onChanged: (bool? value) {
                          FirebaseService.updateTask(task.id, {'isCompleted': value});
                          if (value == true) {
                            GamificationService.awardXP(GamificationService.xpPerTask);
                            ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Task Completed! +10 XP'),
                                 backgroundColor: Color(0xFF6C63FF),
                               ),
                            );
                          }
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: task.description.isNotEmpty
                          ? Text(task.description)
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.timer_outlined, color: Color(0xFFFFD700)),
                            onPressed: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => FocusScreen(taskTitle: task.title),
                                 ),
                               );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => FirebaseService.deleteTask(task.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }


  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No tasks yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          Text('Tap + to add your first task'),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    _titleController.clear();
    _descriptionController.clear();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      child: Text(selectedDate == null 
                        ? 'Pick Date' 
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                      child: Text(selectedTime == null 
                        ? 'Pick Time' 
                        : selectedTime!.format(context)),
                    ),
                  ),
                ],
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
                    DateTime? reminderTime;
                    if (selectedDate != null && selectedTime != null) {
                      reminderTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                    }
                    await _addTask(_titleController.text.trim(), _descriptionController.text.trim(), reminderTime);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task added successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding task: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask(String title, String description, DateTime? reminderTime) async {
    await FirebaseService.addTask({
      'title': title,
      'description': description,
      'isCompleted': false,
      'dueDate': reminderTime != null ? Timestamp.fromDate(reminderTime) : null,
    });
    
    if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
      await NotificationService.scheduleTaskReminder(title, reminderTime);
    }
  }


}