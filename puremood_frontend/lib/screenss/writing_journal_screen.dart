import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mood_models.dart';
import '../services/recommendation_service.dart';

class WritingJournalScreen extends StatefulWidget {
  final Recommendation recommendation;
  final String promptTitle;

  const WritingJournalScreen({
    Key? key,
    required this.recommendation,
    this.promptTitle = 'Write your feelings',
  }) : super(key: key);

  @override
  _WritingJournalScreenState createState() => _WritingJournalScreenState();
}

class _WritingJournalScreenState extends State<WritingJournalScreen> {
  final TextEditingController _writingController = TextEditingController();
  final RecommendationService _recommendationService = RecommendationService();
  bool isSaving = false;
  int wordCount = 0;
  int charCount = 0;

  @override
  void initState() {
    super.initState();
    _writingController.addListener(_updateCounts);
  }

  @override
  void dispose() {
    _writingController.removeListener(_updateCounts);
    _writingController.dispose();
    super.dispose();
  }

  void _updateCounts() {
    setState(() {
      charCount = _writingController.text.length;
      wordCount = _writingController.text.trim().isEmpty
          ? 0
          : _writingController.text.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _saveWriting() async {
    if (_writingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write something first', style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Update recommendation status to completed
      await _recommendationService.updateRecommendationStatus(
        widget.recommendation.recommendationId,
        true,
      );

      // You can save the text to note or elsewhere if needed
      // For now, we only set completed = true

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Your writing has been saved successfully! ',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back with success result
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while saving', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.amber.shade700,
        elevation: 0,
        centerTitle: true,
        title: Text(
          ' ${widget.promptTitle}',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade100,
                  Colors.orange.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.shade300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  ' Express your feelings',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Write whatever is on your mind without limits or judgment. Writing helps organize thoughts and reduce stress.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Writing prompts
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ' Writing ideas:',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                SizedBox(height: 8),
                _buildPrompt('• How do you feel right now?'),
                _buildPrompt('• What made you feel this way?'),
                _buildPrompt('• What do you need in this moment?'),
                _buildPrompt('• What are you grateful for today?'),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Writing Area
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Words', wordCount.toString(), Icons.text_fields),
                      _buildStat('Letters', charCount.toString(), Icons.abc),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: charCount > 50 ? Colors.green.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              charCount > 50 ? Icons.check_circle : Icons.edit,
                              size: 16,
                              color: charCount > 50 ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                            SizedBox(width: 4),
                            Text(
                              charCount > 50 ? 'Great!' : 'Start',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: charCount > 50 ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Text Field
                  Expanded(
                    child: TextField(
                      controller: _writingController,
                      maxLines: null,
                      expands: true,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        height: 1.8,
                        color: Colors.grey.shade800,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing here...\n\nExpress your feelings freely, no one is judging you ',
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 15,
                          color: Colors.grey.shade400,
                          height: 1.6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.amber.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.amber.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.amber.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.amber.shade50,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isSaving ? null : _saveWriting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: isSaving
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Save and finish ',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.amber.shade700),
        SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade800,
          ),
        ),
      ],
    );
  }
}
