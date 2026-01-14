import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mood_models.dart';
import '../services/recommendation_service.dart';

class CategorySuggestionsScreen extends StatefulWidget {
  final String category;
  final String title;
  final List<dynamic>? suggestions;
  final Recommendation? recommendation;
  final Color primaryColor;
  final Color secondaryColor;
  final String emoji;

  const CategorySuggestionsScreen({
    Key? key,
    required this.category,
    required this.title,
    this.suggestions,
    this.recommendation,
    this.primaryColor = const Color(0xFF00897B),
    this.secondaryColor = const Color(0xFF4DB6AC),
    this.emoji = '🎯',
  }) : super(key: key);

  @override
  _CategorySuggestionsScreenState createState() => _CategorySuggestionsScreenState();
}

class _CategorySuggestionsScreenState extends State<CategorySuggestionsScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  List<Map<String, dynamic>> allSuggestions = [];
  int? selectedIndex;
  bool isLoading = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadSuggestions();
  }

  void loadSuggestions() {
    if (widget.suggestions != null && widget.suggestions!.isNotEmpty) {
      setState(() {
        allSuggestions = widget.suggestions!.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _markAsCompleted() async {
    if (widget.recommendation == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await _recommendationService.updateRecommendationStatus(
        widget.recommendation!.recommendationId,
        true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Recommendation completed successfully! ✅',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred', style: GoogleFonts.cairo()),
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
    return WebScaffold(
      backgroundColor: widget.primaryColor.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${widget.emoji} ${widget.title}',
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
      body: allSuggestions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.emoji, style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'No suggestions available',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.secondaryColor.withOpacity(0.3),
                        widget.primaryColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(widget.emoji, style: TextStyle(fontSize: 32)),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getHeaderTitle(),
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getHeaderSubtitle(),
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Suggestions List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = allSuggestions[index];
                      final isSelected = selectedIndex == index;
                      return _buildSuggestionCard(suggestion, index, isSelected);
                    },
                  ),
                ),

                // Complete Button
                if (widget.recommendation != null)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _markAsCompleted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
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
                                  'Completed ✓',
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

  String _getHeaderTitle() {
    switch (widget.category) {
      case 'exercise':
        return 'Choose your favorite exercise';
      case 'meditation':
        return 'Various meditation exercises';
      case 'breathing':
        return 'Breathing techniques';
      case 'reading':
        return 'Recommended books for you';
      case 'social':
        return 'Social activities';
      case 'activity':
        return 'Helpful activities';
      default:
        return 'Suggestions for you';
    }
  }

  String _getHeaderSubtitle() {
    switch (widget.category) {
      case 'exercise':
        return 'Start burning calories!';
      case 'meditation':
        return 'For calm and inner peace';
      case 'breathing':
        return 'Breathe deeply and relax';
      case 'reading':
        return 'Invest in yourself through reading';
      case 'social':
        return 'Connect with your loved ones';
      case 'activity':
        return 'Make good use of your time';
      default:
        return 'Try something new';
    }
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion, int index, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [widget.primaryColor, widget.primaryColor.withOpacity(0.8)]
              : [widget.secondaryColor, widget.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedIndex = selectedIndex == index ? null : index;
            });
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _buildCardContent(suggestion, isSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> suggestion, bool isSelected) {
    // Determine fields according to suggestion type
    String mainText = suggestion['name'] ?? suggestion['title'] ?? 'Item';
    String icon = suggestion['icon'] ?? widget.emoji;
    String? duration = suggestion['duration'];
    String? benefits = suggestion['benefits'];
    String? calories = suggestion['calories'];
    String? level = suggestion['level'];
    String? author = suggestion['author'];
    String? technique = suggestion['technique'];
    String? category = suggestion['category'];
    String? pages = suggestion['pages'];
    String? rating = suggestion['rating'];

    return Row(
      children: [
        // Icon
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(fontSize: 26),
            ),
          ),
        ),

        SizedBox(width: 14),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainText,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (author != null) ...[
                SizedBox(height: 2),
                Text(
                  author,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
              if (duration != null) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.9)),
                    SizedBox(width: 4),
                    Text(
                      duration,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
              if (calories != null) ...[
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 14, color: Colors.orange.shade200),
                    SizedBox(width: 4),
                    Text(
                      calories,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
              if (level != null) ...[
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.show_chart, size: 14, color: Colors.white.withOpacity(0.9)),
                    SizedBox(width: 4),
                    Text(
                      'Level: $level',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
              if (category != null) ...[
                SizedBox(height: 2),
                Text(
                  category,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
              if (pages != null) ...[
                SizedBox(height: 2),
                Text(
                  pages,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
              if (rating != null) ...[
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade200),
                    SizedBox(width: 4),
                    Text(
                      rating,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
              if (isSelected && benefits != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✨ $benefits',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              if (isSelected && technique != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎯 Technique: $technique',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Selection indicator
        if (isSelected)
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            ),
          ),
      ],
    );
  }
}
