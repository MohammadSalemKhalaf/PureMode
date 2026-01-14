import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mood_models.dart';
import '../services/recommendation_service.dart';
import 'music_player_screen.dart';
import 'warm_drinks_screen.dart';
import 'category_suggestions_screen.dart';
import 'writing_journal_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  final String moodEmoji;
  final String moodLabel;
  final List<Recommendation>? initialRecommendations;

  const RecommendationsScreen({
    Key? key,
    required this.moodEmoji,
    required this.moodLabel,
    this.initialRecommendations,
  }) : super(key: key);

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  final RecommendationService _recommendationService = RecommendationService();
  List<Recommendation> recommendations = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    if (widget.initialRecommendations != null) {
      recommendations = widget.initialRecommendations!;
      isLoading = false;
      _animationController.forward();
    } else {
      loadRecommendations();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadRecommendations() async {
    try {
      final recs = await _recommendationService.getMyRecommendations(
        moodEmoji: widget.moodEmoji,
        limit: 10,
      );

      setState(() {
        recommendations = recs;
        isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      print('Error loading recommendations: $e');
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load recommendations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getMoodColor() {
    switch (widget.moodEmoji) {
      case '😢':
        return Color(0xFF64B5F6);
      case '😔':
        return Color(0xFFFFB74D);
      case '😐':
        return Color(0xFFB0BEC5);
      case '😊':
        return Color(0xFF4DB6AC);
      case '😄':
        return Color(0xFFF06292);
      default:
        return Color(0xFF4DB6AC);
    }
  }

  Widget _buildRecommendationCard(Recommendation rec, int index) {
    final categoryInfo = RecommendationService.getCategoryInfo(rec.category);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final safeValue = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - safeValue)),
          child: Opacity(
            opacity: safeValue,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(categoryInfo['gradient'][0]),
              Color(categoryInfo['gradient'][1]),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(categoryInfo['color']).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              _handleRecommendationTap(rec);
            },
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        rec.icon ?? categoryInfo['icon'],
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.title,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          rec.description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            categoryInfo['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow or Checkmark
                  rec.completed
                      ? Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.7),
                          size: 18,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleRecommendationTap(Recommendation rec) async {
    final categoryInfo = RecommendationService.getCategoryInfo(rec.category);
    
    // Check if there are suggestions for this category
    if (rec.suggestions != null && rec.suggestions!.isNotEmpty) {
      switch (rec.category) {
        case 'music':
          // Open music player
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusicPlayerScreen(
                initialMusicUrl: rec.audioUrl,
                musicList: rec.suggestions,
                recommendation: rec,
              ),
            ),
          );
          
          // Reload if completed
          if (result == true) {
            loadRecommendations();
          }
          break;
        
        case 'food':
          // Open warm drinks screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WarmDrinksScreen(
                drinksList: rec.suggestions,
                recommendation: rec,
              ),
            ),
          );
          
          // Reload recommendations if proof was uploaded
          if (result == true) {
            loadRecommendations();
          }
          break;
        
        case 'exercise':
          // Open exercises screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategorySuggestionsScreen(
                category: 'exercise',
                title: 'Exercises',
                suggestions: rec.suggestions,
                recommendation: rec,
                primaryColor: Color(categoryInfo['color']),
                secondaryColor: Color(categoryInfo['gradient'][0]),
                emoji: categoryInfo['icon'],
              ),
            ),
          );
          if (result == true) loadRecommendations();
          break;
        
        case 'meditation':
          // Open meditation screen
          final result2 = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategorySuggestionsScreen(
                category: 'meditation',
                title: 'Meditation exercises',
                suggestions: rec.suggestions,
                recommendation: rec,
                primaryColor: Color(categoryInfo['color']),
                secondaryColor: Color(categoryInfo['gradient'][0]),
                emoji: categoryInfo['icon'],
              ),
            ),
          );
          if (result2 == true) loadRecommendations();
          break;
        
        case 'breathing':
          // Open breathing exercises screen
          final result3 = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategorySuggestionsScreen(
                category: 'breathing',
                title: 'Breathing exercises',
                suggestions: rec.suggestions,
                recommendation: rec,
                primaryColor: Color(categoryInfo['color']),
                secondaryColor: Color(categoryInfo['gradient'][0]),
                emoji: categoryInfo['icon'],
              ),
            ),
          );
          if (result3 == true) loadRecommendations();
          break;
        
        case 'reading':
          // Open reading suggestions screen
          final result4 = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategorySuggestionsScreen(
                category: 'reading',
                title: 'Recommended books',
                suggestions: rec.suggestions,
                recommendation: rec,
                primaryColor: Color(categoryInfo['color']),
                secondaryColor: Color(categoryInfo['gradient'][0]),
                emoji: categoryInfo['icon'],
              ),
            ),
          );
          if (result4 == true) loadRecommendations();
          break;
        
        case 'social':
          // Open social activities screen
          final result5 = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategorySuggestionsScreen(
                category: 'social',
                title: 'Social activities',
                suggestions: rec.suggestions,
                recommendation: rec,
                primaryColor: Color(categoryInfo['color']),
                secondaryColor: Color(categoryInfo['gradient'][0]),
                emoji: categoryInfo['icon'],
              ),
            ),
          );
          if (result5 == true) loadRecommendations();
          break;
        
        case 'activity':
          // Check if the recommendation is about writing
          if (rec.title.toLowerCase().contains('write') ||
              rec.title.toLowerCase().contains('writing') ||
              rec.title.toLowerCase().contains('journal') ||
              rec.description.toLowerCase().contains('write') ||
              rec.description.toLowerCase().contains('writing') ||
              rec.description.toLowerCase().contains('journal')) {
            // Open dedicated writing screen
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WritingJournalScreen(
                  recommendation: rec,
                  promptTitle: rec.title,
                ),
              ),
            );
            
            // Reload recommendations if saved
            if (result == true) {
              loadRecommendations();
            }
          } else {
            // Open general activities screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategorySuggestionsScreen(
                  category: 'activity',
                  title: 'Helpful activities',
                  suggestions: rec.suggestions,
                  recommendation: rec,
                  primaryColor: Color(categoryInfo['color']),
                  secondaryColor: Color(categoryInfo['gradient'][0]),
                  emoji: categoryInfo['icon'],
                ),
              ),
            );
          }
          break;
        
        default:
          // Show normal details
          _showRecommendationDetails(rec, categoryInfo);
      }
    } else {
      // No suggestions available, show normal details
      _showRecommendationDetails(rec, categoryInfo);
    }
  }

  void _showRecommendationDetails(Recommendation rec, Map<String, dynamic> categoryInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(categoryInfo['gradient'][0]),
                    Color(categoryInfo['gradient'][1]),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(categoryInfo['color']).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  rec.icon ?? categoryInfo['icon'],
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                rec.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
              ),
            ),
            
            SizedBox(height: 12),
            
            // Category chip
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(categoryInfo['gradient'][0]),
                    Color(categoryInfo['gradient'][1]),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categoryInfo['name'],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Description
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  rec.description,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            
            // Close button
            Padding(
              padding: EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it! 👍',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: Color(0xFFE8F5F3),
      appBar: AppBar(
        backgroundColor: _getMoodColor(),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Recommendations for You',
          style: GoogleFonts.poppins(
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
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_getMoodColor()),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading recommendations...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getMoodColor().withOpacity(0.2),
                          _getMoodColor().withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getMoodColor().withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.moodEmoji,
                          style: TextStyle(fontSize: 48),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You\'re feeling ${widget.moodLabel}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00695C),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Here are ${recommendations.length} personalized suggestions',
                                style: GoogleFonts.poppins(
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
                  
                  // Recommendations list
                  Expanded(
                    child: recommendations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '🎯',
                                  style: TextStyle(fontSize: 64),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No recommendations yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Check back later!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: recommendations.length,
                            itemBuilder: (context, index) {
                              return _buildRecommendationCard(
                                recommendations[index],
                                index,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
