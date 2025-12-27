import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AvailabilityService {
  String get baseUrl => '${ApiConfig.baseUrl}/availability';
  final storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await storage.read(key: 'jwt');
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
    };
  }

  // Get my availability
  Future<List<Map<String, dynamic>>> getMyAvailability() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/my-availability'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['availability'] ?? []);
      } else {
        print('getMyAvailability failed: status=${response.statusCode}, body=${response.body}');
        throw Exception('Failed to load availability');
      }
    } catch (e) {
      print('Error getting availability: $e');
      throw Exception('Failed to load availability');
    }
  }

  // Set availability for a single day
  Future<Map<String, dynamic>> setAvailability({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    bool? isAvailable,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/set'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          if (isAvailable != null) 'is_available': isAvailable,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('setAvailability failed: status=${response.statusCode}, body=${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to set availability');
        } catch (_) {
          throw Exception('Failed to set availability');
        }
      }
    } catch (e) {
      print('Error setting availability: $e');
      throw Exception('Failed to set availability: $e');
    }
  }

  // Set multiple days at once
  Future<Map<String, dynamic>> setBulkAvailability(
    List<Map<String, dynamic>> availabilities,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/bulk'),
        headers: _getHeaders(token),
        body: jsonEncode({'availabilities': availabilities}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('setBulkAvailability failed: status=${response.statusCode}, body=${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to set bulk availability');
        } catch (_) {
          throw Exception('Failed to set bulk availability');
        }
      }
    } catch (e) {
      print('Error setting bulk availability: $e');
      throw Exception('Failed to set bulk availability: $e');
    }
  }

  // Toggle availability (enable/disable)
  Future<Map<String, dynamic>> toggleAvailability(int dayOfWeek) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/toggle'),
        headers: _getHeaders(token),
        body: jsonEncode({'day_of_week': dayOfWeek}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('toggleAvailability failed: status=${response.statusCode}, body=${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to toggle availability');
        } catch (_) {
          throw Exception('Failed to toggle availability');
        }
      }
    } catch (e) {
      print('Error toggling availability: $e');
      throw Exception('Failed to toggle availability');
    }
  }

  // Delete availability
  Future<void> deleteAvailability(int dayOfWeek) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/$dayOfWeek'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        print('deleteAvailability failed: status=${response.statusCode}, body=${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to delete availability');
        } catch (_) {
          throw Exception('Failed to delete availability');
        }
      }
    } catch (e) {
      print('Error deleting availability: $e');
      throw Exception('Failed to delete availability');
    }
  }
}
