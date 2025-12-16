import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getHabitsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final habit = snapshot.data!.docs[index];
              final data = habit.data() as Map<String, dynamic>;
              
              return _buildHabitCard(habit.id, data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Stream<QuerySnapshot> _getHabitsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Widget _buildHabitCard(String habitId, Map<String, dynamic> data) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastCompleted = data['lastCompleted'];
    final isCompletedToday = lastCompleted == today;
    final streak = data['streak'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _markHabitCompleted(habitId, !isCompletedToday),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompletedToday ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isCompletedToday ? Icons.check : Icons.radio_button_unchecked,
              color: isCompletedToday ? Colors.white : Colors.grey,
            ),
          ),
        ),
        title: Text(data['title'] ?? 'Habit'),
        subtitle: Text('🔥 $streak day streak'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteHabit(habitId),
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

  Future<void> _markHabitCompleted(String habitId, bool completed) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final doc = FirebaseFirestore.instance.collection('habits').doc(habitId);
    
    if (completed) {
      await doc.update({
        'lastCompleted': today,
        'streak': FieldValue.increment(1),
      });
    }
  }

  Future<void> _deleteHabit(String habitId) async {
    await FirebaseFirestore.instance.collection('habits').doc(habitId).delete();
  }

  void _showAddHabitDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Habit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Habit name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _createHabit(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createHabit(String title) async {
    if (title.isEmpty) return;
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('habits').add({
      'title': title,
      'userId': uid,
      'streak': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}