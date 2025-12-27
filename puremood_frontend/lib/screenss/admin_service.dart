import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AdminService {
  // Use 10.0.2.2 for Android Emulator, localhost for web/desktop
  final String baseUrl = 'http://10.0.2.2:5000/api/admin';
  final storage = FlutterSecureStorage();

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt');
  }

  // 📊 جلب إحصائيات Dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load stats: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading stats: $e');
    }
  }

  // 👥 جلب كل المستخدمين
  Future<Map<String, dynamic>> getAllUsers({String? role, String? status, String? search}) async {
    try {
      final token = await getToken();
      String url = '$baseUrl/users?';
      if (role != null) url += 'role=$role&';
      if (status != null) url += 'status=$status&';
      if (search != null) url += 'search=$search&';

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load users: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  // 👤 جلب تفاصيل مستخدم
  Future<Map<String, dynamic>> getUserDetails(int userId) async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load user details: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading user details: $e');
    }
  }

  // 🔄 تحديث دور/حالة مستخدم
  Future<Map<String, dynamic>> updateUserRoleStatus(
    int userId, {
    String? role,
    String? status,
  }) async {
    try {
      final token = await getToken();
      final body = <String, dynamic>{};
      if (role != null) body['role'] = role;
      if (status != null) body['status'] = status;

      final res = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to update user: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // 🗑️ حذف مستخدم
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final token = await getToken();
      final res = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to delete user: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // 📝 جلب كل المنشورات
  Future<Map<String, dynamic>> getAllPosts() async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load posts: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading posts: $e');
    }
  }

  // 🗑️ حذف منشور
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final token = await getToken();
      final res = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to delete post: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting post: $e');
    }
  }

  // 📊 صحة النظام
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/system/health'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load system health: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading system health: $e');
    }
  }

  // 📈 جلب تعليقات منشور معين
  Future<Map<String, dynamic>> getPostComments(int postId) async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/community/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return {'comments': jsonDecode(res.body)};
      } else {
        throw Exception('Failed to load comments: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading comments: $e');
    }
  }

  // 🗑️ حذف تعليق
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    try {
      final token = await getToken();
      final res = await http.delete(
        Uri.parse('http://10.0.2.2:5000/api/community/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return {'message': 'Comment deleted successfully'};
      } else {
        throw Exception('Failed to delete comment: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }

  // 🔄 تحديث معلومات مستخدم (wrapper for updateUserRoleStatus)
  Future<Map<String, dynamic>> updateUser(
    int userId, {
    String? role,
    String? status,
    String? name,
    String? email,
  }) async {
    return await updateUserRoleStatus(userId, role: role, status: status);
  }

  // 🔔 جلب إحصائيات الإشعارات
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final token = await getToken();
      print('🔑 Token: ${token?.substring(0, 20)}...');
      print('📡 Calling: http://10.0.2.2:5000/api/notifications/stats');
      
      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/notifications/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response status: ${res.statusCode}');
      print('📥 Response body: ${res.body}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load notification stats: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('❌ Exception in getNotificationStats: $e');
      throw Exception('Error loading notification stats: $e');
    }
  }

  // 🔔 جلب الإشعارات
  Future<Map<String, dynamic>> getNotifications({int limit = 5}) async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/notifications?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load notifications: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading notifications: $e');
    }
  }

  // ✅ تحديد إشعار كمقروء
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final token = await getToken();
      await http.put(
        Uri.parse('http://10.0.2.2:5000/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // ✅ تحديد كل الإشعارات كمقروءة
  Future<void> markAllNotificationsAsRead() async {
    try {
      final token = await getToken();
      await http.put(
        Uri.parse('http://10.0.2.2:5000/api/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }
}
