import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create user profile if doesn't exist
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await _createUserProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  static Future<void> _createUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email!,
      'displayName': user.displayName ?? user.email!.split('@')[0],
      'username': user.email!.split('@')[0],
      'domain': user.email!.split('@')[1],
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': false,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}