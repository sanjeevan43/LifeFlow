import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_task_screen.dart';
import 'add_habit_screen.dart';
import 'water_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && mounted) {
          setState(() => _userName = doc.data()?['displayName'] ?? 'User');
        }
      } catch (e) {
        if (mounted) setState(() => _userName = 'User');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTodayScreen(),
          _buildTasksScreen(),
          _buildHabitsScreen(),
          const WaterScreen(),
          _buildProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Water'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _currentIndex < 3 ? FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddHabitScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTaskScreen()));
          }
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildTodayScreen() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final user = FirebaseAuth.instance.currentUser;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $_userName! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E3440))),
            const SizedBox(height: 8),
            Text(
              'Today is ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} 📅',
              style: const TextStyle(fontSize: 16, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today\'s Tasks ✨', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2E3440))),
StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tasks')
                      .where('userId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final docs = snapshot.data!.docs;
                    final total = docs.length;
                    final completed = docs.where((doc) => (doc.data() as Map<String, dynamic>)['completed'] == true).length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completed/$total ✓',
                        style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('userId', isEqualTo: user?.uid)
                    .where('date', isEqualTo: today)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.task_alt, size: 60, color: Color(0xFF4CAF50)),
                          ),
                          const SizedBox(height: 16),
                          const Text('No tasks for today! 😊', style: TextStyle(fontSize: 18, color: Color(0xFF2E3440), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('Tap + to add your first task and start being productive! ✨', style: TextStyle(color: Color(0xFF4CAF50)), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final task = snapshot.data!.docs[index];
                      final data = task.data() as Map<String, dynamic>;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: data['completed'] ?? false,
                            activeColor: const Color(0xFF4CAF50),
                            onChanged: (value) async {
                              await task.reference.update({'completed': value});
                            },
                          ),
                          title: Text(
                            '${(data['completed'] ?? false) ? '✅ ' : ''}${data['title'] ?? ''}',
                            style: TextStyle(
                              color: const Color(0xFF2E3440),
                              decoration: (data['completed'] ?? false) ? TextDecoration.lineThrough : null,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text('⏰ ${data['time']}${data['description'] != null && data['description'].toString().isNotEmpty ? ' - ${data['description']}' : ''}', style: const TextStyle(color: Color(0xFF4CAF50))),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await task.reference.delete();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksScreen() {
    final user = FirebaseAuth.instance.currentUser;
    
    return DefaultTabController(
      length: 4,
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              title: const Text('All Tasks 📋', style: TextStyle(color: Color(0xFF2E3440))),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              bottom: const TabBar(
                labelColor: Color(0xFF4CAF50),
                unselectedLabelColor: Color(0xFF2E3440),
                indicatorColor: Color(0xFF4CAF50),
                isScrollable: true,
                tabs: [
                  Tab(text: '📅 Daily'),
                  Tab(text: '📆 Weekly'),
                  Tab(text: '🗓️ Monthly'),
                  Tab(text: '📊 Yearly'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTaskList(user, 'daily'),
                  _buildTaskList(user, 'weekly'),
                  _buildTaskList(user, 'monthly'),
                  _buildTaskList(user, 'yearly'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(User? user, String frequency) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: user?.uid)
          .where('frequency', isEqualTo: frequency)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  frequency == 'daily' ? Icons.today :
                  frequency == 'weekly' ? Icons.date_range :
                  frequency == 'monthly' ? Icons.calendar_month :
                  Icons.calendar_today,
                  size: 60,
                  color: const Color(0xFF4CAF50).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text('No ${frequency} tasks yet! 🚀', style: const TextStyle(fontSize: 16, color: Color(0xFF2E3440))),
                const SizedBox(height: 8),
                Text('Add your first ${frequency} task to get started', style: const TextStyle(color: Color(0xFF4CAF50))),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final task = snapshot.data!.docs[index];
            final data = task.data() as Map<String, dynamic>;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ListTile(
                leading: Checkbox(
                  value: data['completed'] ?? false,
                  activeColor: const Color(0xFF4CAF50),
                  onChanged: (value) async {
                    await task.reference.update({'completed': value});
                  },
                ),
                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    color: const Color(0xFF2E3440),
                    decoration: (data['completed'] ?? false) ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📅 ${data['date']} at ⏰ ${data['time']}', style: const TextStyle(color: Color(0xFF4CAF50))),
                    if (data['description'] != null && data['description'].toString().isNotEmpty)
                      Text('📝 ${data['description']}', style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getFrequencyColor(frequency).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        frequency.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getFrequencyColor(frequency),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await task.reference.delete();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHabitsScreen() {
    final user = FirebaseAuth.instance.currentUser;
    
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: const Text('Habits 🎯', style: TextStyle(color: Color(0xFF2E3440))),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('habits')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.track_changes, size: 60, color: Color(0xFF4CAF50)),
                        ),
                        const SizedBox(height: 16),
                        const Text('No habits yet! 🌱', style: TextStyle(fontSize: 18, color: Color(0xFF2E3440), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Start building positive habits today! ✨', style: TextStyle(color: Color(0xFF4CAF50)), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final habit = snapshot.data!.docs[index];
                    final data = habit.data() as Map<String, dynamic>;
                    final today = DateTime.now().toIso8601String().split('T')[0];
                    final lastCompleted = data['lastCompleted'];
                    final isCompletedToday = lastCompleted == today;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _getCategoryColor(data['category'] ?? 'health').withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(data['category'] ?? 'health').withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () async {
                            if (!isCompletedToday) {
                              await habit.reference.update({
                                'lastCompleted': today,
                                'streak': (data['streak'] ?? 0) + 1,
                                'totalDays': (data['totalDays'] ?? 0) + 1,
                              });
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isCompletedToday 
                                ? _getCategoryColor(data['category'] ?? 'health')
                                : _getCategoryColor(data['category'] ?? 'health').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              isCompletedToday ? Icons.check : Icons.radio_button_unchecked,
                              color: isCompletedToday ? Colors.white : _getCategoryColor(data['category'] ?? 'health'),
                              size: 30,
                            ),
                          ),
                        ),
                        title: Text(
                          data['title'] ?? '',
                          style: const TextStyle(color: Color(0xFF2E3440), fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(data['category'] ?? 'health').withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getCategoryIcon(data['category'] ?? 'health'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getCategoryColor(data['category'] ?? 'health'),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('🔥 ${data['streak'] ?? 0} days', style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (data['description'] != null && data['description'].toString().isNotEmpty)
                              Text('📝 ${data['description']}', style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await habit.reference.delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  Color _getCategoryColor(String category) {
    switch (category) {
      case 'health': return const Color(0xFF4CAF50);
      case 'productivity': return const Color(0xFF2196F3);
      case 'learning': return const Color(0xFFFF9800);
      case 'mindfulness': return const Color(0xFF9C27B0);
      default: return const Color(0xFF4CAF50);
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'health': return '💪 HEALTH';
      case 'productivity': return '⚡ PRODUCTIVITY';
      case 'learning': return '📚 LEARNING';
      case 'mindfulness': return '🧘 MINDFULNESS';
      default: return '💪 HEALTH';
    }
  }

  Color _getFrequencyColor(String frequency) {
    switch (frequency) {
      case 'daily': return const Color(0xFF4CAF50);
      case 'weekly': return const Color(0xFF2196F3);
      case 'monthly': return const Color(0xFFFF9800);
      case 'yearly': return const Color(0xFF9C27B0);
      default: return const Color(0xFF4CAF50);
    }
  }

  Widget _buildProfileScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF4CAF50),
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_userName 👤', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2E3440))),
                          Text('📧 ${FirebaseAuth.instance.currentUser?.email ?? ''}', style: const TextStyle(color: Color(0xFF4CAF50))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () async => await FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out 👋'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}