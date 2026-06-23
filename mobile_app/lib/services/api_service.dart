import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage.dart';

/// A single, shared Dio HTTP client for the whole app.
///
/// Two interceptors run on EVERY request:
///   1. X-Tenant: <saved slug>            — tells the backend which tenant this is
///   2. Authorization: Bearer <saved JWT> — authenticates the user
class ApiService {
  ApiService._internal();

  /// The one and only instance (use `ApiService.instance.dio`).
  static final ApiService instance = ApiService._internal();

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api', // e.g. https://your-api.com/api
        headers: {'Accept': 'application/json'},
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Tenant identification.
          final slug = await Storage.getSlug();
          if (slug != null && slug.isNotEmpty) {
            options.headers['X-Tenant'] = slug;
          }
          // 2. Authentication.
          final token = await Storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // If the token is rejected, drop it so the app returns to login.
          if (e.response?.statusCode == 401) {
            await Storage.clearToken();
          }
          handler.next(e);
        },
      ),
    );

    return client;
  }
}

/// Extracts a human-friendly message from an error. The Laravel API returns
/// `{ "message": "..." }` on failures.
String apiError(Object e, [String fallback = 'Something went wrong.']) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
  }
  return fallback;
}
