# Flutter Integration Guide - AI Chat Assistant

## Overview
This guide shows how to integrate the AI Chat Assistant into your Flutter app with:
- Tab navigation for "المساعد" (Assistant)
- CTA button after assessment results
- Chat history and manual delete

---

## 1. Create Models

### `lib/models/chat_session.dart`
```dart
class ChatSession {
  final int sessionId;
  final String title;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.sessionId,
    required this.title,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'],
      title: json['title'] ?? 'محادثة جديدة',
      language: json['language'] ?? 'ar',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
```

### `lib/models/chat_message.dart`
```dart
class ChatMessage {
  final int? messageId;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<String> safetyFlags;
  final DateTime? createdAt;

  ChatMessage({
    this.messageId,
    required this.role,
    required this.content,
    this.safetyFlags = const [],
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'],
      role: json['role'],
      content: json['content'],
      safetyFlags: json['safety_flags'] != null 
        ? List<String>.from(json['safety_flags']) 
        : [],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}
```

---

## 2. Create Service

### `lib/services/ai_chat_service.dart`
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_session.dart';
import '../models/chat_message.dart';

class AIChatService {
  final String baseUrl;
  final String token;

  AIChatService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  /// Send message and get AI response
  Future<Map<String, dynamic>> sendMessage({
    int? sessionId,
    required String language,
    required List<ChatMessage> messages,
    Map<String, dynamic>? context,
    bool consent = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/chat'),
      headers: _headers,
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
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  /// Get all chat sessions
  Future<List<ChatSession>> getSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ai/sessions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['sessions'] as List)
          .map((json) => ChatSession.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  /// Get messages for a session
  Future<Map<String, dynamic>> getSessionMessages(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ai/sessions/$sessionId/messages'),
      headers: _headers,
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
  }

  /// Delete a chat session
  Future<void> deleteSession(int sessionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/ai/sessions/$sessionId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete session');
    }
  }
}
```

---

## 3. Create Chat Screen

### `lib/screens/chat_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int? sessionId;
  final String language;
  final Map<String, dynamic>? context;

  const ChatScreen({
    Key? key,
    this.sessionId,
    this.language = 'ar',
    this.context,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int? _currentSessionId;
  late AIChatService _aiService;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    // Initialize service with token from storage
    _aiService = AIChatService(
      baseUrl: 'http://your-backend-url',
      token: 'your-jwt-token', // Get from secure storage
    );
    
    if (_currentSessionId != null) {
      _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (_currentSessionId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final data = await _aiService.getSessionMessages(_currentSessionId!);
      setState(() {
        _messages.clear();
        _messages.addAll(data['messages']);
      });
    } catch (e) {
      _showError('فشل تحميل المحادثة');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      role: 'user',
      content: _controller.text.trim(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _controller.clear();

    try {
      final response = await _aiService.sendMessage(
        sessionId: _currentSessionId,
        language: widget.language,
        messages: [userMessage],
        context: widget.context,
      );

      setState(() {
        _currentSessionId = response['sessionId'];
        _messages.add(ChatMessage(
          role: 'assistant',
          content: response['reply'],
          safetyFlags: List<String>.from(response['safetyFlags'] ?? []),
        ));
      });
    } catch (e) {
      _showError('فشل إرسال الرسالة');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد'),
        actions: [
          if (_currentSessionId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف المحادثة'),
                    content: const Text('هل أنت متأكد؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && _currentSessionId != null) {
                  await _aiService.deleteSession(_currentSessionId!);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer banner
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange.shade100,
            child: const Text(
              'هذا دعم عام وليس نصيحة طبية. استشر مختصًا للتقييم الدقيق.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
          
          // Messages list
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser 
                          ? Alignment.centerRight 
                          : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser 
                              ? Colors.blue.shade100 
                              : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg.content),
                        ),
                      );
                    },
                  ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. Add to Navigation

### Option A: Bottom Navigation Tab

In your main navigation widget, add:

```dart
BottomNavigationBarItem(
  icon: Icon(Icons.chat),
  label: 'المساعد',
),
```

And in the body:
```dart
ChatScreen(language: 'ar'),
```

### Option B: CTA Button After Assessment Results

In your assessment results screen:

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ChatScreen(
          language: 'ar',
          context: {
            'source_screen': 'results',
            'scores': {
              'phq9': phq9Score,
              'gad7': gad7Score,
              'who5': who5Score,
            },
          },
        ),
      ),
    );
  },
  icon: Icon(Icons.chat),
  label: Text('اسأل المساعد'),
),
```

---

## 5. Sessions History Screen (Optional)

```dart
class ChatSessionsScreen extends StatelessWidget {
  final AIChatService aiService;

  const ChatSessionsScreen({Key? key, required this.aiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات السابقة')),
      body: FutureBuilder<List<ChatSession>>(
        future: aiService.getSessions(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          
          final sessions = snapshot.data ?? [];
          
          if (sessions.isEmpty) {
            return const Center(child: Text('لا توجد محادثات سابقة'));
          }
          
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (ctx, i) {
              final session = sessions[i];
              return ListTile(
                title: Text(session.title),
                subtitle: Text(session.updatedAt.toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await aiService.deleteSession(session.sessionId);
                    // Refresh list
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ChatScreen(
                        sessionId: session.sessionId,
                        language: session.language,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 6. Next Steps

1. **Install dependencies**:
   ```bash
   npm install  # في الباك إند
   ```

2. **Set up environment**:
   - نسخ `.env.example` إلى `.env`
   - إضافة `OPENAI_API_KEY`

3. **Run migration**:
   ```bash
   mysql -u root -p puremood_db < migrations/create_chat_tables.sql
   ```

4. **Test endpoints**:
   استخدم Postman لاختبار `/api/ai/chat`

5. **Integrate Flutter screens**:
   - إضافة تبويب "المساعد"
   - إضافة زر "اسأل المساعد" بعد النتائج

---

## Security Checklist

- ✅ Store JWT token securely (flutter_secure_storage)
- ✅ Validate all user inputs
- ✅ Don't log sensitive PII
- ✅ Show clear disclaimers
- ✅ Handle API errors gracefully
- ✅ Rate limit requests on backend
- ✅ Monitor OpenAI costs

---

## Troubleshooting

**Flutter error: "Failed to send message"**
- Check backend logs
- Verify JWT token is valid
- Ensure network connectivity

**Backend error: "OPENAI_API_KEY not configured"**
- Verify `.env` file exists
- Restart server after adding key

**High latency**
- OpenAI API typically takes 2-5 seconds
- Show loading indicators
- Consider caching common responses
