import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  int _dailyGoal = 8; // 8 glasses default
  int _currentIntake = 0;
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('water_intake')
          .doc('${user.uid}_$today')
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _currentIntake = data['intake'] ?? 0;
          _dailyGoal = data['goal'] ?? 8;
          _remindersEnabled = data['reminders'] ?? true;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _addWater() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _currentIntake++);
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await FirebaseFirestore.instance
        .collection('water_intake')
        .doc('${user.uid}_$today')
        .set({
      'userId': user.uid,
      'date': today,
      'intake': _currentIntake,
      'goal': _dailyGoal,
      'reminders': _remindersEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (_currentIntake >= _dailyGoal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Daily water goal achieved! Great job!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _setupWaterReminders() async {
    if (!_remindersEnabled) return;

    // Schedule water reminders every 2 hours from 8 AM to 8 PM
    final now = DateTime.now();
    for (int hour = 8; hour <= 20; hour += 2) {
      final reminderTime = DateTime(now.year, now.month, now.day, hour, 0);
      if (reminderTime.isAfter(now)) {
        await NotificationService.scheduleTaskNotification(
          id: 'water_$hour'.hashCode,
          title: '💧 Water Reminder',
          body: 'Time to drink a glass of water! Stay hydrated!',
          scheduledTime: reminderTime,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentIntake / _dailyGoal;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Water Tracker 💧', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E3440))),
            const SizedBox(height: 8),
            Text('Stay hydrated for better health!', style: TextStyle(fontSize: 16, color: Colors.blue[600])),
            const SizedBox(height: 32),
            
            // Water Progress Circle
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue[200]!, width: 8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress > 1 ? 1 : progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.blue[100],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_currentIntake', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2E3440))),
                      Text('/ $_dailyGoal glasses', style: TextStyle(fontSize: 16, color: Colors.blue[600])),
                      Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 14, color: Colors.blue[400])),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Add Water Button
            Container(
              width: double.infinity,
              height: 80,
              child: ElevatedButton(
                onPressed: _addWater,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 32, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Add Glass 💧', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => _dailyGoal = _dailyGoal > 1 ? _dailyGoal - 1 : 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$_dailyGoal glasses', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              onPressed: () => setState(() => _dailyGoal++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Water Reminders'),
                      subtitle: const Text('Get notified every 2 hours'),
                      value: _remindersEnabled,
                      onChanged: (value) {
                        setState(() => _remindersEnabled = value);
                        if (value) {
                          _setupWaterReminders();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIntake > 0 ? () => setState(() => _currentIntake--) : null,
                    child: const Text('Remove Glass'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentIntake = 0),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Reset Day'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}