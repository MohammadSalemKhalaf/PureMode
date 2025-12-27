import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Refund and cancellation service
class RefundService {
  final _storage = FlutterSecureStorage();
  
  /// ============================================
  /// 1. Cancel booking (with automatic refund calculation)
  /// ============================================
  Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    required String cancelledBy, // 'patient' or 'specialist'
    required String reason,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/bookings/$bookingId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cancelled_by': cancelledBy,
          'reason': reason,
        }),
      );

      print('📤 Cancel Booking Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'refund_amount': data['refund_amount'],
          'refund_percentage': data['refund_percentage'],
          'booking': data['booking'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      print('❌ Cancel Booking Error: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }
  
  /// ============================================
  /// 2. Calculate expected refund percentage
  /// ============================================
  Map<String, dynamic> calculateRefundPercentage({
    required DateTime bookingDate,
    required String cancelledBy,
  }) {
    if (cancelledBy == 'specialist') {
      return {
        'percentage': 100,
        'message': 'Full refund (100%) - Cancelled by specialist'
      };
    }
    
    // Calculate remaining time
    final now = DateTime.now();
    final hoursUntilBooking = bookingDate.difference(now).inHours;
    
    if (hoursUntilBooking >= 24) {
      return {
        'percentage': 100,
        'message': 'Full refund (100%) - Cancellation before 24 hours'
      };
    } else if (hoursUntilBooking > 0) {
      return {
        'percentage': 50,
        'message': 'Partial refund (50%) - Cancellation after 24 hours'
      };
    } else {
      return {
        'percentage': 0,
        'message': 'Cannot cancel - Booking time has passed'
      };
    }
  }
  
  /// ============================================
  /// 3. Mark patient no-show (specialist only)
  /// ============================================
  Future<Map<String, dynamic>> markNoShow({
    required int bookingId,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/bookings/$bookingId/mark-no-show'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📤 Mark No-Show Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'booking': data['booking'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to mark no-show');
      }
    } catch (e) {
      print('❌ Mark No-Show Error: $e');
      throw Exception('Failed to mark no-show: $e');
    }
  }
  
  /// ============================================
  /// 4. Get specialist payments
  /// ============================================
  Future<Map<String, dynamic>> getSpecialistPayments() async {
    try {
      final token = await _storage.read(key: 'jwt');
      
      print('🔑 Token: ${token?.substring(0, 20)}...');
      print('🌐 URL: ${ApiConfig.baseUrl}/payment/specialist/payments');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payment/specialist/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📤 Get Specialist Payments Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data['stats'],
          'bookings': data['bookings'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get payments');
      }
    } catch (e) {
      print('❌ Get Specialist Payments Error: $e');
      throw Exception('Failed to get payments: $e');
    }
  }
  
  /// ============================================
  /// 5. Get transactions history
  /// ============================================
  Future<List<dynamic>> getTransactions() async {
    try {
      final token = await _storage.read(key: 'jwt');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payment/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transactions'];
      } else {
        throw Exception('Failed to get transactions');
      }
    } catch (e) {
      print('❌ Get Transactions Error: $e');
      throw Exception('Failed to get transactions: $e');
    }
  }
  
  /// ============================================
  /// 6. Check if cancellation is allowed
  /// ============================================
  bool canCancelBooking(DateTime bookingDate) {
    final now = DateTime.now();
    return bookingDate.isAfter(now);
  }
  
  /// ============================================
  /// 7. Calculate refund amount
  /// ============================================
  double calculateRefundAmount({
    required double originalAmount,
    required int refundPercentage,
  }) {
    return (originalAmount * refundPercentage) / 100;
  }
  
  /// ============================================
  /// 8. Refund policy helper message
  /// ============================================
  String getRefundPolicyMessage(DateTime bookingDate) {
    final now = DateTime.now();
    final hoursUntilBooking = bookingDate.difference(now).inHours;
    
    if (hoursUntilBooking >= 24) {
      return '✅ You can cancel now and get a full refund (100%)';
    } else if (hoursUntilBooking > 0) {
      return '⚠️ Cancelling now will refund 50% (after 24 hours)';
    } else {
      return '❌ Cannot cancel - Booking time has passed';
    }
  }
}
