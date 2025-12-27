import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/assessment_models.dart';
import '../screenss/assessment_test_screen.dart';

class AssessmentReminderDialog extends StatelessWidget {
  final List<AssessmentSchedule> dueAssessments;

  const AssessmentReminderDialog({
    Key? key,
    required this.dueAssessments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00A79D).withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF00A79D).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 48,
                color: Color(0xFF00A79D),
              ),
            ),

            SizedBox(height: 16),

            // Title
            Text(
              '⏰ It\'s time for your periodic assessment',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A79D),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            // Description
            Text(
              'You have ${dueAssessments.length} due assessment${dueAssessments.length > 1 ? "s" : ""}',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            // Assessment Cards
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dueAssessments.length,
                itemBuilder: (context, index) {
                  final assessment = dueAssessments[index];
                  return _buildAssessmentItem(assessment);
                },
              ),
            ),

            SizedBox(height: 20),

            // Info Text
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assessments appear based on how often you log your mood to track your progress accurately',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                // Later Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      'Later',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Start Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startFirstAssessment(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00A79D),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start now',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentItem(AssessmentSchedule assessment) {
    // Get color based on type
    Color getColor() {
      switch (assessment.assessmentType) {
        case 'anxiety':
          return Color(0xFF5C6BC0);
        case 'depression':
          return Color(0xFF7E57C2);
        case 'wellbeing':
          return Color(0xFF66BB6A);
        default:
          return Colors.grey;
      }
    }

    // Get icon
    IconData getIcon() {
      switch (assessment.assessmentType) {
        case 'anxiety':
          return Icons.psychology_outlined;
        case 'depression':
          return Icons.sentiment_very_dissatisfied_outlined;
        case 'wellbeing':
          return Icons.self_improvement_outlined;
        default:
          return Icons.quiz_outlined;
      }
    }

    // Get entries text
    String getEntriesText() {
      if (assessment.lastTaken == null) {
        return 'Never taken before';
      }
      final entriesLeft = assessment.daysUntilDue; // It is named "days" but now represents entries
      if (entriesLeft == 0) {
        return 'Due now! ✅';
      } else {
        return 'Remaining: $entriesLeft log${entriesLeft == 1 ? "" : "s"}';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(getIcon(), color: getColor(), size: 20),
          ),

          SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment.assessmentName,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  getEntriesText(),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Badge
          if (assessment.isDue)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Due',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startFirstAssessment(BuildContext context) {
    // Start the first due assessment
    if (dueAssessments.isNotEmpty) {
      final firstAssessment = dueAssessments[0];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentTestScreen(
            assessmentName: firstAssessment.assessmentType,
            assessmentTitle: firstAssessment.assessmentName,
          ),
        ),
      );
    }
  }
}

// Helper function to show the dialog
Future<void> showAssessmentReminderIfNeeded(BuildContext context, List<AssessmentSchedule> schedules) async {
  final dueAssessments = schedules.where((s) => s.isDue).toList();
  
  if (dueAssessments.isNotEmpty) {
    await Future.delayed(Duration(milliseconds: 500)); // Small delay for better UX
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AssessmentReminderDialog(
          dueAssessments: dueAssessments,
        ),
      );
    }
  }
}
