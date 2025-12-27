import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class RatingService {
  String get baseUrl => ApiConfig.baseUrl;
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> rateSpecialist(int specialistId, double rating) async {
    try {
      final token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ratings/rate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'specialist_id': specialistId,
          'rating': rating,
        }),
      );

      print('📊 Rating response: ${response.statusCode}');
      print('📊 Rating body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit rating: ${response.body}');
      }
    } catch (e) {
      print('❌ Error rating specialist: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSpecialistRating(int specialistId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/$specialistId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get rating');
      }
    } catch (e) {
      print('❌ Error getting rating: $e');
      rethrow;
    }
  }
}
