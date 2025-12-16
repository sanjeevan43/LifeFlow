import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';

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
        _buildSummaryCard('Tasks', '3/5 completed', Icons.task_alt, Colors.green),
        _buildSummaryCard('Habits', '2/4 done', Icons.trending_up, Colors.orange),
        _buildSummaryCard('Water', '6/8 glasses', Icons.water_drop, Colors.blue),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String progress, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(progress),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}