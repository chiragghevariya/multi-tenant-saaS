import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Thin wrapper around SharedPreferences for the two values we persist:
/// the tenant slug and the JWT token.
class Storage {
  static Future<void> saveSlug(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.tenantSlug, slug);
  }

  static Future<String?> getSlug() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.tenantSlug);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.token, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.token);
  }

  /// Remove only the token (keeps the slug, so we return to the login screen).
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.token);
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.themeMode, mode);
  }

  static Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.themeMode);
  }
}
