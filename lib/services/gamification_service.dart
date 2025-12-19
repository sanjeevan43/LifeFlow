import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // XP Constants
  static const int xpPerTask = 10;
  static const int xpPerHabit = 20;

  static Future<void> awardXP(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final currentXP = (snapshot.data()?['xp'] as int?) ?? 0;
      final newXP = currentXP + amount;
      
      transaction.update(userRef, {'xp': newXP});
    });
  }

  static int getLevel(int xp) {
    // Simple formula: Level = sqrt(xp) / 5
    // XP: 0 -> Lvl 0
    // XP: 100 -> Lvl 2
    // XP: 400 -> Lvl 4
    if (xp == 0) return 1;
    return (xp / 100).floor() + 1;
  }
}
