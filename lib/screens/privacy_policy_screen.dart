import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.white.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LifeFlow Privacy Commitment',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    _buildSection('100% Free & No Tracking', [
                      '• Completely free app with no premium features',
                      '• No advertisements or tracking',
                      '• No data selling or sharing with third parties',
                      '• No hidden background activities',
                    ]),
                    _buildSection('Data Storage', [
                      '• Your data is stored securely in Firebase',
                      '• Only you can access your personal information',
                      '• Data is synced across your devices only',
                      '• No data mining or analysis',
                    ]),
                    _buildSection('Permissions Explained', [
                      '• Phone: Only to make calls when you enter a number and tap call',
                      '• Camera: Only to control flashlight when you request it',
                      '• Storage: Only to access media files you want to play',
                      '• Notifications: Only to remind you of tasks and habits',
                    ]),
                    _buildSection('Your Control', [
                      '• All permissions are optional',
                      '• You can revoke any permission anytime',
                      '• App functions work even with limited permissions',
                      '• No forced permissions or locked features',
                    ]),
                    _buildSection('Transparency Promise', [
                      '• All actions require your explicit approval',
                      '• No hidden system modifications',
                      '• Open about what data we collect (minimal)',
                      '• Clear explanations for every permission request',
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Color(0xFF00E5FF).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Icon(Icons.verified_user, color: Color(0xFF00E5FF), size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Your Privacy is Our Priority',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'LifeFlow is designed to help you achieve your goals while respecting your privacy and maintaining full transparency.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(point, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}