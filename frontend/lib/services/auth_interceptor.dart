import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor {
  static Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> authenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) requestFunc,
  ) async {
    try {
      final headers = await getAuthHeaders();
      return await requestFunc(headers);
    } catch (e) {
      rethrow;
    }
  }
}