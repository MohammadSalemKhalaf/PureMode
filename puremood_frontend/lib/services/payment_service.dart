import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class PaymentService {
  String get baseUrl => ApiConfig.baseUrl;
  final _storage = FlutterSecureStorage();

  // Create Payment Intent
  Future<Map<String, dynamic>> createPaymentIntent(int bookingId) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/payments/create-intent';
      print('🌐 Full URL: $url');
      print('🔑 Token: ${token?.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
        }),
      );

      print('📤 Create Payment Intent Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      print('❌ Error creating payment intent: $e');
      rethrow;
    }
  }

  // Confirm Payment
  Future<Map<String, dynamic>> confirmPayment(String paymentId) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('💳 Confirming payment with ID: $paymentId');

      final response = await http.post(
        Uri.parse('$baseUrl/payments/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'payment_id': int.parse(paymentId),
        }),
      );

      print('✅ Confirm Payment Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to confirm payment');
      }
    } catch (e) {
      print('❌ Error confirming payment: $e');
      rethrow;
    }
  }

  /// تأكيد الدفع بعد النجاح (للنظام الجديد)
  Future<Map<String, dynamic>> confirmPaymentSuccess({
    required int bookingId,
    required String paymentIntentId,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/confirm-payment/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'payment_intent_id': paymentIntentId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to confirm payment');
      }
    } catch (e) {
      throw Exception('Failed to confirm payment: $e');
    }
  }

  // Get Payment Details
  Future<Map<String, dynamic>> getPayment(int paymentId) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch payment');
      }
    } catch (e) {
      print('❌ Error fetching payment: $e');
      rethrow;
    }
  }

  // Get Payment History
  Future<List<dynamic>> getPaymentHistory() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/payments/history/all'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['payments'] ?? [];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch payment history');
      }
    } catch (e) {
      print('❌ Error fetching payment history: $e');
      rethrow;
    }
  }

  // Request Refund
  Future<Map<String, dynamic>> requestRefund(int paymentId, String reason) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payments/refund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'payment_id': paymentId,
          'reason': reason,
        }),
      );

      print('🔄 Refund Request Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to process refund');
      }
    } catch (e) {
      print('❌ Error requesting refund: $e');
      rethrow;
    }
  }
}
