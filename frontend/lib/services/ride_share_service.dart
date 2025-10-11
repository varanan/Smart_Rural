import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config.dart';
import 'package:frontend/models/ride_share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideShareService {
  static final RideShareService _instance = RideShareService._internal();
  factory RideShareService() => _instance;
  RideShareService._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<RideShare>> getAllRideShares() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/ride-share'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((ride) => RideShare.fromJson(ride))
            .toList();
      }
      throw Exception('Failed to load ride shares');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<RideShare> createRideShare(Map<String, dynamic> rideData) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/ride-share'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(rideData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return RideShare.fromJson(data['data']);
      }
      throw Exception('Failed to create ride share');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<RideShare>> getConnectorRides() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/ride-share/connector'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((ride) => RideShare.fromJson(ride))
            .toList();
      }
      throw Exception('Failed to load connector rides');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<RideShare> updateRideStatus(String rideId, bool isActive) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/ride-share/$rideId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'isActive': isActive}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RideShare.fromJson(data['data']);
      }
      throw Exception('Failed to update ride status');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<RideShare> requestRide(String rideId, String passengerId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/ride-share/request'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'rideId': rideId,
          'passengerId': passengerId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RideShare.fromJson(data['data']);
      }
      throw Exception('Failed to request ride');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<RideShare> respondToRequest(
    String rideId,
    String requestId,
    String status,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/ride-share/$rideId/respond'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'requestId': requestId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RideShare.fromJson(data['data']);
      }
      throw Exception('Failed to respond to request');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<RideShare>> getPassengerRides(String passengerId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/ride-share/passenger?passengerId=$passengerId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((ride) => RideShare.fromJson(ride))
            .toList();
      }
      throw Exception('Failed to load passenger rides');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}