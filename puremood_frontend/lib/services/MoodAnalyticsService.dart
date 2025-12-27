import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MoodAnalyticsService {
  final storage = FlutterSecureStorage();
  final String baseUrl = "http://10.0.2.2:5000/api";

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<String?> getToken() async {
    return await storage.read(key: "jwt");
  }

  // 📊 Analytics
  Future<Map<String, dynamic>> fetchAnalytics(String period) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('No authentication token found. Please login first.');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/analytics/$period'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print('=== FULL ANALYTICS RESPONSE ===');
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
    print('=============================');

    if (res.statusCode == 401) {
      await storage.delete(key: "jwt");
      throw Exception('Session expired. Please login again.');
    }

    if (res.statusCode == 404) {
      return {
        'average_mood': 0.0,
        'median_mood': 0.0,
        'variance': 0.0,
        'high_days': 0,
        'low_days': 0,
        'trend': 'stable',
        'message': 'No data available',
        'has_data': false,
      };
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to fetch analytics: ${res.statusCode} - ${res.body}',
      );
    }

    final data = json.decode(res.body);
    data['has_data'] = true;

    // 🔹 Print available keys
    print('Available keys: ${data.keys.toList()}');
    if (data['analytics'] != null) {
      print('Analytics keys: ${data['analytics'].keys.toList()}');
    }

    return data;
  }

  // 🤖 AI Mood Analysis
  Future<Map<String, dynamic>> fetchAI() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('No authentication token found. Please login first.');
    }

    final res = await http.post(
      Uri.parse('$baseUrl/ai/evaluate'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print('AI Response: ${res.statusCode} - ${res.body}');

    if (res.statusCode == 401) {
      await storage.delete(key: "jwt");
      throw Exception('Session expired. Please login again.');
    }

    if (res.statusCode == 404) {
      return {
        'risk_level': 'low',
        'message': 'Start tracking your mood to get AI insights',
        'suggestion': 'Record your mood daily for personalized analysis',
        'has_data': false,
      };
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to fetch AI insights: ${res.statusCode} - ${res.body}',
      );
    }

    final data = json.decode(res.body);
    data['has_data'] = true;
    return data;
  }
}
