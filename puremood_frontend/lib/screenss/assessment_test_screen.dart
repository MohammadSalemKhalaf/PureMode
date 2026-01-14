import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/assessment_service.dart';
import '../models/assessment_models.dart';
import 'chat_screen.dart';
import 'specialists_list_screen.dart';

class AssessmentTestScreen extends StatefulWidget {
  final String assessmentName;
  final String assessmentTitle;

  const AssessmentTestScreen({
    Key? key,
    required this.assessmentName,
    required this.assessmentTitle,
  }) : super(key: key);

  @override
  _AssessmentTestScreenState createState() => _AssessmentTestScreenState();
}

class _AssessmentTestScreenState extends State<AssessmentTestScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  List<AssessmentQuestion> _questions = [];
  List<int> _answers = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await _assessmentService.getAssessmentQuestions(widget.assessmentName);
      setState(() {
        _questions = data['questions'] as List<AssessmentQuestion>;
        _answers = List<int>.filled(_questions.length, -1);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading questions: $e';
        _isLoading = false;
      });
    }
  }

  void _answerQuestion(int optionIndex) {
    setState(() {
      _answers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_answers[_currentQuestionIndex] == -1) {
      _showSnackBar('Please select an answer');
      return;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitAssessment();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitAssessment() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      print('📝 [DEBUG] Starting submission...');
      print('📝 [DEBUG] Assessment Name: ${widget.assessmentName}');
      print('📝 [DEBUG] User Answers: $_answers');
      
      final answers = _questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        final selectedIndex = _answers[index];
        final selectedScore = question.scoreValues[selectedIndex];
        
        print('📝 [DEBUG] Question ${index + 1}:');
        print('   - Question ID: ${question.questionId}');
        print('   - Selected Index: $selectedIndex');
        print('   - Score Values: ${question.scoreValues}');
        print('   - Selected Score: $selectedScore');
        
        return AssessmentAnswer(
          questionId: question.questionId,
          selectedOptionIndex: selectedIndex,
          score: selectedScore,
        );
      }).toList();

      print('📝 [DEBUG] Final Answers: ${answers.map((a) => {
        'questionId': a.questionId,
        'selectedOptionIndex': a.selectedOptionIndex,
        'score': a.score
      }).toList()}');

      final submission = AssessmentSubmission(
        assessmentName: widget.assessmentName,
        answers: answers,
      );

      final result = await _assessmentService.submitAssessment(submission);
      print('📝 [DEBUG] Result received: Total Score = ${result.totalScore}, Risk Level = ${result.riskLevel}');
      _showResults(result);
    } catch (e) {
      print('❌ [ERROR] Submission failed: $e');
      _showSnackBar('Error submitting answers: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showResults(AssessmentResult result) {
    // Determine color based on risk level
    Color riskColor;
    String riskText;
    switch (result.riskLevel.toLowerCase()) {
      case 'low':
        riskColor = Colors.green;
        riskText = 'Low';
        break;
      case 'medium':
        riskColor = Colors.orange;
        riskText = 'Medium';
        break;
      case 'high':
        riskColor = Colors.red;
        riskText = 'High';
        break;
      default:
        riskColor = Colors.grey;
        riskText = result.riskLevel;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.psychology, color: riskColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Test Results',
                style: GoogleFonts.poppins(
                  color: riskColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultItem('Total Score', '${result.totalScore}'),
              const SizedBox(height: 12),
              _buildResultItem('Risk Level', riskText,
                  valueColor: riskColor),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: riskColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Recommendation:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: riskColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.suggestion.isNotEmpty
                          ? result.suggestion
                          : _getDefaultSuggestion(result.riskLevel),
                      style: GoogleFonts.poppins(
                        color: riskColor.withOpacity(0.8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // عرض توصية المعالج إذا موجودة
              if (result.specialistRecommendation != null && result.specialistRecommendation!.needs) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        result.specialistRecommendation!.urgency == 'high'
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                        result.specialistRecommendation!.urgency == 'high'
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: result.specialistRecommendation!.urgency == 'high'
                          ? Colors.red.shade300
                          : Colors.blue.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: result.specialistRecommendation!.urgency == 'high'
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'توصية مهمة',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: result.specialistRecommendation!.urgency == 'high'
                                    ? Colors.red.shade900
                                    : Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.specialistRecommendation!.messageAr ?? 
                        result.specialistRecommendation!.message ?? 
                        'نوصي بالتحدث مع معالج نفسي مختص',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // زر "Find Specialist" إذا موجودة التوصية
          if (result.specialistRecommendation != null && result.specialistRecommendation!.needs)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpecialistsListScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: result.specialistRecommendation!.urgency == 'high'
                    ? Colors.red.shade600
                    : const Color(0xFF00A79D),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 3,
              ),
              icon: Icon(Icons.psychology, size: 20, color: Colors.white),
              label: Text(
                'ابحث عن معالج 🩺',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Pass scores as context
              Map<String, int> scores = {};
              String assessmentType = widget.assessmentName.toLowerCase();
              if (assessmentType.contains('phq')) {
                scores['phq9'] = result.totalScore;
              } else if (assessmentType.contains('gad')) {
                scores['gad7'] = result.totalScore;
              } else if (assessmentType.contains('who')) {
                scores['who5'] = result.totalScore;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    language: 'ar',
                    context: {
                      'source_screen': 'results',
                      'scores': scores,
                    },
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: BorderSide(color: const Color(0xFF008080)),
            ),
            icon: Icon(Icons.chat_bubble_outline, size: 18, color: const Color(0xFF008080)),
            label: Text(
              'اسأل المساعد',
              style: GoogleFonts.poppins(
                color: const Color(0xFF008080),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'رجوع للرئيسية',
              style: GoogleFonts.poppins(
                color: const Color(0xFF00A79D),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDefaultSuggestion(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return 'Your condition is good. Keep tracking your mental health.';
      case 'medium':
        return 'We recommend practicing relaxation techniques and monitoring your condition.';
      case 'high':
        return 'We recommend consulting a mental health professional.';
      default:
        return 'We recommend monitoring your mental health regularly.';
    }
  }

  Widget _buildResultItem(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor ?? const Color(0xFF00A79D),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return WebScaffold(
        appBar: AppBar(
          title: Text(widget.assessmentTitle),
          backgroundColor: const Color(0xFF00A79D),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF00A79D)),
              SizedBox(height: 16),
              Text('Loading questions...'),
            
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return WebScaffold(
        appBar: AppBar(
          title: Text(widget.assessmentTitle),
          backgroundColor: const Color(0xFF00A79D),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A79D),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return WebScaffold(
        appBar: AppBar(
          title: Text(widget.assessmentTitle),
          backgroundColor: const Color(0xFF00A79D),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No questions available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return WebScaffold(
      appBar: AppBar(
        title: Text(widget.assessmentTitle),
        backgroundColor: const Color(0xFF00A79D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF004D40),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF00A79D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  color: const Color(0xFF00A79D),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          // Question and options
          Expanded(
            child: Container(
              color: const Color(0xfff3f9f8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          currentQuestion.questionText,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004D40),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Options
                    Expanded(
                      child: ListView.builder(
                        itemCount: currentQuestion.options.length,
                        itemBuilder: (context, index) {
                          final isSelected = _answers[_currentQuestionIndex] == index;
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected
                                ? const Color(0xFF00A79D).withOpacity(0.1)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF00A79D)
                                    : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                currentQuestion.options[index],
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF004D40)
                                      : Colors.grey[700],
                                ),
                              ),
                              leading: Radio<int>(
                                value: index,
                                groupValue: _answers[_currentQuestionIndex],
                                onChanged: (value) {
                                  _answerQuestion(value!);
                                },
                                activeColor: const Color(0xFF00A79D),
                              ),
                              onTap: () {
                                _answerQuestion(index);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  ElevatedButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      'Previous',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _nextQuestion,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(_currentQuestionIndex == _questions.length - 1
                      ? Icons.check
                      : Icons.arrow_forward),
                  label: Text(
                    _isSubmitting
                        ? 'Submitting...'
                        : _currentQuestionIndex == _questions.length - 1
                        ? 'Finish Test'
                        : 'Next',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A79D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}