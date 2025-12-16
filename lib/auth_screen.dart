import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await _createUserProfile(credential.user!);
      }
    } catch (e) {
      _showError(e.toString());
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createUserProfile(User user) async {
    final email = user.email!;
    final username = email.split('@')[0];
    final domain = email.split('@')[1];
    
    String displayName = username.replaceAll(RegExp(r'[0-9._-]'), ' ').trim();
    displayName = displayName.split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
    ).join(' ');
    
    if (displayName.isEmpty) displayName = username;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'displayName': displayName,
      'username': username,
      'domain': domain,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': false,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(Icons.task_alt, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(_isLogin ? 'Welcome Back! 😊' : 'Get Started! 🌟', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E3440))),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Sign in to continue your productive journey' : 'Create account to start achieving your goals',
                style: const TextStyle(fontSize: 16, color: Color(0xFF4CAF50)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF4CAF50)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF4CAF50)),
                ),
                obscureText: true,
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticate,
                  child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isLogin ? 'Sign In' : 'Create Account'),
                ),
              ),
              
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Create new account' : 'Already have account?', style: const TextStyle(color: Color(0xFF4CAF50))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}