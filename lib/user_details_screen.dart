import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsScreen extends StatefulWidget {
  final User user;
  
  const UserDetailsScreen({super.key, required this.user});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Prefer not to say';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _nameController.text = data['displayName'] ?? '';
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveUserDetails() async {
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final timezoneOffset = '${offset.isNegative ? '-' : '+'}${offset.inHours.abs().toString().padLeft(2, '0')}:${(offset.inMinutes.abs() % 60).toString().padLeft(2, '0')}';
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
        'uid': widget.user.uid,
        'email': widget.user.email,
        'displayName': _nameController.text.trim(),
        'age': _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
        'gender': _selectedGender,
        'timezone': timezoneOffset,
        'profileComplete': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await widget.user.updateDisplayName(_nameController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile completed successfully! 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError('Failed to save profile: $e');
    }

    if (mounted) setState(() => _isLoading = false);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('Complete Your Profile ✨', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E3440))),
              const SizedBox(height: 8),
              const Text('Help us personalize your productive experience', style: TextStyle(fontSize: 16, color: Color(0xFF4CAF50))),
              const SizedBox(height: 32),
              
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF4CAF50)),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age (Optional)',
                  prefixIcon: Icon(Icons.cake_outlined, color: Color(0xFFFF9800)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF2E3440)),
                    items: ['Male', 'Female', 'Other', 'Prefer not to say']
                        .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedGender = value!),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We automatically detect your timezone for better reminders 🌍',
                        style: TextStyle(fontSize: 14, color: Color(0xFF4CAF50)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUserDetails,
                  child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Complete Setup 🚀'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}