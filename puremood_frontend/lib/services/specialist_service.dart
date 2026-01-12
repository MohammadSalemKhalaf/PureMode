import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/specialist.dart';
import '../models/appointment.dart';

class SpecialistService {
  final String baseUrl = 'http://10.0.2.2:5000/api/specialists';
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

  Future<List<dynamic>> getPatientMoodEntries(int patientId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/patients/$patientId/moods'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['entries'] ?? [];
      }

      if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Not allowed');
      }

      throw Exception('Failed to load mood entries');
    } catch (e) {
      print('Error loading patient mood entries: $e');
      rethrow;
    }
  }

  // ====== Get all specialists with filters ======
  Future<List<Specialist>> getAllSpecialists({
    String? specialization,
    double? minRating,
    double? maxPrice,
    bool? isAvailable,
  }) async {
    try {
      final token = await _getToken();

      // Build query parameters
      Map<String, String> queryParams = {};
      if (specialization != null)
        queryParams['specialization'] = specialization;
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (isAvailable != null)
        queryParams['isAvailable'] = isAvailable.toString();

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['specialists'] as List)
            .map((json) => Specialist.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load specialists');
      }
    } catch (e) {
      print('Error getting specialists: $e');
      return [];
    }
  }

  // ====== Get specialist by ID ======
  Future<Specialist?> getSpecialistById(int specialistId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/$specialistId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Specialist.fromJson(data['specialist']);
      } else {
        throw Exception('Failed to load specialist details');
      }
    } catch (e) {
      print('Error getting specialist details: $e');
      return null;
    }
  }

  // ====== Get recommended specialists based on assessment ======
  Future<Map<String, dynamic>> getRecommendedSpecialists(
    int assessmentResultId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/recommendations/$assessmentResultId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'assessment': data['assessment'],
          'recommendations': (data['recommendations'] as List)
              .map((json) => Specialist.fromJson(json))
              .toList(),
        };
      } else {
        throw Exception('Failed to get recommendations');
      }
    } catch (e) {
      print('Error getting recommendations: $e');
      rethrow;
    }
  }

  // ====== Book appointment ======
  Future<Map<String, dynamic>> bookAppointment({
    required int specialistId,
    required DateTime appointmentDate,
    required String startTime,
    required String endTime,
    required String sessionType,
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/$specialistId/book'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'appointment_date': appointmentDate.toIso8601String().split('T')[0],
          'start_time': startTime,
          'end_time': endTime,
          'session_type': sessionType,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to book appointment: ${response.body}');
      }
    } catch (e) {
      print('Error booking appointment: $e');
      rethrow;
    }
  }

  // ====== Get user appointments ======
  Future<List<Appointment>> getUserAppointments() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/user/appointments'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['appointments'] as List)
            .map((json) => Appointment.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      print('Error getting appointments: $e');
      return [];
    }
  }

  // ====== Cancel appointment ======
  Future<bool> cancelAppointment(int appointmentId, String reason) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.put(
        Uri.parse('$baseUrl/appointments/$appointmentId/cancel'),
        headers: _getHeaders(token),
        body: jsonEncode({'cancellation_reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling appointment: $e');
      return false;
    }
  }

  // ====== Share assessment with specialist ======
  Future<bool> shareAssessmentWithSpecialist({
    required int appointmentId,
    required int assessmentResultId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/share-assessment'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'appointment_id': appointmentId,
          'assessment_result_id': assessmentResultId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sharing assessment: $e');
      return false;
    }
  }

  // ====== Get specialist availability ======
  Future<List<dynamic>> getSpecialistAvailability(
    int specialistId,
    DateTime date,
  ) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/$specialistId/availability?date=${date.toIso8601String().split('T')[0]}',
        ),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available_slots'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting availability: $e');
      return [];
    }
  }

  // ====== Add review ======
  Future<bool> addReview({
    required int specialistId,
    required int rating,
    required String comment,
    int? appointmentId,
    bool isAnonymous = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/$specialistId/review'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
          'appointment_id': appointmentId,
          'is_anonymous': isAnonymous,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  // ====== Get specialist reviews ======
  Future<List<dynamic>> getSpecialistReviews(int specialistId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/$specialistId/reviews'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reviews'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }
}
