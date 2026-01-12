import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminService {
  final String baseUrl = 'http://10.0.2.2:5000/api/admin';
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

  // ====== Get Dashboard Stats ======
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load stats: ${response.body}');
      }
    } catch (e) {
      print('Error getting dashboard stats: $e');
      throw Exception('Failed to load stats');
    }
  }

  // ====== Get All Specialists ======
  Future<List<dynamic>> getAllSpecialists() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/specialists'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['specialists'] ?? [];
      } else {
        throw Exception('Failed to load specialists');
      }
    } catch (e) {
      print('Error getting specialists: $e');
      throw Exception('Failed to load specialists');
    }
  }

  // ====== Get Pending Specialists ======
  Future<List<dynamic>> getPendingSpecialists() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/specialists/pending'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['specialists'] ?? [];
      } else {
        throw Exception('Failed to load pending specialists');
      }
    } catch (e) {
      print('Error getting pending specialists: $e');
      throw Exception('Failed to load pending specialists');
    }
  }

  // ====== Approve Specialist ======
  Future<Map<String, dynamic>> approveSpecialist(int specialistId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/specialists/$specialistId/approve'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to approve specialist');
      }
    } catch (e) {
      print('Error approving specialist: $e');
      throw Exception('Failed to approve specialist');
    }
  }

  // ====== Reject Specialist ======
  Future<Map<String, dynamic>> rejectSpecialist(
    int specialistId, {
    String? reason,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/specialists/$specialistId/reject'),
        headers: _getHeaders(token),
        body: jsonEncode({'reason': reason ?? 'No reason provided'}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to reject specialist');
      }
    } catch (e) {
      print('Error rejecting specialist: $e');
      throw Exception('Failed to reject specialist');
    }
  }

  // ====== Get Notifications ======
  Future<List<dynamic>> getNotifications({int? limit}) async {
    try {
      final token = await _getToken();
      String url = 'http://10.0.2.2:5000/api/notifications';
      if (limit != null) url += '?limit=$limit';
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['notifications'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/notifications/stats'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'unread_count': 0};
    } catch (e) {
      return {'unread_count': 0};
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final token = await _getToken();
      await http.post(
        Uri.parse('http://10.0.2.2:5000/api/notifications/mark-all-read'),
        headers: _getHeaders(token),
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<Map<String, dynamic>> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final token = await _getToken();
      final endpoints = <String>['admins', 'add-admin'];
      for (final ep in endpoints) {
        final response = await http.post(
          Uri.parse('$baseUrl/$ep'),
          headers: _getHeaders(token),
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 201) {
          return data;
        }

        if (response.statusCode != 404) {
          throw Exception(data['message'] ?? data['error'] ?? 'Failed to create admin');
        }
      }

      throw Exception('Failed to create admin');
    } catch (e) {
      print('Error creating admin: $e');
      throw Exception('Failed to create admin: $e');
    }
  }

  // ====== Get All Users ======
  Future<Map<String, dynamic>> getAllUsers({
    String? role,
    String? status,
    String? search,
  }) async {
    try {
      final token = await _getToken();
      String url = '$baseUrl/users?';
      if (role != null) url += 'role=$role&';
      if (status != null) url += 'status=$status&';
      if (search != null) url += 'search=$search&';

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error getting users: $e');
      throw Exception('Failed to load users');
    }
  }

  // ====== Delete User ======
  Future<void> deleteUser(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user');
    }
  }

  // ====== Update User ======
  Future<void> updateUser(int userId, {String? status, String? role}) async {
    try {
      final token = await _getToken();
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (role != null) body['role'] = role;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user');
    }
  }

  // ====== Get User Details ======
  Future<Map<String, dynamic>> getUserDetails(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      print('Error getting user details: $e');
      throw Exception('Failed to load user details');
    }
  }

  // ====== Get All Posts ======
  Future<Map<String, dynamic>> getAllPosts() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      print('Error getting posts: $e');
      throw Exception('Failed to load posts');
    }
  }

  // ====== Delete Post ======
  Future<void> deletePost(int postId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('Failed to delete post');
    }
  }

  // ====== Delete Comment ======
  Future<void> deleteComment(int commentId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment');
      }
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Failed to delete comment');
    }
  }

  // ====== Get System Health ======
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load system health');
      }
    } catch (e) {
      print('Error getting system health: $e');
      throw Exception('Failed to load system health');
    }
  }
}
