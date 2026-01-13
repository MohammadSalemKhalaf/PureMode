import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import 'package:puremood_frontend/config/api_config.dart';

class AIChatService {
  // Use localhost for Chrome
  final String baseUrl = '${ApiConfig.baseUrl}/ai';
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

  /// Send message and get AI response
  Future<Map<String, dynamic>> sendMessage({
    int? sessionId,
    required String language,
    required List<ChatMessage> messages,
    Map<String, dynamic>? context,
    bool consent = true,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Debug: log endpoint and payload
      final url = Uri.parse('$baseUrl/chat');
      // ignore: avoid_print
      print('[AIChatService] POST ${url.toString()}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          if (sessionId != null) 'sessionId': sessionId,
          'language': language,
          'messages': messages.map((m) => m.toJson()).toList(),
          if (context != null) 'context': context,
          'consent': consent,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Debug: status and body to diagnose routing issues
        // ignore: avoid_print
        print('[AIChatService] Status: ${response.statusCode}');
        // ignore: avoid_print
        print('[AIChatService] Body: ${response.body}');
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      rethrow;
    }
  }

  /// Get all chat sessions
  Future<List<ChatSession>> getSessions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sessions'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['sessions'] as List)
            .map((json) => ChatSession.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load sessions');
      }
    } catch (e) {
      print('Error in getSessions: $e');
      return [];
    }
  }

  /// Get messages for a session
  Future<Map<String, dynamic>> getSessionMessages(int sessionId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/messages'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'session': ChatSession.fromJson(data['session']),
          'messages': (data['messages'] as List)
              .map((json) => ChatMessage.fromJson(json))
              .toList(),
        };
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error in getSessionMessages: $e');
      rethrow;
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(int sessionId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete session');
      }
    } catch (e) {
      print('Error in deleteSession: $e');
      rethrow;
    }
  }
}


