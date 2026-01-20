import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:installed_apps/installed_apps.dart';

class DeviceAccessService {
  // Permission status tracking
  static final Map<String, bool> _permissions = {};

  // Check and request permissions with user explanation
  static Future<bool> requestPermission(Permission permission, String reason) async {
    // Skip permission requests on web
    if (kIsWeb) {
      return true; // Assume granted on web
    }
    
    final status = await permission.status;
    
    if (status.isGranted) {
      _permissions[permission.toString()] = true;
      return true;
    }

    if (status.isDenied) {
      final result = await permission.request();
      _permissions[permission.toString()] = result.isGranted;
      return result.isGranted;
    }

    return false;
  }

  // Phone Actions
  static Future<bool> makePhoneCall(String phoneNumber) async {
    if (await requestPermission(Permission.phone, "Make phone calls to contacts")) {
      final uri = Uri.parse('tel:$phoneNumber');
      return await launchUrl(uri);
    }
    return false;
  }

  // Torch/Flashlight Control (Simplified)
  static Future<bool> toggleTorch() async {
    // Note: Torch functionality removed due to compatibility issues
    // Users can use device quick settings for flashlight
    return false;
  }

  // App Launcher
  static Future<bool> openApp(String packageName) async {
    try {
      final result = await InstalledApps.startApp(packageName);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    // Not supported on web
    if (kIsWeb) {
      return [];
    }
    
    try {
      final apps = await InstalledApps.getInstalledApps(false, true);
      return apps.map((app) => {
        'name': app.name,
        'packageName': app.packageName,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // URL/Browser Actions
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // System Settings
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  // Storage Access
  static Future<bool> requestStorageAccess() async {
    return await requestPermission(Permission.storage, "Access device storage for media files");
  }

  // Check permission status
  static bool hasPermission(String permission) {
    return _permissions[permission] ?? false;
  }

  // Get all permission statuses
  static Map<String, bool> getAllPermissions() {
    return Map.from(_permissions);
  }
}