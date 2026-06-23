import 'package:flutter/foundation.dart';
import '../models/tenant_user.dart';
import '../services/api_service.dart';
import '../services/storage.dart';

/// Holds authentication state: the saved tenant slug, the logged-in user,
/// and login/logout actions.
class AuthProvider extends ChangeNotifier {
  TenantUser? user;
  String? slug;
  bool loading = false;
  String? error;

  // --- Tenant slug (set on the TenantSetupScreen) ---
  Future<void> saveSlug(String value) async {
    slug = value.trim();
    await Storage.saveSlug(slug!);
    notifyListeners();
  }

  Future<String?> currentSlug() => Storage.getSlug();

  // --- Login ---
  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await ApiService.instance.dio.post('/tenant/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      await Storage.saveToken(res.data['access_token'] as String);
      user = TenantUser.fromJson(res.data['user'] as Map<String, dynamic>);
      return true;
    } catch (e) {
      error = apiError(e, 'Invalid credentials.');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Load the slug + current user (called when the Home screen opens).
  Future<void> loadProfile() async {
    slug = await Storage.getSlug();
    try {
      final res = await ApiService.instance.dio.get('/tenant/auth/me');
      user = TenantUser.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      // Token may be invalid; the interceptor clears it. UI still renders.
    }
    notifyListeners();
  }

  // --- Logout ---
  Future<void> logout() async {
    try {
      await ApiService.instance.dio.post('/tenant/auth/logout');
    } catch (_) {
      // ignore network/token errors on logout
    }
    await Storage.clearToken();
    user = null;
    notifyListeners();
  }
}
