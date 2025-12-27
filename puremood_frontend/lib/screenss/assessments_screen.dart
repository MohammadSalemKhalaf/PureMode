import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assessment_test_screen.dart';
import '../models/assessment_models.dart';
import '../services/assessment_service.dart';

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({Key? key}) : super(key: key);

  Map<String, AssessmentSchedule> _indexSchedulesByType(
    List<AssessmentSchedule> schedules,
  ) {
    final Map<String, AssessmentSchedule> byType = {};
    for (final s in schedules) {
      byType[s.assessmentType.toLowerCase()] = s;
    }
    return byType;
  }

  String _lockedMessageForSchedule(AssessmentSchedule schedule) {
    final remaining = schedule.daysUntilDue;
    if (remaining <= 0) {
      return 'Not available yet';
    }
    return 'Remaining: $remaining log${remaining == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final assessmentService = AssessmentService();
    final assessments = [
      {
        'id': 'anxiety',
        'name': 'Anxiety Test (GAD-7)',
        'description': 'General Anxiety Disorder Scale',
        'questions': '7 Questions',
        'icon': Icons.psychology_outlined,
        'color': const Color(0xFF5C6BC0),
        'info': 'Helps assess general anxiety symptoms'
      },
      {
        'id': 'depression',
        'name': 'Depression Test (PHQ-9)',
        'description': 'Patient Health Questionnaire',
        'questions': '9 Questions',
        'icon': Icons.sentiment_very_dissatisfied_outlined,
        'color': const Color(0xFF7E57C2),
        'info': 'Certified scale for depression symptoms'
      },
      {
        'id': 'wellbeing',
        'name': 'Well-being Index (WHO-5)',
        'description': 'WHO Well-being Index',
        'questions': '5 Questions',
        'icon': Icons.self_improvement_outlined,
        'color': const Color(0xFF66BB6A),
        'info': 'Measures overall psychological well-being'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff3f9f8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A79D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mental Health Assessments',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<AssessmentSchedule>>(
        future: assessmentService.getAssessmentSchedules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF00A79D),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load assessment schedule. Please try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final schedules = snapshot.data ?? <AssessmentSchedule>[];
          final scheduleByType = _indexSchedulesByType(schedules);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: assessments.length,
                  itemBuilder: (context, index) {
                    final assessment = assessments[index];
                    final id = (assessment['id'] as String).toLowerCase();
                    final schedule = scheduleByType[id];
                    final isLocked = schedule != null ? !schedule.isDue : true;
                    final lockedMessage = schedule != null
                        ? _lockedMessageForSchedule(schedule)
                        : 'Not available yet';

                    return _buildAssessmentCard(
                      context,
                      assessment,
                      isLocked: isLocked,
                      lockedMessage: lockedMessage,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00A79D), const Color(0xFF006D68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Assess Your Mental Health',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Take scientifically validated tests to understand your mental well-being. Early detection helps in getting the right support.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white.withOpacity(0.9), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your responses are confidential and secure',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(
    BuildContext context,
    Map<String, dynamic> assessment, {
    required bool isLocked,
    required String lockedMessage,
  }) {
    final color = assessment['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lockedMessage),
                backgroundColor: Colors.grey.shade800,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssessmentTestScreen(
                assessmentName: assessment['id'] as String,
                assessmentTitle: assessment['name'] as String,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      assessment['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isLocked)
                          Text(
                            lockedMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Locked',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                assessment['description'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.quiz_outlined, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    assessment['questions'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.info_outline, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assessment['info'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade400 : null,
                      gradient: isLocked
                          ? null
                          : LinearGradient(
                              colors: [color, color.withOpacity(0.8)],
                            ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isLocked
                          ? null
                          : [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start Test',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}