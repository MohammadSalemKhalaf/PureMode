import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MoodService {
  final storage = FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:5000/api/moods';

  // 🟢 Add new mood - Enhanced version
  Future<Map<String, dynamic>> addMoodEntry(
    String emoji,
    String noteText,
    String? noteAudio,
  ) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Extract mood label and tags
    String moodLabel = _getMoodLabelFromEmoji(emoji);
    List<String> tags = _extractTagsFromNote(noteText);

    print('📤 Sending mood data to server...');
    print('   Emoji: $emoji');
    print('   Mood Label: $moodLabel');
    print('   Note: $noteText');
    print('   Tags: $tags');

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mood_emoji': emoji,
          'mood_label': moodLabel,
          'note_text': noteText,
          'note_audio': noteAudio,
          'tags': tags,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      print('📥 Server response: ${res.statusCode}');
      print('📦 Response content: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final responseData = jsonDecode(res.body);
        print('✅ Mood saved successfully: ${responseData['message']}');

        // Save locally for suggestions
        await _saveMoodToLocal({
          'emoji': emoji,
          'moodLabel': moodLabel,
          'note': noteText,
          'tags': tags,
          'timestamp': DateTime.now(),
        });

        return responseData;
      } else {
        throw Exception('Failed to save mood: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('❌ Connection error: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Helper: Get mood label from emoji
  String _getMoodLabelFromEmoji(String emoji) {
    switch (emoji) {
      case "😢":
        return "Sad";
      case "😔":
        return "Confused";
      case "😐":
        return "Neutral";
      case "😊":
        return "Happy";
      case "😄":
        return "Excited";
      default:
        return "Neutral";
    }
  }

  // Helper: Extract tags from note
  List<String> _extractTagsFromNote(String note) {
    List<String> tags = [];
    List<String> keywords = [
      'sleep',
      'tired',
      'work',
      'pressure',
      'happy',
      'joy',
      'sad',
      'anxious',
      'relax',
      'problems',
      'family',
      'friends',
      'study',
      'university',
      'school',
      'future',
      'money',
      'health',
      'sports',
      'walk',
      'music',
      'songs',
      'movie',
      'book',
      'reading',
      'writing',
      'meditation',
      'yoga',
      'breathing',
      'relaxation',
    ];

    String lowerNote = note.toLowerCase();
    for (String keyword in keywords) {
      if (lowerNote.contains(keyword)) {
        tags.add(keyword);
      }
    }
    return tags;
  }

  // Save mood locally for suggestions
  Future<void> _saveMoodToLocal(Map<String, dynamic> moodData) async {
    try {
      List<Map<String, dynamic>> history = await getMoodHistory();
      history.add(moodData);

      // Keep only last 30 days
      if (history.length > 30) {
        history = history.sublist(history.length - 30);
      }

      await storage.write(key: 'mood_history', value: jsonEncode(history));
    } catch (e) {
      print('❌ Error saving mood locally: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeMoodFromImage(File imageFile) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('$baseUrl/analyze-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Image mood response: ${response.statusCode}');
      print('📦 Image mood body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to analyze image mood: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error while analyzing image mood: $e');
      throw Exception('Failed to analyze image mood: $e');
    }
  }

  // Get mood history for suggestions
  Future<List<Map<String, dynamic>>> getMoodHistory() async {
    try {
      final historyString = await storage.read(key: 'mood_history');
      if (historyString != null) {
        List<dynamic> data = jsonDecode(historyString);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ Error reading mood history: $e');
    }
    return [];
  }

  // 🟡 Get current user's mood entries
  Future<List<dynamic>> getMyMoodEntries() async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/user/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to fetch mood entries: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching moods: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🟡 Get mood entries for specific user
  Future<List<dynamic>> getMoodEntriesByUser(String userId) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to fetch mood entries: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching moods: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🔵 Delete specific mood entry
  Future<void> deleteMood(String moodId) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/$moodId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        print('✅ Mood deleted successfully');
      } else {
        throw Exception('Failed to delete mood: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting mood: $e');
      throw Exception('Connection failed: $e');
    }
  }

  // 🔍 Check server connection
  Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/'));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Cannot connect to server: $e');
      return false;
    }
  }
}
