import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Add these imports 👇
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

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

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
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

  // ===========================
  // ADMIN AUTHENTICATION
  // ===========================
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

  // ===========================
  // BUS TIMETABLE (OFFLINE SUPPORT)
  // ===========================
  static Future<Map<String, dynamic>> getBusTimeTable({
    String? from,
    String? to,
    String? startTime,
    String? endTime,
    String? busType,
    String? status,
  }) async {
    final connectivityService = ConnectivityService();
    final isOnline = await connectivityService.isConnected();

    try {
      if (isOnline) {
        var url = Uri.parse('$baseUrl/bus-timetable');

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
        if (status != null && status.isNotEmpty) {
          queryParams['status'] = status;
        }

        if (queryParams.isNotEmpty) {
          url = url.replace(queryParameters: queryParams);
        }

        final response = await http
            .get(url, headers: await _getHeaders(includeAuth: true))
            .timeout(const Duration(seconds: 10));

        final result = await _handleResponse(response);

        if (result['success'] == true && result['data'] != null) {
          await DatabaseService.instance.saveBusTimetables(
            List<Map<String, dynamic>>.from(result['data']),
          );
        }

        return result;
      } else {
        final localData = await DatabaseService.instance.getBusTimetables(
          from: from,
          to: to,
          startTime: startTime,
          busType: busType,
        );

        return {
          'success': true,
          'message': 'Data loaded from offline storage',
          'data': localData.map((item) => {
                '_id': item['id'],
                'from': item['from_location'],
                'to': item['to_location'],
                'startTime': item['start_time'],
                'endTime': item['end_time'],
                'busType': item['bus_type'],
                'createdAt': item['created_at'],
                'updatedAt': item['updated_at'],
              }).toList(),
          'offline': true,
        };
      }
    } on SocketException {
      final localData = await DatabaseService.instance.getBusTimetables(
        from: from,
        to: to,
        startTime: startTime,
        busType: busType,
      );

      return {
        'success': true,
        'message': 'Cannot connect to server. Showing offline data.',
        'data': localData.map((item) => {
              '_id': item['id'],
              'from': item['from_location'],
              'to': item['to_location'],
              'startTime': item['start_time'],
              'endTime': item['end_time'],
              'busType': item['bus_type'],
              'createdAt': item['created_at'],
              'updatedAt': item['updated_at'],
            }).toList(),
        'offline': true,
      };
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
          .post(url, headers: await _getHeaders(includeAuth: true), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Cannot connect to server. Please check if the backend is running.',
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
          .put(url, headers: await _getHeaders(includeAuth: true), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Cannot connect to server. Please check if the backend is running.',
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
        message: 'Cannot connect to server. Please check if the backend is running.',
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

  // =====================
  // Review APIs
  // =====================
  
  static Future<Map<String, dynamic>> createReview({
    required String busId,
    required int rating,
    required String comment,
  }) async {
    final url = Uri.parse('$baseUrl/reviews');
    final token = await _getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'busId': busId,
        'rating': rating,
        'comment': comment,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create review');
    }
  }

  static Future<List<dynamic>> getMyReviews() async {
    final url = Uri.parse('$baseUrl/reviews/my-reviews');
    final token = await _getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch reviews');
    }
  }

  static Future<List<dynamic>> getReviewsByBus(String busId) async {
    final url = Uri.parse('$baseUrl/reviews/bus/$busId');

    final response = await http.get(url);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch reviews');
    }
  }

  static Future<List<dynamic>> getAllReviews() async {
    final url = Uri.parse('$baseUrl/reviews');
    final token = await _getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch reviews');
    }
  }

  static Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    final url = Uri.parse('$baseUrl/reviews/$reviewId');
    final token = await _getToken();

    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (comment != null) body['comment'] = comment;

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update review');
    }
  }

  static Future<void> deleteReview(String reviewId) async {
    final url = Uri.parse('$baseUrl/reviews/$reviewId');
    final token = await _getToken();

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete review');
    }
  }

  // ===========================
  // ADMIN VERIFICATION APIs
  // ===========================
  
  static Future<List<dynamic>> getUnverifiedDrivers() async {
    try {
      final url = Uri.parse('$baseUrl/admin/drivers/unverified');
      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);
      return result['data'] ?? [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch unverified drivers',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<List<dynamic>> getUnverifiedConnectors() async {
    try {
      final url = Uri.parse('$baseUrl/admin/connectors/unverified');
      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);
      return result['data'] ?? [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch unverified connectors',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<List<dynamic>> getAllDrivers() async {
    try {
      final url = Uri.parse('$baseUrl/admin/drivers');
      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);
      return result['data'] ?? [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch drivers',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<List<dynamic>> getAllConnectors() async {
    try {
      final url = Uri.parse('$baseUrl/admin/connectors');
      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);
      return result['data'] ?? [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch connectors',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> verifyDriver(String driverId) async {
    try {
      final url = Uri.parse('$baseUrl/admin/drivers/$driverId/verify');
      final response = await http
          .put(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to verify driver',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> verifyConnector(String connectorId) async {
    try {
      final url = Uri.parse('$baseUrl/admin/connectors/$connectorId/verify');
      final response = await http
          .put(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to verify connector',
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

  // ===========================
  // DRIVER SCHEDULE APIs
  // ===========================
  
  static Future<Map<String, dynamic>> getDriverSchedules() async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable/driver/my-schedules');
      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch your schedules',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> createDriverSchedule({
    required String from,
    required String to,
    required String startTime,
    required String endTime,
    required String busType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable/driver/create');
      final body = {
        'from': from,
        'to': to,
        'startTime': startTime,
        'endTime': endTime,
        'busType': busType,
      };

      final response = await http
          .post(url, headers: await _getHeaders(includeAuth: true), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to create schedule',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> updateDriverSchedule({
    required String id,
    required String from,
    required String to,
    required String startTime,
    required String endTime,
    required String busType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable/driver/$id');
      final body = {
        'from': from,
        'to': to,
        'startTime': startTime,
        'endTime': endTime,
        'busType': busType,
      };

      final response = await http
          .put(url, headers: await _getHeaders(includeAuth: true), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to update schedule',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> deleteDriverSchedule(String id) async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable/driver/$id');

      final response = await http
          .delete(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to delete schedule',
        statusCode: 0,
        errors: null,
      );
    }
  }

  // ===========================
  // ADMIN SCHEDULE APPROVAL APIs
  // ===========================
  
  static Future<Map<String, dynamic>> approveSchedule(String id) async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable/$id/approve');
      final response = await http
          .patch(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to approve schedule',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> rejectSchedule(String id, String reason) async {
    try {
      final url = Uri.parse('$baseUrl/bus-timetable/$id/reject');
      final body = {'reason': reason};

      final response = await http
          .patch(url, headers: await _getHeaders(includeAuth: true), body: json.encode(body))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to reject schedule',
        statusCode: 0,
        errors: null,
      );
    }
  }

  // ===========================
  // NOTIFICATION APIs
  // ===========================
  
  static Future<List<dynamic>> getNotifications() async {
    try {
      final url = Uri.parse('$baseUrl/notifications');
      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);
      return result['data'] ?? [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch notifications',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(String id) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/$id/read');
      final response = await http
          .patch(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to mark notification as read',
        statusCode: 0,
        errors: null,
      );
    }
  }

  static Future<int> getUnreadNotificationCount() async {
    try {
      final url = Uri.parse('$baseUrl/notifications/unread-count');
      final response = await http
          .get(url, headers: await _getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 10));

      final result = await _handleResponse(response);
      return result['data']['count'] ?? 0;
    } catch (e) {
      return 0;
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