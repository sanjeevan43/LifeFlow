import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

import '../services/firebase_service.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with AutomaticKeepAliveClientMixin {
  Map<String, int>? _cachedStats;
  DateTime? _lastStatsUpdate;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getUserTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading next task...'),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final tasks = snapshot.data!.docs
            .map((doc) => Task.fromFirestore(doc))
            .where((task) => !task.isCompleted && task.dueDate != null && task.dueDate!.isAfter(DateTime.now()))
            .toList();
        
        if (tasks.isEmpty) return const SizedBox.shrink();
        
        tasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
        final next = tasks.first;
        
        return Card(
          color: Colors.blue.shade50,
          child: ListTile(
            leading: Icon(Icons.schedule, color: Colors.blue.shade600),
            title: const Text('Next Task'),
            subtitle: Text(next.title),
            trailing: Text(DateFormat('MMM dd').format(next.dueDate!)),
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
    return FutureBuilder<Map<String, int>>(
      future: _getCachedStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSummaryCard(
            'Tasks', 
            'Loading...', 
            Icons.task_alt, 
            Colors.green
          );
        }
        
        final stats = snapshot.data ?? {'completedTasks': 0, 'totalTasks': 0};
        return _buildSummaryCard(
          'Tasks', 
          '${stats['completedTasks']}/${stats['totalTasks']} completed', 
          Icons.task_alt, 
          Colors.green
        );
      },
    );
  }

  Widget _buildHabitsSummary() {
    return FutureBuilder<Map<String, int>>(
      future: _getCachedStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSummaryCard(
            'Habits', 
            'Loading...', 
            Icons.trending_up, 
            Colors.orange
          );
        }
        
        final stats = snapshot.data ?? {'completedHabits': 0, 'totalHabits': 0};
        return _buildSummaryCard(
          'Habits', 
          '${stats['completedHabits']}/${stats['totalHabits']} done', 
          Icons.trending_up, 
          Colors.orange
        );
      },
    );
  }

  Widget _buildWaterSummary() {
    return FutureBuilder<Map<String, int>>(
      future: _getCachedStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSummaryCard(
            'Water', 
            'Loading...', 
            Icons.water_drop, 
            Colors.blue
          );
        }
        
        final stats = snapshot.data ?? {'waterIntake': 0};
        const goal = 8;
        return _buildSummaryCard(
          'Water', 
          '${stats['waterIntake']}/$goal glasses', 
          Icons.water_drop, 
          Colors.blue
        );
      },
    );
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

  Future<Map<String, int>> _getCachedStats() async {
    final now = DateTime.now();
    
    // Use cached data if it's less than 5 minutes old
    if (_cachedStats != null && 
        _lastStatsUpdate != null && 
        now.difference(_lastStatsUpdate!).inMinutes < 5) {
      return _cachedStats!;
    }
    
    try {
      final stats = await FirebaseService.getUserStats();
      _cachedStats = stats;
      _lastStatsUpdate = now;
      return stats;
    } catch (e) {
      return _cachedStats ?? {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalHabits': 0,
        'completedHabits': 0,
        'waterIntake': 0,
      };
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _cachedStats = null;
      _lastStatsUpdate = null;
    });
    FirebaseService.clearAllCache();
    await _getCachedStats();
    if (mounted) setState(() {});
  }
}