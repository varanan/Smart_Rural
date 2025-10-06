import 'package:shared_preferences/shared_preferences.dart';

class OfflineAuthService {
  static const String _keyOfflineMode = 'offline_mode';
  static const String _keyLastUserRole = 'last_user_role';

  // Check if user has previously logged in
  static Future<bool> hasLoggedInBefore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }

  // Enable offline mode
  static Future<void> enableOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, true);
  }

  // Check if in offline mode
  static Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOfflineMode) ?? false;
  }

  // Disable offline mode (when user logs in)
  static Future<void> disableOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOfflineMode);
  }

  // Check if user can access offline data
  static Future<bool> canAccessOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    // User can access offline if they're in offline mode OR have cached data
    final hasCache = await _hasCachedData();
    return hasCache;
  }

  static Future<bool> _hasCachedData() async {
    // This will be checked via DatabaseService
    return true; // For now, always allow offline access to public schedules
  }
}