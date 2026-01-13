import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:puremood_frontend/config/api_config.dart';

class EmailVerificationService {
  final String baseUrl = '${ApiConfig.baseUrl}/email';

  // Send verification code to email
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/send-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final body = jsonDecode(res.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to send verification code',
        };
      }
    } catch (e) {
      print('Error sending verification code: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Verify the code
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final body = jsonDecode(res.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Invalid verification code',
        };
      }
    } catch (e) {
      print('Error verifying code: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}


