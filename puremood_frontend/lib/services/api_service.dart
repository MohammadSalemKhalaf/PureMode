import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show File;

class ApiService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // ============================================================
  // BASE URL
  // ============================================================
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else {
      return 'http://10.0.2.2:5000/api';
    }
  }

  String get usersBase => '$baseUrl/users';

  // ============================================================
  // TOKEN
  // ============================================================
  Future<String?> getToken() async {
    return storage.read(key: 'jwt');
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ============================================================
  // LOGIN
  // ============================================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$usersBase/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['token'] != null) {
      await storage.write(key: 'jwt', value: body['token']);
    }

    return body;
  }

  // ============================================================
  // REGISTER
  // ============================================================
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
    int age,
    String gender, {
    Map<String, dynamic>? specialistData,
    File? certificateFile,
    String? picture,
  }) async {
    if (certificateFile != null) {
      if (kIsWeb) {
        throw Exception('Certificate upload not supported on Web');
      }

      final request =
          http.MultipartRequest('POST', Uri.parse('$usersBase/register'));

      request.fields.addAll({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'age': age.toString(),
        'gender': gender,
      });

      if (specialistData != null) {
        request.fields['specialistData'] = jsonEncode(specialistData);
      }

      if (picture != null) {
        request.fields['picture'] = picture;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'certificate_file',
          certificateFile.path,
        ),
      );

      final response =
          await http.Response.fromStream(await request.send());
      return jsonDecode(response.body);
    }

    final res = await http.post(
      Uri.parse('$usersBase/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'age': age,
        'gender': gender,
        if (specialistData != null) 'specialistData': specialistData,
        if (picture != null) 'picture': picture,
      }),
    );

    return jsonDecode(res.body);
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$usersBase/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  // ============================================================
  // USER INFO
  // ============================================================
  Future<Map<String, dynamic>?> getMe() async {
    final token = await getToken();
    if (token == null) return null;

    final res = await http.get(
      Uri.parse('$usersBase/me'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return await getMe() ?? {};
  }

  // ============================================================
  // UPDATE USER
  // ============================================================
  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$usersBase/$userId'),
      headers: _headers(token!),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  // ============================================================
  // UPLOAD PROFILE PICTURE (Mobile)
  // ============================================================
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    if (kIsWeb) {
      throw Exception('Upload not supported on Web');
    }

    final token = await getToken();

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$usersBase/me/picture'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('picture', imageFile.path),
    );

    final response =
        await http.Response.fromStream(await request.send());
    return jsonDecode(response.body);
  }

  // ============================================================
  // ADMIN
  // ============================================================
  Future<Map<String, dynamic>> getPendingUsers() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/pending'),
      headers: _headers(token!),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> approveUser(int userId) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$baseUrl/admin/approve/$userId'),
      headers: _headers(token!),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> rejectUser(int userId) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$baseUrl/admin/reject/$userId'),
      headers: _headers(token!),
    );
    return jsonDecode(res.body);
  }

  // ============================================================
  // USER MOODS ✅ (المفقودة سابقًا)
  // ============================================================
  Future<List<dynamic>> getUserMoods() async {
    final token = await getToken();
    if (token == null) return [];

    final res = await http.get(
      Uri.parse('$baseUrl/moods/user/me'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List;
    }
    return [];
  }

  // ============================================================
  // DASHBOARD
  // ============================================================
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final moods = await getUserMoods();

    return {
      "lastMoodEmoji":
          moods.isNotEmpty ? moods.first['mood_emoji'] : "🙂",
      "averageMood": 0,
      "totalMoods": moods.length,
      "dailySuggestion": "Keep tracking your mood 🌱",
    };
  }
}
