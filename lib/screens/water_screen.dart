import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _getWaterStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final intake = data?['intake'] ?? 0;
          final goal = data?['goal'] ?? 8;
          
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProgressCard(intake, goal),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildGoalSetting(context, goal),
              ],
            ),
          );
        },
      ),
    );
  }

  Stream<DocumentSnapshot> _getWaterStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return FirebaseFirestore.instance
        .collection('water_intake')
        .doc('${uid}_$today')
        .snapshots();
  }

  Widget _buildProgressCard(int intake, int goal) {
    final progress = goal > 0 ? intake / goal : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '$intake / $goal',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text('glasses today'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text('${(progress * 100).toInt()}% of daily goal'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildActionButton('+1 Glass', Icons.water_drop, () => _addWater(1))),
        const SizedBox(width: 8),
        Expanded(child: _buildActionButton('+2 Glasses', Icons.water_drop, () => _addWater(2))),
        const SizedBox(width: 8),
        Expanded(child: _buildActionButton('Reset', Icons.refresh, _resetWater)),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildGoalSetting(BuildContext context, int currentGoal) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag),
        title: const Text('Daily Goal'),
        subtitle: Text('$currentGoal glasses'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showGoalDialog(context, currentGoal),
        ),
      ),
    );
  }

  Future<void> _addWater(int amount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final docRef = FirebaseFirestore.instance
        .collection('water_intake')
        .doc('${uid}_$today');

    await docRef.set({
      'userId': uid,
      'date': today,
      'intake': FieldValue.increment(amount),
      'goal': 8,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _resetWater() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await FirebaseFirestore.instance
        .collection('water_intake')
        .doc('${uid}_$today')
        .update({'intake': 0});
  }

  void _showGoalDialog(BuildContext context, int currentGoal) {
    final controller = TextEditingController(text: currentGoal.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Glasses per day',
            suffixText: 'glasses',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text) ?? 8;
              _updateGoal(newGoal);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGoal(int newGoal) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await FirebaseFirestore.instance
        .collection('water_intake')
        .doc('${uid}_$today')
        .set({
      'userId': uid,
      'date': today,
      'goal': newGoal,
      'intake': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}