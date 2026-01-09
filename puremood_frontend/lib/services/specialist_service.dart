import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // ✅ kIsWeb

import '../models/specialist.dart';
import '../models/appointment.dart';

class SpecialistService {
  // =========================
  // BASE URL (Web + Mobile)
  // =========================
    String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://10.0.2.2:5000/api';
  }
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // =========================
  // TOKEN
  // =========================
  Future<String?> _getToken() async {
    return await storage.read(key: 'jwt');
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
    };
  }

  // =========================
  // GET ALL SPECIALISTS
  // =========================
  Future<List<Specialist>> getAllSpecialists({
    String? specialization,
    double? minRating,
    double? maxPrice,
    bool? isAvailable,
  }) async {
    try {
      final token = await _getToken();

      final queryParams = <String, String>{};
      if (specialization != null) queryParams['specialization'] = specialization;
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (isAvailable != null) {
        queryParams['isAvailable'] = isAvailable.toString();
      }

      final uri = Uri.parse('$baseUrl/specialists')
          .replace(queryParameters: queryParams);

      final res = await http.get(uri, headers: _getHeaders(token));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['specialists'] as List)
            .map((e) => Specialist.fromJson(e))
            .toList();
      }

      throw Exception('Failed to load specialists');
    } catch (e) {
      debugPrint('Error getting specialists: $e');
      return [];
    }
  }

  // =========================
  // GET SPECIALIST BY ID
  // =========================
  Future<Specialist?> getSpecialistById(int specialistId) async {
    try {
      final token = await _getToken();

      final res = await http.get(
        Uri.parse('$baseUrl/specialists/$specialistId'),
        headers: _getHeaders(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return Specialist.fromJson(data['specialist']);
      }

      throw Exception('Failed to load specialist');
    } catch (e) {
      debugPrint('Error getting specialist: $e');
      return null;
    }
  }

  // =========================
  // BOOK APPOINTMENT
  // =========================
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
      if (token == null) throw Exception('No token');

      final res = await http.post(
        Uri.parse('$baseUrl/specialists/$specialistId/book'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'appointment_date':
              appointmentDate.toIso8601String().split('T')[0],
          'start_time': startTime,
          'end_time': endTime,
          'session_type': sessionType,
          'notes': notes,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }

      throw Exception(res.body);
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      rethrow;
    }
  }

  // =========================
  // USER APPOINTMENTS
  // =========================
  Future<List<Appointment>> getUserAppointments() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      final res = await http.get(
        Uri.parse('$baseUrl/appointments/user'),
        headers: _getHeaders(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['appointments'] as List)
            .map((e) => Appointment.fromJson(e))
            .toList();
      }

      throw Exception('Failed to load appointments');
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      return [];
    }
  }

  // =========================
  // SPECIALIST BOOKINGS (Dashboard)
  // =========================
  Future<List<Appointment>> getSpecialistBookings(int specialistId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      final url = '$baseUrl/bookings/specialist/$specialistId';
      debugPrint('SpecialistService.getSpecialistBookings URL => $url (kIsWeb=$kIsWeb)');

      final res = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['bookings'] as List)
            .map((e) => Appointment.fromJson(e))
            .toList();
      }

      throw Exception('Failed to load specialist bookings');
    } catch (e) {
      debugPrint('Error getting specialist bookings: $e');
      return [];
    }
  }

  // =========================
  // CANCEL APPOINTMENT
  // =========================
  Future<bool> cancelAppointment(int appointmentId, String reason) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      final res = await http.put(
        Uri.parse('$baseUrl/appointments/$appointmentId/cancel'),
        headers: _getHeaders(token),
        body: jsonEncode({'cancellation_reason': reason}),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error canceling appointment: $e');
      return false;
    }
  }

  // =========================
  // SPECIALIST AVAILABILITY
  // =========================
  Future<List<dynamic>> getSpecialistAvailability(
    int specialistId,
    DateTime date,
  ) async {
    try {
      final token = await _getToken();

      final res = await http.get(
        Uri.parse(
          '$baseUrl/specialists/$specialistId/availability'
          '?date=${date.toIso8601String().split('T')[0]}',
        ),
        headers: _getHeaders(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['available_slots'] ?? [];
      }

      return [];
    } catch (e) {
      debugPrint('Error getting availability: $e');
      return [];
    }
  }

  // =========================
  // REVIEWS
  // =========================
  Future<bool> addReview({
    required int specialistId,
    required int rating,
    required String comment,
    int? appointmentId,
    bool isAnonymous = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      final res = await http.post(
        Uri.parse('$baseUrl/specialists/$specialistId/review'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
          'appointment_id': appointmentId,
          'is_anonymous': isAnonymous,
        }),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return false;
    }
  }

  Future<List<dynamic>> getSpecialistReviews(int specialistId) async {
    try {
      final token = await _getToken();

      final res = await http.get(
        Uri.parse('$baseUrl/specialists/$specialistId/reviews'),
        headers: _getHeaders(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['reviews'] ?? [];
      }

      return [];
    } catch (e) {
      debugPrint('Error getting reviews: $e');
      return [];
    }
  }
}
