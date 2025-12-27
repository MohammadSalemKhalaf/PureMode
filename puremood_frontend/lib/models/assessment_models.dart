class Assessment {
  final int assessmentId;
  final String name;
  final String description;
  final int intervalDays; // interval between assessments (7, 14, 30)
  final String assessmentType; // anxiety, depression, stress, wellbeing

  Assessment({
    required this.assessmentId,
    required this.name,
    required this.description,
    this.intervalDays = 14, // default value
    this.assessmentType = 'general',
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      assessmentId: json['assessment_id'],
      name: json['name'],
      description: json['description'],
      intervalDays: json['interval_days'] ?? 14,
      assessmentType: json['assessment_type'] ?? 'general',
    );
  }
}

class AssessmentQuestion {
  final int questionId;
  final int assessmentId;
  final String questionText;
  final List<String> options;
  final List<int> scoreValues;

  AssessmentQuestion({
    required this.questionId,
    required this.assessmentId,
    required this.questionText,
    required this.options,
    required this.scoreValues,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      questionId: json['question_id'],
      assessmentId: json['assessment_id'],
      questionText: json['question_text'],
      options: List<String>.from(json['options']),
      scoreValues: List<int>.from(json['score_values']),
    );
  }
}

class AssessmentAnswer {
  final int questionId;
  final int selectedOptionIndex;
  final int score;

  AssessmentAnswer({
    required this.questionId,
    required this.selectedOptionIndex,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_option_index': selectedOptionIndex,
      'score': score,
    };
  }
}

class AssessmentSubmission {
  final String assessmentName;
  final List<AssessmentAnswer> answers;

  AssessmentSubmission({
    required this.assessmentName,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'assessmentName': assessmentName,
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }
}

class AssessmentResult {
  final int resultId;
  final int totalScore;
  final String riskLevel;
  final String message;
  final String suggestion;
  final DateTime takenAt;
  final SpecialistRecommendation? specialistRecommendation;

  AssessmentResult({
    required this.resultId,
    required this.totalScore,
    required this.riskLevel,
    required this.message,
    required this.suggestion,
    required this.takenAt,
    this.specialistRecommendation,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      resultId: json['result_id'] ?? 0,
      totalScore: json['total_score'] ?? 0,
      riskLevel: json['risk_level'] ?? 'unknown',
      message: json['message'] ?? '',
      suggestion: json['suggestion'] ?? '',
      takenAt: DateTime.parse(json['taken_at'] ?? DateTime.now().toString()),
      specialistRecommendation: json['specialist_recommendation'] != null
          ? SpecialistRecommendation.fromJson(json['specialist_recommendation'])
          : null,
    );
  }
}

class SpecialistRecommendation {
  final bool needs;
  final String? urgency;
  final String? message;
  final String? messageAr;

  SpecialistRecommendation({
    required this.needs,
    this.urgency,
    this.message,
    this.messageAr,
  });

  factory SpecialistRecommendation.fromJson(Map<String, dynamic> json) {
    return SpecialistRecommendation(
      needs: json['needs'] ?? false,
      urgency: json['urgency'],
      message: json['message'],
      messageAr: json['messageAr'],
    );
  }
}

// Model: comparison between assessments
class AssessmentComparison {
  final AssessmentResult current;
  final AssessmentResult? previous;
  final int scoreDifference;
  final String trend; // 'improved', 'stable', 'worsened'
  final String trendMessage;
  final bool needsProfessionalHelp;

  AssessmentComparison({
    required this.current,
    this.previous,
    required this.scoreDifference,
    required this.trend,
    required this.trendMessage,
    required this.needsProfessionalHelp,
  });

  factory AssessmentComparison.fromJson(Map<String, dynamic> json) {
    return AssessmentComparison(
      current: AssessmentResult.fromJson(json['current']),
      previous: json['previous'] != null 
          ? AssessmentResult.fromJson(json['previous'])
          : null,
      scoreDifference: json['score_difference'] ?? 0,
      trend: json['trend'] ?? 'stable',
      trendMessage: json['trend_message'] ?? '',
      needsProfessionalHelp: json['needs_professional_help'] ?? false,
    );
  }
}

// Model: assessment schedule
class AssessmentSchedule {
  final String assessmentType;
  final String assessmentName;
  final DateTime? lastTaken;
  final DateTime? nextDue;
  final int intervalDays;
  final bool isDue;
  final int daysUntilDue;

  AssessmentSchedule({
    required this.assessmentType,
    required this.assessmentName,
    this.lastTaken,
    this.nextDue,
    required this.intervalDays,
    required this.isDue,
    required this.daysUntilDue,
  });

  factory AssessmentSchedule.fromJson(Map<String, dynamic> json) {
    return AssessmentSchedule(
      assessmentType: json['assessment_type'] ?? '',
      assessmentName: json['assessment_name'] ?? '',
      lastTaken: json['last_taken'] != null 
          ? DateTime.parse(json['last_taken'])
          : null,
      nextDue: json['next_due'] != null 
          ? DateTime.parse(json['next_due'])
          : null,
      intervalDays: json['interval_days'] ?? 14,
      isDue: json['is_due'] ?? false,
      daysUntilDue: json['days_until_due'] ?? 0,
    );
  }
}

// Model: user progress over time
class AssessmentProgress {
  final String assessmentType;
  final List<AssessmentResult> history;
  final String overallTrend;
  final double averageScore;
  final AssessmentResult? bestResult;
  final AssessmentResult? worstResult;

  AssessmentProgress({
    required this.assessmentType,
    required this.history,
    required this.overallTrend,
    required this.averageScore,
    this.bestResult,
    this.worstResult,
  });

  factory AssessmentProgress.fromJson(Map<String, dynamic> json) {
    return AssessmentProgress(
      assessmentType: json['assessment_type'] ?? '',
      history: (json['history'] as List?)
          ?.map((r) => AssessmentResult.fromJson(r))
          .toList() ?? [],
      overallTrend: json['overall_trend'] ?? 'stable',
      averageScore: (json['average_score'] ?? 0).toDouble(),
      bestResult: json['best_result'] != null 
          ? AssessmentResult.fromJson(json['best_result'])
          : null,
      worstResult: json['worst_result'] != null 
          ? AssessmentResult.fromJson(json['worst_result'])
          : null,
    );
  }
}

// Model: professional referral recommendation
class ProfessionalReferral {
  final bool isNeeded;
  final String severity; // 'moderate', 'severe', 'critical'
  final String reason;
  final String message;
  final List<String> symptoms;
  final List<String> recommendations;

  ProfessionalReferral({
    required this.isNeeded,
    required this.severity,
    required this.reason,
    required this.message,
    required this.symptoms,
    required this.recommendations,
  });

  factory ProfessionalReferral.fromJson(Map<String, dynamic> json) {
    return ProfessionalReferral(
      isNeeded: json['is_needed'] ?? false,
      severity: json['severity'] ?? 'moderate',
      reason: json['reason'] ?? '',
      message: json['message'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}