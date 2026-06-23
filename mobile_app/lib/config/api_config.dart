// Central API configuration.

/// The single backend base URL. Only the X-Tenant header changes per tenant —
/// this URL stays the same for every tenant.
///
/// For local testing point this at your running Laravel server:
///   - Android emulator: http://10.0.2.2:8000   (10.0.2.2 = the host machine's localhost)
///   - iOS simulator:    http://127.0.0.1:8000
///   - Real device:      http://<your-computer-LAN-IP>:8000
const String baseUrl = 'https://your-api.com';

/// Keys used to store values in SharedPreferences.
class StorageKeys {
  static const String tenantSlug = 'tenant_slug';
  static const String token = 'auth_token';
}
