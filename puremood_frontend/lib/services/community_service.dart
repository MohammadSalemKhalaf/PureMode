import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:puremood_frontend/config/api_config.dart';

// استثناء خاص بمراقبة المحتوى
class CommentModerationException implements Exception {
  final String message;
  final List<String> foundWords;
  final String reason;
  
  CommentModerationException({
    required this.message,
    required this.foundWords,
    required this.reason,
  });
  
  @override
  String toString() {
    return 'CommentModerationException: $message';
  }
}

class CommunityService {
  final String baseUrl = '${ApiConfig.baseUrl}/community';
  final storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt');
  }

  Future<Map<String, dynamic>> getAllPosts({String? category}) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Please login first to view community posts');
      }

      final url = category != null
          ? '$baseUrl/posts?category=$category'
          : '$baseUrl/posts';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again');
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading posts: $e');
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    required String category,
    bool isAnonymous = false,
  }) async {
    try {
      final token = await getToken();
      
      // التحقق من المحتوى محلياً قبل الإرسال
      if (title.trim().isEmpty || content.trim().isEmpty) {
        throw Exception('Title and content are required');
      }
      
      if (title.length > 200) {
        throw Exception('Title is too long (maximum 200 characters)');
      }
      
      if (content.length > 5000) {
        throw Exception('Content is too long (maximum 5000 characters)');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'category': category,
          'is_anonymous': isAnonymous,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // التحقق من وجود فلترة في المحتوى
        if (responseData['moderation'] != null && 
            responseData['moderation']['wasFiltered'] == true) {
          responseData['wasContentFiltered'] = true;
          responseData['filterMessage'] = 'Some words were filtered from your post';
        }
        
        return responseData;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        
        // إذا كان الخطأ بسبب محتوى غير مناسب
        if (errorData['foundWords'] != null) {
          throw CommentModerationException(
            message: errorData['message'] ?? 'المشاركة تحتوي على محتوى غير مناسب',
            foundWords: List<String>.from(errorData['foundWords']),
            reason: errorData['reason'],
          );
        }
        
        throw Exception(errorData['message'] ?? 'Failed to create post');
      } else {
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    } catch (e) {
      if (e is CommentModerationException) {
        rethrow;
      }
      throw Exception('Error creating post: $e');
    }
  }

  Future<Map<String, dynamic>> getPostById(int postId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading post: $e');
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting post: $e');
    }
  }

  Future<Map<String, dynamic>> likePost(int postId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to like post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking post: $e');
    }
  }

  Future<Map<String, dynamic>> getComments(int postId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading comments: $e');
    }
  }

  Future<Map<String, dynamic>> createComment({
    required int postId,
    required String content,
    bool isAnonymous = false,
  }) async {
    try {
      final token = await getToken();
      
      // التحقق من المحتوى محلياً قبل الإرسال
      if (content.trim().isEmpty) {
        throw Exception('Comment cannot be empty');
      }
      
      if (content.length > 1000) {
        throw Exception('Comment is too long (maximum 1000 characters)');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content, 'is_anonymous': isAnonymous}),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // التحقق من وجود فلترة في المحتوى
        if (responseData['moderation'] != null && 
            responseData['moderation']['wasFiltered'] == true) {
          responseData['wasContentFiltered'] = true;
          responseData['filterMessage'] = 'Some words were filtered from your comment';
        }
        
        return responseData;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        
        // إذا كان الخطأ بسبب محتوى غير مناسب
        if (errorData['foundWords'] != null) {
          throw CommentModerationException(
            message: errorData['message'] ?? 'التعليق يحتوي على محتوى غير مناسب',
            foundWords: List<String>.from(errorData['foundWords']),
            reason: errorData['reason'],
          );
        }
        
        throw Exception(errorData['message'] ?? 'Failed to create comment');
      } else {
        throw Exception('Failed to create comment: ${response.statusCode}');
      }
    } catch (e) {
      if (e is CommentModerationException) {
        rethrow;
      }
      throw Exception('Error creating comment: $e');
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }

  Future<Map<String, dynamic>> repostPost({
    required int postId,
    String? content,
    bool isAnonymous = false,
  }) async {
    try {
      final token = await getToken();
      
      // التحقق من المحتوى الإضافي إذا كان موجوداً
      if (content != null && content.length > 1000) {
        throw Exception('Additional content is too long (maximum 1000 characters)');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/repost'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content ?? '',
          'is_anonymous': isAnonymous,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // التحقق من وجود فلترة في المحتوى
        if (responseData['moderation'] != null && 
            responseData['moderation']['wasFiltered'] == true) {
          responseData['wasContentFiltered'] = true;
          responseData['filterMessage'] = 'Some words were filtered from your repost';
        }
        
        return responseData;
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        final errorData = jsonDecode(response.body);
        
        // إذا كان الخطأ بسبب محتوى غير مناسب
        if (errorData['foundWords'] != null) {
          throw CommentModerationException(
            message: errorData['message'] ?? 'Additional content contains inappropriate material',
            foundWords: List<String>.from(errorData['foundWords']),
            reason: errorData['reason'],
          );
        }
        
        throw Exception(errorData['message'] ?? 'Failed to repost');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again');
      } else {
        throw Exception('Failed to repost: ${response.statusCode}');
      }
    } catch (e) {
      if (e is CommentModerationException) {
        rethrow;
      }
      throw Exception('Error reposting: $e');
    }
  }
}


