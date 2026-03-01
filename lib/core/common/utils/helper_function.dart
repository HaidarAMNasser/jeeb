import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;

/// Notification Permission Helper
class NotificationPermissionHelper {
  NotificationPermissionHelper._();

  static const String _notificationPermissionKey =
      'notification_permission_granted';

  /// Request notification permission
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestNotificationPermission() async {
    try {
      // Check current status first
      final currentStatus = await Permission.notification.status;

      // If already granted, return true
      if (currentStatus.isGranted) {
        await _savePermissionStatus(true);
        return true;
      }

      // If permanently denied, open settings
      if (currentStatus.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      // Request permission
      final status = await Permission.notification.request();
      final isGranted = status.isGranted;

      // Store permission status
      if (isGranted) {
        await _savePermissionStatus(true);
      }

      return isGranted;
    } catch (e) {
      // If notification permission is not available, try opening settings
      try {
        await openAppSettings();
      } catch (_) {
        // Ignore errors
      }
      return false;
    }
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Get stored permission status
  static Future<bool> getStoredPermissionStatus() async {
    try {
      final sharedPrefs = await prefs.SharedPreferences.getInstance();
      return sharedPrefs.getBool(_notificationPermissionKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Save permission status to local storage
  static Future<void> _savePermissionStatus(bool granted) async {
    try {
      final sharedPrefs = await prefs.SharedPreferences.getInstance();
      await sharedPrefs.setBool(_notificationPermissionKey, granted);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Open app settings to allow user to enable notifications manually
  static Future<bool> openNotificationSettings() async {
    return await openAppSettings();
  }
}
