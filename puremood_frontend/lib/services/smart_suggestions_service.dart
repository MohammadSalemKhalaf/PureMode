import 'package:flutter/material.dart';

class SmartSuggestionsService {
  final Map<String, List<Map<String, dynamic>>> _moodSuggestions = {
    "Sad": [
      {
        "type": "activity",
        "title": "Deep Breathing Exercise",
        "description": "Take 5 minutes for slow deep breathing",
        "duration": "5 minutes",
        "reason": "Helps calm nerves and improve mood",
        "icon": Icons.air,
        "color": Colors.blue,
        "category": "Relaxation",
        "isPremium": false,
      },
      {
        "type": "music",
        "title": "Happy Music Playlist",
        "description": "Songs that make you feel positive",
        "duration": "15 minutes",
        "reason": "Happy music can change your mood",
        "icon": Icons.music_note,
        "color": Colors.orange,
        "category": "Entertainment",
        "isPremium": false,
      },
      {
        "type": "therapy",
        "title": "Guided Therapy Session",
        "description":
            "Professional therapy session for deep emotional support",
        "duration": "30 minutes",
        "reason": "Professional guidance for persistent sadness",
        "icon": Icons.psychology,
        "color": Colors.purple,
        "category": "Therapy",
        "isPremium": true,
        "premiumDescription":
            "Access to licensed therapists and professional guidance",
      },
      {
        "type": "writing",
        "title": "Express Your Feelings",
        "description": "Write about your feelings without restrictions",
        "duration": "10 minutes",
        "reason": "Expressing emotions reduces pain",
        "icon": Icons.edit,
        "color": Colors.purple,
        "category": "Reflection",
        "isPremium": false,
      },
    ],

    "Happy": [
      {
        "type": "social",
        "title": "Share Your Happiness",
        "description": "Call a friend or write about your day",
        "duration": "10 minutes",
        "reason": "Sharing multiplies happiness",
        "icon": Icons.share,
        "color": Colors.green,
        "category": "Social",
        "isPremium": false,
      },
      {
        "type": "creative",
        "title": "Creative Project",
        "description": "Draw, write, or play a musical instrument",
        "duration": "20 minutes",
        "reason": "Positive energy drives creativity",
        "icon": Icons.brush,
        "color": Colors.pink,
        "category": "Creative",
        "isPremium": false,
      },
      {
        "type": "premium_activity",
        "title": "Advanced Happiness Techniques",
        "description": "Advanced methods to sustain and enhance happiness",
        "duration": "20 minutes",
        "reason": "Scientifically proven methods for long-term happiness",
        "icon": Icons.auto_awesome,
        "color": Colors.amber,
        "category": "Advanced",
        "isPremium": true,
        "premiumDescription":
            "Advanced psychological techniques and personalized coaching",
      },
    ],

    "Confused": [
      {
        "type": "writing",
        "title": "Write Your Thoughts",
        "description": "Write down everything on your mind",
        "duration": "7 minutes",
        "reason": "Writing organizes scattered thoughts",
        "icon": Icons.edit,
        "color": Colors.purple,
        "category": "Organization",
        "isPremium": false,
      },
      {
        "type": "meditation",
        "title": "Clarity Meditation",
        "description": "Focus on your breathing and regain focus",
        "duration": "5 minutes",
        "reason": "Helps clear the mind",
        "icon": Icons.self_improvement,
        "color": Colors.indigo,
        "category": "Meditation",
        "isPremium": false,
      },
      {
        "type": "premium_coaching",
        "title": "Clarity Coaching Session",
        "description": "One-on-one coaching to gain clarity",
        "duration": "25 minutes",
        "reason": "Professional guidance for decision making",
        "icon": Icons.record_voice_over,
        "color": Colors.teal,
        "category": "Coaching",
        "isPremium": true,
        "premiumDescription": "Personalized coaching sessions",
      },
    ],

    "Neutral": [
      {
        "type": "learning",
        "title": "Learn Something New",
        "description": "Read an article or watch an educational video",
        "duration": "10 minutes",
        "reason": "Learning gives a sense of accomplishment",
        "icon": Icons.school,
        "color": Colors.amber,
        "category": "Learning",
        "isPremium": false,
      },
      {
        "type": "organization",
        "title": "Organize Your Space",
        "description": "Tidy up your room or desk",
        "duration": "15 minutes",
        "reason": "Organized space gives a sense of control",
        "icon": Icons.cleaning_services,
        "color": Colors.blueGrey,
        "category": "Organization",
        "isPremium": false,
      },
      {
        "type": "premium_learning",
        "title": "Personal Development Course",
        "description": "Access to exclusive personal growth courses",
        "duration": "30 minutes",
        "reason": "Structured learning for personal growth",
        "icon": Icons.library_books,
        "color": Colors.deepPurple,
        "category": "Premium Learning",
        "isPremium": true,
        "premiumDescription": "Exclusive courses and learning materials",
      },
    ],

    "Excited": [
      {
        "type": "creative",
        "title": "Creative Project",
        "description": "Use your energy for something innovative",
        "duration": "20 minutes",
        "reason": "Positive energy drives creativity",
        "icon": Icons.brush,
        "color": Colors.pink,
        "category": "Creative",
        "isPremium": false,
      },
      {
        "type": "physical",
        "title": "Exercise",
        "description": "Use the energy for physical activity",
        "duration": "15 minutes",
        "reason": "Sports regulate excess energy",
        "icon": Icons.fitness_center,
        "color": Colors.red,
        "category": "Sports",
        "isPremium": false,
      },
      {
        "type": "premium_planning",
        "title": "Goal Achievement Plan",
        "description":
            "Create a detailed plan to channel your excitement into goals",
        "duration": "25 minutes",
        "reason": "Turn positive energy into tangible achievements",
        "icon": Icons.flag,
        "color": Colors.green,
        "category": "Premium Planning",
        "isPremium": true,
        "premiumDescription": "Advanced goal setting and achievement tracking",
      },
    ],
  };

  List<Map<String, dynamic>> getSuggestionsForMood(
    String moodLabel,
    String note,
    List<Map<String, dynamic>> moodHistory,
    bool isPremiumUser,
  ) {
    // Basic suggestions based on mood
    List<Map<String, dynamic>> baseSuggestions =
        _moodSuggestions[moodLabel] ?? _moodSuggestions["Neutral"]!;

    // Additional suggestions based on notes
    List<Map<String, dynamic>> noteSuggestions = _analyzeNoteForSuggestions(
      note,
      isPremiumUser,
    );

    // Filter suggestions based on user subscription
    List<Map<String, dynamic>> filteredSuggestions = baseSuggestions.where((
      suggestion,
    ) {
      // If premium user, show all suggestions
      if (isPremiumUser) return true;
      // If free user, show only free suggestions
      return !suggestion['isPremium'];
    }).toList();

    // Add note-based suggestions
    filteredSuggestions.addAll(noteSuggestions);

    // Add premium suggestions for premium users
    if (isPremiumUser) {
      filteredSuggestions.addAll(_getPremiumBonusSuggestions(moodLabel));
    }

    return filteredSuggestions;
  }

  List<Map<String, dynamic>> _analyzeNoteForSuggestions(
    String note,
    bool isPremiumUser,
  ) {
    List<Map<String, dynamic>> suggestions = [];
    String lowerNote = note.toLowerCase();

    if (lowerNote.contains('sleep') ||
        lowerNote.contains('tired') ||
        lowerNote.contains('exhausted')) {
      suggestions.add({
        "type": "sleep",
        "title": isPremiumUser
            ? "Sleep Quality Analysis"
            : "Sleep Improvement Tips",
        "description": isPremiumUser
            ? "Detailed sleep pattern analysis and improvement plan"
            : "Basic sleep improvement tips",
        "duration": isPremiumUser ? "15 minutes" : "5 minutes",
        "reason": "Based on your mention of tiredness",
        "icon": Icons.nightlight,
        "color": Colors.deepPurple,
        "category": "Health",
        "isPremium": isPremiumUser ? false : true,
      });
    }

    if (lowerNote.contains('work') ||
        lowerNote.contains('pressure') ||
        lowerNote.contains('deadline')) {
      suggestions.add({
        "type": "organization",
        "title": isPremiumUser ? "Stress Management Plan" : "Task Planning",
        "description": isPremiumUser
            ? "Comprehensive stress management and work-life balance plan"
            : "Organize your priorities to reduce pressure",
        "duration": isPremiumUser ? "20 minutes" : "5 minutes",
        "reason": "Helps organize work pressures",
        "icon": Icons.work,
        "color": Colors.amber,
        "category": isPremiumUser ? "Premium Planning" : "Organization",
        "isPremium": isPremiumUser ? false : true,
      });
    }

    if (lowerNote.contains('friend') ||
        lowerNote.contains('family') ||
        lowerNote.contains('someone')) {
      suggestions.add({
        "type": "social",
        "title": "Social Connection",
        "description": "Connect with a close person",
        "duration": "15 minutes",
        "reason": "Social support is important for mental health",
        "icon": Icons.people,
        "color": Colors.lightBlue,
        "category": "Social",
        "isPremium": false,
      });
    }

    if (lowerNote.contains('anxious') ||
        lowerNote.contains('fear') ||
        lowerNote.contains('stress')) {
      suggestions.add({
        "type": isPremiumUser ? "premium_anxiety" : "anxiety",
        "title": isPremiumUser
            ? "Anxiety Pattern Detection"
            : "Relaxation Exercises",
        "description": isPremiumUser
            ? "AI-powered analysis of your anxiety triggers and patterns"
            : "Techniques to calm nerves",
        "duration": isPremiumUser ? "10 minutes" : "8 minutes",
        "reason": "Useful for dealing with anxiety and stress",
        "icon": Icons.psychology,
        "color": Colors.brown,
        "category": isPremiumUser ? "Advanced Analysis" : "Relaxation",
        "isPremium": isPremiumUser ? false : true,
      });
    }

    return suggestions;
  }

  List<Map<String, dynamic>> _getPremiumBonusSuggestions(String moodLabel) {
    return [
      {
        "type": "personalized_therapy",
        "title": "Personalized Therapy Plan",
        "description": "Custom therapy plan based on your mood history",
        "duration": "45 minutes",
        "reason": "Tailored specifically for your emotional patterns",
        "icon": Icons.personal_injury,
        "color": Colors.deepOrange,
        "category": "Premium Therapy",
        "isPremium": true,
      },
      {
        "type": "ai_coaching",
        "title": "AI Mood Coach",
        "description": "24/7 AI coaching and support",
        "duration": "Ongoing",
        "reason": "Continuous support and guidance",
        "icon": Icons.smart_toy,
        "color": Colors.teal,
        "category": "AI Support",
        "isPremium": true,
      },
    ];
  }

  // Get number of premium suggestions available for a mood
  int getPremiumSuggestionsCount(String moodLabel) {
    final suggestions = _moodSuggestions[moodLabel] ?? [];
    return suggestions.where((s) => s['isPremium'] == true).length;
  }

  // Get total premium suggestions count
  int getTotalPremiumSuggestionsCount() {
    int count = 0;
    _moodSuggestions.forEach((mood, suggestions) {
      count += suggestions.where((s) => s['isPremium'] == true).length;
    });
    return count;
  }
}
