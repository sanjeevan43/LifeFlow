import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await SettingsService.getNotificationPreference();
    setState(() => _notificationsEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable reminder notifications'),
            value: _notificationsEnabled,
            onChanged: toggleNotifications,
          ),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: logout,
          ),
        ],
      ),
    );
  }

  Future<void> toggleNotifications(bool enabled) async {
    await SettingsService.toggleNotifications(enabled);
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> logout() async {
    await NotificationService.logout();
    await AuthService.logoutUser();
  }
}