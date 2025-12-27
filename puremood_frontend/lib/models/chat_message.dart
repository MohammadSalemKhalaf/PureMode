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
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
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

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasSafetyFlags => safetyFlags.isNotEmpty;
}
