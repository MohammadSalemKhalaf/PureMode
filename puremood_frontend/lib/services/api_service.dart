import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000/api/users';
  final storage = FlutterSecureStorage();
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt'); // ✅ Use 'jwt' instead of 'token'
  }

  // -------------------------
  // Login
  // -------------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['token'] != null) {
      await storage.write(key: 'jwt', value: body['token']);
    }
    return body;
  }

  // -------------------------
  // Get user by ID
  // -------------------------
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final token = await storage.read(key: 'jwt');
      if (token == null) return null;

      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // -------------------------
  // Register
  // -------------------------
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
    int age,
    String gender, {
    Map<String, dynamic>? specialistData,
    dynamic certificateFile,
    String? picture,
  }) async {
    if (certificateFile != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register'),
      );

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['role'] = role;
      request.fields['age'] = age.toString();
      request.fields['gender'] = gender;

      if (specialistData != null) {
        request.fields['specialistData'] = jsonEncode(specialistData);
      }
      if (picture != null && picture.isNotEmpty) {
        request.fields['picture'] = picture;
      }

      if (certificateFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'certificate_file',
            certificateFile.path,
          ),
        );
      }

      final streamed = await request.send();
      final responseBody = await streamed.stream.bytesToString();
      return jsonDecode(responseBody);
    }

    final body = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'age': age,
      'gender': gender,
    };

    if (specialistData != null) {
      body['specialistData'] = specialistData;
    }

    if (picture != null && picture.isNotEmpty) {
      body['picture'] = picture;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  // -------------------------
  // Get user info (alias for getMe, kept for backward compatibility)
  // -------------------------
  Future<Map<String, dynamic>> getUserInfo() async {
    final me = await getMe();
    return me ?? {};
  }

  // -------------------------
  // Forgot password
  // -------------------------
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  // -------------------------
  // Get user info
  // -------------------------
  Future<Map<String, dynamic>?> getMe() async {
    final token = await storage.read(key: 'jwt');
    if (token == null) return null;

    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // -------------------------
  // Dashboard Summary (real data from backend)
  // -------------------------
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final token = await storage.read(key: 'jwt');
      if (token == null) {
        return {
          "lastMoodEmoji": "🙂",
          "lastMoodLabel": "N/A",
          "averageMood": 0,
          "totalMoods": 0,
          "dailySuggestion": "Please log in again 🌿",
        };
      }

      // Fetch latest mood from backend
      final moodRes = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/moods/user/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Fetch weekly analytics
      final analyticsRes = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/analytics/weekly'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      String lastMoodEmoji = "🙂";
      String lastMoodLabel = "Happy";
      double averageMood = 0;
      int totalMoods = 0;

      // Process mood data
      if (moodRes.statusCode == 200) {
        final moods = jsonDecode(moodRes.body) as List;
        if (moods.isNotEmpty) {
          final lastMood = moods.first;
          lastMoodEmoji = lastMood['mood_emoji'] ?? "🙂";
          lastMoodLabel = _getEmojiLabel(lastMoodEmoji);
          totalMoods = moods.length;
        }
      }

      // Process analytics data
      if (analyticsRes.statusCode == 200) {
        final analytics = jsonDecode(analyticsRes.body);
        averageMood =
            double.tryParse(analytics['average_mood']?.toString() ?? '0') ?? 0;
      }

      return {
        "lastMoodEmoji": lastMoodEmoji,
        "lastMoodLabel": lastMoodLabel,
        "averageMood": averageMood,
        "totalMoods": totalMoods,
        "dailySuggestion": _getSuggestionForMood(lastMoodEmoji),
      };
    } catch (e) {
      print('Error loading dashboard summary: $e');
      return {
        "lastMoodEmoji": "🙂",
        "lastMoodLabel": "Happy",
        "averageMood": 0,
        "totalMoods": 0,
        "dailySuggestion": "Start tracking your mood today! 🌸",
      };
    }
  }

  String _getEmojiLabel(String emoji) {
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
        return "Mood";
    }
  }

  String _getSuggestionForMood(String emoji) {
    switch (emoji) {
      case "😢":
        return "It's okay to feel down. Take a moment for self-care 💙";
      case "😔":
        return "Try some deep breathing exercises to clear your mind 🌿";
      case "😐":
        return "A walk in nature might help brighten your day 🌳";
      case "😊":
        return "Great mood! Keep up the positive energy ✨";
      case "😄":
        return "You're doing amazing! Share your joy with others 🎉";
      default:
        return "Take a deep breath and enjoy your day 🌸";
    }
  }

  // -------------------------
  // Get all user moods (for calendar)
  // -------------------------
  Future<List<dynamic>> getUserMoods() async {
    try {
      final token = await storage.read(key: 'jwt');
      if (token == null) return [];

      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/moods/user/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List;
      }
      return [];
    } catch (e) {
      print('Error fetching user moods: $e');
      return [];
    }
  }

  // Admin: fetch pending users
  Future<Map<String, dynamic>> getPendingUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load pending users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading pending users: $e');
    }
  }

  // Admin: approve a user
  Future<Map<String, dynamic>> approveUser(int userId) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/approve/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to approve user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving user: $e');
    }
  }

  // Admin: reject a user
  Future<Map<String, dynamic>> rejectUser(int userId) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/reject/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to reject user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error rejecting user: $e');
    }
  }

  // -------------------------
  // Update User (Edit Profile)
  // -------------------------
  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Unauthorized: No token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // -------------------------
  // Upload profile picture (multipart)
  // -------------------------
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('Unauthorized: No token found');
    }

    final uri = Uri.parse('$baseUrl/me/picture');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath(
      'picture',
      imageFile.path,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to upload profile picture: ${response.statusCode}');
    }
  }
}
