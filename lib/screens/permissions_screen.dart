import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/device_access_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<Permission, String> _permissionDescriptions = {
    Permission.phone: 'Make phone calls directly from the app',
    Permission.camera: 'Control flashlight/torch and camera features',
    Permission.storage: 'Access device storage for media files and app data',
    Permission.notification: 'Send you reminders and notifications for tasks and habits',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Permissions'),
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
                  children: const [
                    const Text(
                      'Privacy & Transparency',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'LifeFlow respects your privacy. All permissions are optional and can be revoked anytime. We never collect, store, or share your personal data.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                      Icon(Icons.security, color: Color(0xFF00E5FF)),
                        const SizedBox(width: 8),
                        const Text('100% Free - No Ads - No Tracking', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Manage Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ..._permissionDescriptions.entries.map((entry) => _buildPermissionCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(Permission permission, String description) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getPermissionIcon(permission), color: const Color(0xFF6C63FF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getPermissionTitle(permission),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                FutureBuilder<PermissionStatus>(
                  future: permission.status,
                  builder: (context, snapshot) {
                    final isGranted = snapshot.data?.isGranted ?? false;
                    return Switch(
                      value: isGranted,
                      onChanged: (value) async {
                        if (value) {
                          await DeviceAccessService.requestPermission(permission, description);
                        } else {
                          await openAppSettings();
                        }
                        setState(() {});
                      },
                      activeColor: const Color(0xFF00E5FF),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.phone:
        return Icons.phone;
      case Permission.camera:
        return Icons.camera_alt;
      case Permission.storage:
        return Icons.storage;
      case Permission.notification:
        return Icons.notifications;
      default:
        return Icons.security;
    }
  }

  String _getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.phone:
        return 'Phone Access';
      case Permission.camera:
        return 'Camera & Flashlight';
      case Permission.storage:
        return 'Storage Access';
      case Permission.notification:
        return 'Notifications';
      default:
        return 'Permission';
    }
  }
}