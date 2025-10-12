import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

// -------------------------
// Shared Helper Methods
// -------------------------
Map<String, dynamic> _decode(http.Response res) {
  try {
    return jsonDecode(res.body) as Map<String, dynamic>;
  } catch (_) {
    return {'success': false, 'message': res.body};
  }
}

String? _firstError(Map<String, dynamic> body) {
  if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
    return (body['errors'] as List).first.toString();
  }
  return body['message']?.toString();
}

void _debugPrintResponse(String tag, http.Response res) {
  // ignore: avoid_print
  print('[$tag] status=${res.statusCode}, body=${res.body}');
}

// -------------------------
// DRIVER Auth API
// -------------------------
class DriverAuthApi {
  final http.Client _client;
  DriverAuthApi({http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _u('/drivers/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception(_firstError(body) ?? 'Login failed (${res.statusCode})');
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String licenseNumber,
    required String nicNumber,
    required String busNumber,
  }) async {
    final res = await _client.post(
      _u('/drivers/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'phone': phone,
        'licenseNumber': licenseNumber,
        'nicNumber': nicNumber,
        'busNumber': busNumber,
      }),
    );

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception(_firstError(body) ?? 'Signup failed (${res.statusCode})');
  }
}

// -------------------------
// PASSENGER Auth API
// -------------------------
class PassengerAuthApi {
  final http.Client _client;
  PassengerAuthApi({http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _u('/passenger/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception(_firstError(body) ?? 'Login failed (${res.statusCode})');
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    final res = await _client.post(
      _u('/passenger/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception(_firstError(body) ?? 'Signup failed (${res.statusCode})');
  }
}

// -------------------------
// CONNECTOR Auth API (class-based)
// -------------------------
class ConnectorAuthApi {
  final http.Client _client;
  ConnectorAuthApi({http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _u('/connector/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _debugPrintResponse('connectorLogin', res);

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception(_firstError(body) ?? 'Login failed (${res.statusCode})');
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
    required String licenseNumber,
    required String nicNumber,
    required String vehicleNumber,
  }) async {
    final res = await _client.post(
      _u('/connector/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'licenseNumber': licenseNumber,
        'nicNumber': nicNumber,
        'vehicleNumber': vehicleNumber,
      }),
    );
    _debugPrintResponse('connectorRegister', res);

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception(_firstError(body) ?? 'Signup failed (${res.statusCode})');
  }
}

// -------------------------
// Local Auth Storage
// -------------------------
class AuthStorage {
  static const _kAccess = 'auth_access';
  static const _kRefresh = 'auth_refresh';
  static const _kDriver = 'auth_driver';
  static const _kPassenger = 'auth_passenger';
  static const _kConnector = 'auth_connector';

  static Future<void> saveDriver({
    required String access,
    required String refresh,
    required Map<String, dynamic> driver,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
    await sp.setString(_kRefresh, refresh);
    await sp.setString(_kDriver, jsonEncode(driver));
  }

  static Future<void> savePassenger({
    required String access,
    required String refresh,
    required Map<String, dynamic> passenger,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
    await sp.setString(_kRefresh, refresh);
    await sp.setString(_kPassenger, jsonEncode(passenger));
  }

  static Future<void> saveConnector({
    required String access,
    required String refresh,
    required Map<String, dynamic> connector,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
    await sp.setString(_kRefresh, refresh);
    await sp.setString(_kConnector, jsonEncode(connector));
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAccess);
    await sp.remove(_kRefresh);
    await sp.remove(_kDriver);
    await sp.remove(_kPassenger);
    await sp.remove(_kConnector);
    
    // Also clear any additional auth-related keys that might exist
    await sp.remove('access_token');
    await sp.remove('refresh_token');
    await sp.remove('user_role');
    await sp.remove('user_data');
    await sp.remove('auth_access');
    await sp.remove('auth_refresh');
    await sp.remove('auth_passenger');
    await sp.remove('auth_driver');
    await sp.remove('auth_connector');
  }
}

// -------------------------
// Top-level connector helpers
// -------------------------

Future<Map<String, dynamic>> connectorRegister(Map<String, dynamic> data) async {
  final uri = Uri.parse('${AppConfig.baseUrl}/connector/register');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  _debugPrintResponse('connectorRegister', res);

  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception(body['message']?.toString() ?? 'Register failed (${res.statusCode})');
  } catch (_) {
    throw Exception('Register failed (${res.statusCode})');
  }
}

Future<Map<String, dynamic>> connectorLogin(String email, String password) async {
  final uri = Uri.parse('${AppConfig.baseUrl}/connector/login');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  _debugPrintResponse('connectorLogin', res);

  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception(body['message']?.toString() ?? 'Login failed (${res.statusCode})');
  } catch (_) {
    throw Exception('Login failed (${res.statusCode})');
  }
}
