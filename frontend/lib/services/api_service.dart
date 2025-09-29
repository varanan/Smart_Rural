import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  // For Android emulator use: 'http://10.0.2.2:3000/api'
  // For iOS simulator use: 'http://localhost:3000/api'
  // For physical device use your computer's IP: 'http://192.168.1.xxx:3000/api'

  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
  ) async {
    try {
      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ApiException(
          message: data['message'] ?? 'Unknown error occurred',
          statusCode: response.statusCode,
          errors: data['errors'],
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to parse server response',
        statusCode: response.statusCode,
        errors: null,
      );
    }
  }

  // Admin Authentication
  static Future<Map<String, dynamic>> adminRegister({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/register');
      final body = {'name': name, 'email': email, 'password': password};

      if (phone != null && phone.isNotEmpty) {
        body['phone'] = phone;
      }

      final response = await http
          .post(url, headers: await _getHeaders(), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);

      // Store tokens
      if (result['success'] == true && result['data'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', result['data']['accessToken']);
        await prefs.setString('refresh_token', result['data']['refreshToken']);
        await prefs.setString('user_role', 'admin');
        await prefs.setString(
          'user_data',
          json.encode(result['data']['admin']),
        );
      }

      return result;
    } on SocketException {
      throw ApiException(
        message:
            'Cannot connect to server. Please check if the backend is running.',
        statusCode: 0,
        errors: null,
      );
    } on HttpException {
      throw ApiException(
        message: 'HTTP error occurred',
        statusCode: 0,
        errors: null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/login');
      final body = {'email': email, 'password': password};

      final response = await http
          .post(url, headers: await _getHeaders(), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);

      // Store tokens
      if (result['success'] == true && result['data'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', result['data']['accessToken']);
        await prefs.setString('refresh_token', result['data']['refreshToken']);
        await prefs.setString('user_role', 'admin');
        await prefs.setString(
          'user_data',
          json.encode(result['data']['admin']),
        );
      }

      return result;
    } on SocketException {
      throw ApiException(
        message:
            'Cannot connect to server. Please check if the backend is running.',
        statusCode: 0,
        errors: null,
      );
    } on HttpException {
      throw ApiException(
        message: 'HTTP error occurred',
        statusCode: 0,
        errors: null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      final url = Uri.parse('$baseUrl/admin/profile');
      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message:
            'Cannot connect to server. Please check if the backend is running.',
        statusCode: 0,
        errors: null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
        errors: null,
      );
    }
  }

  // Bus TimeTable Operations
  static Future<Map<String, dynamic>> getBusTimeTable({
    String? from,
    String? to,
    String? startTime,
    String? endTime,
    String? busType,
  }) async {
    try {
      var url = Uri.parse('$baseUrl/bus-timetable');

      // Add query parameters
      final queryParams = <String, String>{};
      if (from != null && from.isNotEmpty) queryParams['from'] = from;
      if (to != null && to.isNotEmpty) queryParams['to'] = to;
      if (startTime != null && startTime.isNotEmpty)
        queryParams['startTime'] = startTime;
      if (endTime != null && endTime.isNotEmpty)
        queryParams['endTime'] = endTime;
      if (busType != null && busType.isNotEmpty)
        queryParams['busType'] = busType;

      if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message:
            'Cannot connect to server. Please check if the backend is running.',
        statusCode: 0,
        errors: null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> createBusTimeTable({
    required String from,
    required String to,
    required String startTime,
    required String endTime,
    required String busType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable');
      final body = {
        'from': from,
        'to': to,
        'startTime': startTime,
        'endTime': endTime,
        'busType': busType,
      };

      final response = await http
          .post(
            url,
            headers: await _getHeaders(includeAuth: true),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message:
            'Cannot connect to server. Please check if the backend is running.',
        statusCode: 0,
        errors: null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> updateBusTimeTable({
    required String id,
    required String from,
    required String to,
    required String startTime,
    required String endTime,
    required String busType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable/$id');
      final body = {
        'from': from,
        'to': to,
        'startTime': startTime,
        'endTime': endTime,
        'busType': busType,
      };

      final response = await http
          .put(
            url,
            headers: await _getHeaders(includeAuth: true),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message:
            'Cannot connect to server. Please check if the backend is running.',
        statusCode: 0,
        errors: null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> deleteBusTimeTable(String id) async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable/$id');

      final response = await http
          .delete(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message:
            'Cannot connect to server. Please check if the backend is running.',
        statusCode: 0,
        errors: null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin' || role == 'super_admin';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_role');
    await prefs.remove('user_data');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<dynamic>? errors;

  ApiException({required this.message, required this.statusCode, this.errors});

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.map((e) => e['message'] ?? e.toString()).join(', ');
    }
    return message;
  }
}
