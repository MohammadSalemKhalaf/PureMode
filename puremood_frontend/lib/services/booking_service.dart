import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/booking.dart';
import '../config/api_config.dart';

class BookingService {
  String get baseUrl => '${ApiConfig.baseUrl}/bookings';
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

  Future<Map<String, dynamic>> createBooking({
    required int specialistId,
    required String bookingDate,
    required String startTime,
    required String endTime,
    String sessionType = 'video',
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
          Uri.parse(baseUrl),
          headers: _getHeaders(token),
          body: jsonEncode({
            'specialist_id': specialistId,
            'booking_date': bookingDate,
            'start_time': startTime,
            'end_time': endTime,
            'session_type': sessionType,
            'notes': notes,
          })
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create booking');
      }
    } catch (e) {
      print('Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  // ====== Get My Bookings ======
  Future<List<Booking>> getMyBookings() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/my-bookings'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookingsList = data['bookings'] as List;
        return bookingsList.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      print('Error getting my bookings: $e');
      throw Exception('Failed to load bookings');
    }
  }

  // ====== Get Specialist Bookings ======
  Future<List<Booking>> getSpecialistBookings(int specialistId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/specialist/$specialistId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookingsList = data['bookings'] as List;
        return bookingsList.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load specialist bookings');
      }
    } catch (e) {
      print('Error getting specialist bookings: $e');
      throw Exception('Failed to load specialist bookings');
    }
  }

  // ====== Get Single Booking ======
  Future<Booking> getBooking(int bookingId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/$bookingId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data['booking']);
      } else {
        throw Exception('Failed to load booking');
      }
    } catch (e) {
      print('Error getting booking: $e');
      throw Exception('Failed to load booking');
    }
  }

  // ====== Confirm Booking ======
  Future<Map<String, dynamic>> confirmBooking(int bookingId) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$bookingId/confirm'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to confirm booking');
      }
    } catch (e) {
      print('Error confirming booking: $e');
      throw Exception('Failed to confirm booking');
    }
  }

  // ====== Cancel Booking ======
  Future<Map<String, dynamic>> cancelBooking(int bookingId, {String? reason}) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$bookingId/cancel'),
        headers: _getHeaders(token),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      print('Error cancelling booking: $e');
      throw Exception('Failed to cancel booking');
    }
  }

  // ====== Complete Booking ======
  Future<Map<String, dynamic>> completeBooking(int bookingId) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$bookingId/complete'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to complete booking');
      }
    } catch (e) {
      print('Error completing booking: $e');
      throw Exception('Failed to complete booking');
    }
  }

  // ====== Get Available Slots ======
  Future<List<TimeSlot>> getAvailableSlots(int specialistId, String date) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/specialist/$specialistId/available-slots?date=$date'),
        headers: _getHeaders(token),
      );

      print('🔍 Slots API Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slotsList = data['availableSlots'] as List;
        print('✅ Received ${slotsList.length} slots');
        return slotsList.map((json) => TimeSlot.fromJson(json)).toList();
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load available slots');
      }
    } catch (e) {
      print('Error getting available slots: $e');
      return []; // Return empty list on error
    }
  }
}
