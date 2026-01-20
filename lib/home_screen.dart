import 'package:flutter/material.dart';
import 'screens/today_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/water_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/device_actions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TodayScreen(),
          TasksScreen(),
          HabitsScreen(),
          WaterScreen(),
          DeviceActionsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_rounded),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_rounded),
            label: 'Water',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android_rounded),
            label: 'Device',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
