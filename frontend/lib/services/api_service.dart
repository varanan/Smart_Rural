import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/config.dart';

class ApiService {
  // Use dynamic base URL that adapts per platform (web, iOS, Android, desktop)
  static String get baseUrl => AppConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = false,
    bool includeJsonContentType = true,
  }) async {
    final headers = <String, String>{};
    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      // Check both possible token storage keys
      String? token = prefs.getString('access_token') ?? prefs.getString('auth_access');
      print('[ApiService] Retrieved token: ${token != null ? "Token found (${token.substring(0, 20)}...)" : "No token found"}');
      print('[ApiService] Available keys in SharedPreferences: ${prefs.getKeys()}');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('[ApiService] Authorization header set');
      } else {
        print('[ApiService] No token available for authorization');
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

  // Helper method to handle token refresh for authenticated requests
  static Future<Map<String, dynamic>> _makeAuthenticatedRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      final result = await _handleResponse(response);
      return result;
    } on ApiException catch (e) {
      // If we get a 401 error, try to refresh the token and retry once
      if (e.statusCode == 401) {
        try {
          print('[ApiService] Token expired, attempting refresh...');
          await refreshToken();
          print('[ApiService] Token refreshed, retrying request...');
          final response = await request();
          return await _handleResponse(response);
        } catch (refreshError) {
          print('[ApiService] Token refresh failed: $refreshError');
          // If refresh fails, clear tokens and redirect to login
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('access_token');
          await prefs.remove('refresh_token');
          await prefs.remove('user_role');
          await prefs.remove('user_data');
          rethrow; // Re-throw the original 401 error
        }
      }
      rethrow;
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

  // Passenger Login
  static Future<Map<String, dynamic>> passengerLogin({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/passenger/login');
      final body = {'email': email, 'password': password};

      final response = await http
          .post(url, headers: await _getHeaders(), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);

      // Store tokens
      if (result['success'] == true && result['data'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', result['data']['tokens']['access']);
        await prefs.setString('refresh_token', result['data']['tokens']['refresh']);
        await prefs.setString('user_role', 'passenger');
        await prefs.setString(
          'user_data',
          json.encode(result['data']['passenger']),
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
      // Public endpoint: do NOT include auth; SharedPreferences access on web can add latency.
      final headers = await _getHeaders(includeAuth: false, includeJsonContentType: false);
      // Debug (safe): log URL only to console for troubleshooting
      // ignore: avoid_print
      print('[ApiService] GET $url');
      final response = await http
          .get(url, headers: headers)
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
      if (startTime != null && startTime.isNotEmpty) {
        queryParams['startTime'] = startTime;
      }
      if (endTime != null && endTime.isNotEmpty) {
        queryParams['endTime'] = endTime;
      }
      if (busType != null && busType.isNotEmpty) {
        queryParams['busType'] = busType;
      }

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

  // Booking endpoints
  static Future<Map<String, dynamic>> getSeatAvailability({
    required String timetableId,
    required String journeyDate,
  }) async {
    print('[ApiService] GET $baseUrl/bookings/seat-availability');
    
    final uri = Uri.parse('$baseUrl/bookings/seat-availability').replace(
      queryParameters: {
        'timetableId': timetableId,
        'journeyDate': journeyDate,
      },
    );

    final response = await http.get(uri);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createBooking({
    required String timetableId,
    required List<String> seatNumbers,
    required String journeyDate,
    required double totalAmount,
  }) async {
    print('[ApiService] POST $baseUrl/bookings');
    
    return await _makeAuthenticatedRequest(() async {
      final headers = await _getHeaders(includeAuth: true);
      final body = jsonEncode({
        'timetableId': timetableId,
        'seatNumbers': seatNumbers,
        'journeyDate': journeyDate,
        'totalAmount': totalAmount,
      });

      return await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: body,
      );
    });
  }

  static Future<Map<String, dynamic>> getMyBookings({
    String? bookingStatus,
    String? paymentStatus,
    int page = 1,
    int limit = 10,
  }) async {
    print('[ApiService] GET $baseUrl/bookings/my-bookings');
    
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      't': DateTime.now().millisecondsSinceEpoch.toString(), // Cache busting
    };

    if (bookingStatus != null) queryParams['bookingStatus'] = bookingStatus;
    if (paymentStatus != null) queryParams['paymentStatus'] = paymentStatus;

    final uri = Uri.parse('$baseUrl/bookings/my-bookings').replace(
      queryParameters: queryParams,
    );

    return await _makeAuthenticatedRequest(() async {
      final headers = await _getHeaders(includeAuth: true);
      print('[ApiService] Headers for getMyBookings: $headers');
      return await http.get(uri, headers: headers);
    });
  }

  static Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    print('[ApiService] GET $baseUrl/bookings/$bookingId');
    
    return await _makeAuthenticatedRequest(() async {
      final headers = await _getHeaders(includeAuth: true);
      return await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: headers,
      );
    });
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    print('[ApiService] DELETE $baseUrl/bookings/$bookingId');
    
    return await _makeAuthenticatedRequest(() async {
      final headers = await _getHeaders(includeAuth: true);
      return await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: headers,
      );
    });
  }

  static Future<Map<String, dynamic>> processPayment({
    required String bookingId,
    required String paymentMethod,
    required String cardNumber,
  }) async {
    print('[ApiService] POST $baseUrl/bookings/$bookingId/payment');
    
    return await _makeAuthenticatedRequest(() async {
      final headers = await _getHeaders(includeAuth: true);
      final body = jsonEncode({
        'paymentMethod': paymentMethod,
        'cardNumber': cardNumber,
      });

      return await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/payment'),
        headers: headers,
        body: body,
      );
    });
  }

  static Future<Map<String, dynamic>> getPaymentByBookingId(String bookingId) async {
    print('[ApiService] GET $baseUrl/bookings/$bookingId/payment');
    
    return await _makeAuthenticatedRequest(() async {
      final headers = await _getHeaders(includeAuth: true);
      return await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId/payment'),
        headers: headers,
      );
    });
  }

  // Pricing endpoints
  static Future<Map<String, dynamic>> getPriceEstimation({
    required String from,
    required String to,
    required String busType,
    required String journeyDate,
    int seatCount = 1,
  }) async {
    print('[ApiService] GET $baseUrl/pricing/estimate');

    final uri = Uri.parse('$baseUrl/pricing/estimate').replace(
      queryParameters: {
        'from': from,
        'to': to,
        'busType': busType,
        'journeyDate': journeyDate,
        'seatCount': seatCount.toString(),
      },
    );

    final response = await http.get(uri);
    return _handleResponse(response);
  }

    static Future<Map<String, dynamic>> getRoutes({
    String? from,
    String? to,
  }) async {
    print('[ApiService] GET $baseUrl/pricing/routes');

    final queryParams = <String, String>{};
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    final uri = Uri.parse('$baseUrl/pricing/routes').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri);
    return _handleResponse(response);
  }

  // Token refresh endpoint
  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) {
        throw ApiException(
          message: 'No refresh token available',
          statusCode: 401,
          errors: null,
        );
      }

      final url = Uri.parse('$baseUrl/auth/refresh');
      final body = {'refreshToken': refreshToken};

      final response = await http
          .post(url, headers: await _getHeaders(), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);

      // Store new access token
      if (result['success'] == true && result['data'] != null) {
        await prefs.setString('access_token', result['data']['accessToken']);
      }

      return result;
    } on SocketException {
      throw ApiException(
        message: 'Cannot connect to server. Please check if the backend is running.',
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
        message: 'Token refresh failed: ${e.toString()}',
        statusCode: 0,
        errors: null,
      );
    }
  }

  // Logout endpoint - clears all stored authentication data
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all authentication-related data
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_role');
      await prefs.remove('user_data');
      await prefs.remove('auth_access');
      await prefs.remove('auth_refresh');
      await prefs.remove('auth_passenger');
      await prefs.remove('auth_driver');
      await prefs.remove('auth_connector');
      
      print('[ApiService] All authentication data cleared');
    } catch (e) {
      print('[ApiService] Error during logout: $e');
      // Don't throw error during logout - we want to clear data even if there's an issue
    }
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
