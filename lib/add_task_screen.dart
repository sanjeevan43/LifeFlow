import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _frequency = 'daily';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter task title'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final taskRef = await FirebaseFirestore.instance.collection('tasks').add({
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'frequency': _frequency,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      // Schedule notification
      final now = DateTime.now();
      final notificationTime = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
      
      await NotificationService.scheduleTaskNotification(
        id: taskRef.id.hashCode,
        title: 'Task Reminder: ${_titleController.text.trim()}',
        body: _descriptionController.text.isNotEmpty ? _descriptionController.text.trim() : 'Time to complete your task!',
        scheduledTime: notificationTime.isAfter(now) ? notificationTime : notificationTime.add(const Duration(days: 1)),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_frequency.toUpperCase()} task added successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Add Task ✨', style: TextStyle(color: Color(0xFF2E3440))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4CAF50)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                prefixIcon: Icon(Icons.task_alt, color: Color(0xFF4CAF50)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.description, color: Color(0xFFFF9800)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Task Frequency 🔄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E3440))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFrequencyChip('daily', '📅 Daily'),
                        _buildFrequencyChip('weekly', '📆 Weekly'),
                        _buildFrequencyChip('monthly', '🗓️ Monthly'),
                        _buildFrequencyChip('yearly', '📊 Yearly'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                title: const Text('Reminder Time ⏰', style: TextStyle(color: Color(0xFF2E3440))),
                subtitle: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFF4CAF50))),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: _selectedTime);
                  if (time != null) setState(() => _selectedTime = time);
                },
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTask,
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Task 🚀'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyChip(String value, String label) {
    final isSelected = _frequency == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _frequency = value),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
      checkmarkColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF2E3440),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}