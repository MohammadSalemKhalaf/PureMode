import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/mood_models.dart';

class RecommendationService {
  final storage = FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:5000/api/recommendations';

  // 🟢 Get user's recommendations
  Future<List<Recommendation>> getMyRecommendations({
    String? moodEmoji,
    int limit = 10,
  }) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      String url = baseUrl;
      if (moodEmoji != null) {
        url += '?mood_emoji=$moodEmoji&limit=$limit';
      } else {
        url += '?limit=$limit';
      }

      print('📤 Fetching recommendations from: $url');

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Server response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<Recommendation> recommendations = (data['recommendations'] as List)
            .map((rec) => Recommendation.fromJson(rec))
            .toList();

        print('✅ Fetched ${recommendations.length} recommendations');
        return recommendations;
      } else {
        throw Exception('Failed to load recommendations: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching recommendations: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🟡 Get recommendations for a specific mood (without saving)
  Future<List<Map<String, dynamic>>> getRecommendationsByMood(
    String moodEmoji,
  ) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/mood/$moodEmoji'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Mood recommendations response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['recommendations']);
      } else {
        throw Exception(
          'Failed to load mood recommendations: ${res.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching mood recommendations: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🔵 Delete a specific recommendation
  Future<void> deleteRecommendation(int recommendationId) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/$recommendationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        print('✅ Recommendation deleted successfully');
      } else {
        throw Exception('Failed to delete recommendation: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting recommendation: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🟣 Clear all user recommendations
  Future<void> clearAllRecommendations() async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.delete(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ Cleared ${data['deletedCount']} recommendations');
      } else {
        throw Exception('Failed to clear recommendations: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error clearing recommendations: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🔄 Update recommendation status (completed or not)
  Future<Recommendation> updateRecommendationStatus(
    int recommendationId,
    bool completed,
  ) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/$recommendationId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'completed': completed}),
      );

      print('📥 Update status response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ Recommendation status updated');
        return Recommendation.fromJson(data['recommendation']);
      } else {
        throw Exception(
          'Failed to update recommendation status: ${res.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error updating recommendation status: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 📷 Upload proof image for recommendation
  Future<Recommendation> uploadProofImage(
    int recommendationId,
    String imageUrl,
  ) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/$recommendationId/proof'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'image_url': imageUrl}),
      );

      print('📥 Upload proof response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ Proof image uploaded');
        return Recommendation.fromJson(data['recommendation']);
      } else {
        throw Exception('Failed to upload proof image: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading proof image: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🎵 Get relaxing music list
  Future<List<Map<String, dynamic>>> getRelaxingMusic() async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/resources/music'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Music list response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['music']);
      } else {
        throw Exception('Failed to load music list: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching music list: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // ☕ Get warm drinks list
  Future<List<Map<String, dynamic>>> getWarmDrinks() async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/resources/drinks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Drinks list response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['drinks']);
      } else {
        throw Exception('Failed to load drinks list: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching drinks list: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🎨 Get category color
  static Map<String, dynamic> getCategoryInfo(String category) {
    switch (category) {
      case 'breathing':
        return {
          'color': 0xFF2196F3, // Blue
          'gradient': [0xFF64B5F6, 0xFF2196F3],
          'icon': '🌬️',
          'name': 'Breathing',
        };
      case 'exercise':
        return {
          'color': 0xFF4CAF50, // Green
          'gradient': [0xFF81C784, 0xFF4CAF50],
          'icon': '🏃',
          'name': 'Exercise',
        };
      case 'music':
        return {
          'color': 0xFF9C27B0, // Purple
          'gradient': [0xFFBA68C8, 0xFF9C27B0],
          'icon': '🎵',
          'name': 'Music',
        };
      case 'meditation':
        return {
          'color': 0xFF673AB7, // Deep Purple
          'gradient': [0xFF9575CD, 0xFF673AB7],
          'icon': '🧘',
          'name': 'Meditation',
        };
      case 'food':
        return {
          'color': 0xFFFF9800, // Orange
          'gradient': [0xFFFFB74D, 0xFFFF9800],
          'icon': '🍎',
          'name': 'Food & Drink',
        };
      case 'social':
        return {
          'color': 0xFFE91E63, // Pink
          'gradient': [0xFFF06292, 0xFFE91E63],
          'icon': '💬',
          'name': 'Social',
        };
      case 'reading':
        return {
          'color': 0xFF795548, // Brown
          'gradient': [0xFFA1887F, 0xFF795548],
          'icon': '📚',
          'name': 'Reading',
        };
      case 'activity':
      default:
        return {
          'color': 0xFF00897B, // Teal
          'gradient': [0xFF4DB6AC, 0xFF00897B],
          'icon': '🎯',
          'name': 'Activity',
        };
    }
  }
}
