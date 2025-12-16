import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<void> loginUser(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await updateLastLogin();
  }

  static Future<void> registerUser(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await createUserProfile(credential.user!.uid);
  }

  static Future<void> logoutUser() async {
    await _auth.signOut();
  }

  static Future<void> createUserProfile(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': _auth.currentUser?.email,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': true,
    });
  }

  static Future<void> updateLastLogin() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }
}