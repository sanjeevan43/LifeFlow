import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import '../add_reminder_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildNextReminderCard(),
            const SizedBox(height: 16),
            _buildTodaysSummary(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddReminderScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${_getGreeting()}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, MMMM dd').format(DateTime.now()),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextReminderCard() {
    return StreamBuilder<List<Reminder>>(
      stream: ReminderService.getReminders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final upcoming = snapshot.data!
            .where((r) => !r.isDone && r.remindAt.isAfter(DateTime.now()))
            .toList();
        
        if (upcoming.isEmpty) return const SizedBox.shrink();
        
        final next = upcoming.first;
        
        return Card(
          color: Colors.blue.shade50,
          child: ListTile(
            leading: Icon(Icons.schedule, color: Colors.blue.shade600),
            title: const Text('Next Reminder'),
            subtitle: Text(next.title),
            trailing: Text(DateFormat('HH:mm').format(next.remindAt)),
          ),
        );
      },
    );
  }

  Widget _buildTodaysSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildTasksSummary(),
        _buildHabitsSummary(),
        _buildWaterSummary(),
      ],
    );
  }

  Widget _buildTasksSummary() {
    return StreamBuilder<List<Reminder>>(
      stream: ReminderService.getReminders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final today = DateTime.now().toIso8601String().split('T')[0];
        final todayTasks = snapshot.data!.where((r) => 
          r.remindAt.toIso8601String().split('T')[0] == today
        ).toList();
        
        final completed = todayTasks.where((t) => t.isDone).length;
        final total = todayTasks.length;
        
        return _buildSummaryCard(
          'Tasks', 
          '$completed/$total completed', 
          Icons.task_alt, 
          Colors.green
        );
      },
    );
  }

  Widget _buildHabitsSummary() {
    return StreamBuilder(
      stream: _getHabitsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final habits = snapshot.data!.docs;
        final today = DateTime.now().toIso8601String().split('T')[0];
        final completed = habits.where((h) => 
          (h.data() as Map)['lastCompleted'] == today
        ).length;
        
        return _buildSummaryCard(
          'Habits', 
          '$completed/${habits.length} done', 
          Icons.trending_up, 
          Colors.orange
        );
      },
    );
  }

  Widget _buildWaterSummary() {
    return StreamBuilder(
      stream: _getWaterStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final intake = data?['intake'] ?? 0;
        final goal = data?['goal'] ?? 8;
        
        return _buildSummaryCard(
          'Water', 
          '$intake/$goal glasses', 
          Icons.water_drop, 
          Colors.blue
        );
      },
    );
  }

  Stream _getHabitsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Stream _getWaterStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return FirebaseFirestore.instance
        .collection('water_intake')
        .doc('${uid}_$today')
        .snapshots();
  }

  Widget _buildSummaryCard(String title, String progress, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(progress),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToScreen(title),
      ),
    );
  }

  void _navigateToScreen(String screenName) {
    // This would typically use a navigation controller or callback
    // For now, we'll show a snackbar as the screens are in bottom navigation
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}