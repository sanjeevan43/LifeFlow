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
    final displayName = user.displayName ?? email.split('@')[0];
    final username = email.split('@')[0];
    final domain = email.split('@')[1];

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'displayName': displayName,
      'username': username,
      'domain': domain,
      'photoURL': user.photoURL,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.task_alt, size: 60, color: Color(0xFF00E5FF)),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Get Started!', 
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLogin ? 'Sign in to continue your journey' : 'Create account to start achieving goals',
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00E5FF)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00E5FF)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                    obscureText: true,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFF6C63FF).withOpacity(0.5),
                      ),
                      child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'Create new account' : 'Already have an account?', 
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}