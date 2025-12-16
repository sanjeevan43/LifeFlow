import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase connection...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Test 1: Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = '❌ No authenticated user';
          _isLoading = false;
        });
        return;
      }

      // Test 2: Try to write to Firestore
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection_test')
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'message': 'Firebase connection test successful',
      });

      // Test 3: Try to read from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('test')
          .doc('connection_test')
          .get();

      if (doc.exists) {
        setState(() {
          _status = '✅ Firebase connected successfully!\n'
              'User: ${user.email}\n'
              'UID: ${user.uid}\n'
              'Test document created and read successfully';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = '⚠️ Write successful but read failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Firebase connection failed:\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _status = 'Testing Firebase connection...';
                });
                _testFirebaseConnection();
              },
              child: const Text('Test Again'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to App'),
            ),
          ],
        ),
      ),
    );
  }
}