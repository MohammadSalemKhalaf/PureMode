import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BookingChatMessageDto {
  final int id;
  final String senderRole; // 'patient' or 'specialist'
  final String content;
  final DateTime createdAt;

  BookingChatMessageDto({
    required this.id,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory BookingChatMessageDto.fromJson(Map<String, dynamic> json) {
    return BookingChatMessageDto(
      id: json['id'] ?? json['message_id'] ?? 0,
      senderRole: json['sender_role'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class BookingChatService {
  final _storage = const FlutterSecureStorage();
  String get _baseUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return _storage.read(key: 'jwt');
  }

  Future<List<BookingChatMessageDto>> getMessages(int bookingId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final uri = Uri.parse('$_baseUrl/chat/booking/$bookingId/messages');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['messages'] as List? ?? []);
      return list
          .map((e) => BookingChatMessageDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load chat messages');
    }
  }

  Future<BookingChatMessageDto?> getLastMessage(int bookingId) async {
    final messages = await getMessages(bookingId);
    if (messages.isEmpty) {
      return null;
    }
    return messages.last;
  }

  Future<BookingChatMessageDto> sendMessage({
    required int bookingId,
    required String content,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final uri = Uri.parse('$_baseUrl/chat/booking/$bookingId/messages');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final msgJson = data['message'] as Map<String, dynamic>;
      return BookingChatMessageDto.fromJson(msgJson);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to send message');
    }
  }
}
