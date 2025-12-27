// lib/models/mood_models.dart
import 'dart:convert';

class MoodAnalytics {
  final int analyticsId;
  final int userId;
  final String periodType; // daily, weekly, monthly
  final double averageMood;
  final int highDays;
  final int lowDays;
  final String trend; // improving, declining, stable
  final DateTime createdAt;

  MoodAnalytics({
    required this.analyticsId,
    required this.userId,
    required this.periodType,
    required this.averageMood,
    required this.highDays,
    required this.lowDays,
    required this.trend,
    required this.createdAt,
  });

  factory MoodAnalytics.fromJson(Map<String, dynamic> json) {
    return MoodAnalytics(
      analyticsId: json['analytics_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      periodType: json['period_type'] ?? '',
      averageMood: (json['average_mood'] ?? 0).toDouble(),
      highDays: json['high_days'] ?? 0,
      lowDays: json['low_days'] ?? 0,
      trend: json['trend'] ?? 'stable',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class AIIndicator {
  final int indicatorId;
  final int userId;
  final String riskLevel; // low, medium, high
  final String message;
  final String suggestion;
  final DateTime analyzedAt;

  AIIndicator({
    required this.indicatorId,
    required this.userId,
    required this.riskLevel,
    required this.message,
    required this.suggestion,
    required this.analyzedAt,
  });

  factory AIIndicator.fromJson(Map<String, dynamic> json) {
    return AIIndicator(
      indicatorId: json['indicator_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      riskLevel: json['risk_level'] ?? 'low',
      message: json['message'] ?? '',
      suggestion: json['suggestion'] ?? '',
      analyzedAt: DateTime.parse(json['analyzed_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// 🎯 Recommendation Model
class Recommendation {
  final int recommendationId;
  final int userId;
  final int? moodId;
  final String moodEmoji;
  final String title;
  final String description;
  final String category;
  final String? icon;
  final bool completed;
  final String? proofImageUrl;
  final List<dynamic>? suggestions;
  final String? audioUrl;
  final DateTime createdAt;

  Recommendation({
    required this.recommendationId,
    required this.userId,
    this.moodId,
    required this.moodEmoji,
    required this.title,
    required this.description,
    required this.category,
    this.icon,
    this.completed = false,
    this.proofImageUrl,
    this.suggestions,
    this.audioUrl,
    required this.createdAt,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    List<dynamic>? parsedSuggestions;
    if (json['suggestions'] != null && json['suggestions'] is String) {
      try {
        parsedSuggestions = jsonDecode(json['suggestions']);
      } catch (e) {
        parsedSuggestions = null;
      }
    } else if (json['suggestions'] is List) {
      parsedSuggestions = json['suggestions'];
    }

    return Recommendation(
      recommendationId: json['recommendation_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      moodId: json['mood_id'],
      moodEmoji: json['mood_emoji'] ?? '😊',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'activity',
      icon: json['icon'],
      completed: json['completed'] ?? false,
      proofImageUrl: json['proof_image_url'],
      suggestions: parsedSuggestions,
      audioUrl: json['audio_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendation_id': recommendationId,
      'user_id': userId,
      'mood_id': moodId,
      'mood_emoji': moodEmoji,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'completed': completed,
      'proof_image_url': proofImageUrl,
      'suggestions': suggestions,
      'audio_url': audioUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
