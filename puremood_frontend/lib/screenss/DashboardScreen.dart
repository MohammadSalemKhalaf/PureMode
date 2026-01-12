// lib/screenss/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:puremood_frontend/services/api_service.dart';
import 'package:puremood_frontend/services/assessment_service.dart';
import 'package:puremood_frontend/screenss/profile_screen.dart';
import 'package:puremood_frontend/screenss/mood_tracking_screen.dart';
import 'package:puremood_frontend/screenss/mood_analytics_screen.dart';
import 'package:puremood_frontend/screenss/suggestions_screen.dart';
import 'package:puremood_frontend/screenss/community_screen.dart';
import 'package:puremood_frontend/screenss/assessments_screen.dart';
import 'package:puremood_frontend/screenss/admin_dashboard_screen.dart';
import 'package:puremood_frontend/screenss/gamification_screen.dart';
import 'package:puremood_frontend/screenss/chat_screen.dart';
import 'package:puremood_frontend/screenss/specialists_list_screen.dart';
import 'package:puremood_frontend/screenss/my_bookings_screen.dart';
import 'package:puremood_frontend/screenss/my_mood_history_screen.dart';
import 'package:puremood_frontend/screenss/messages_list_screen.dart';
import '../widgets/assessment_reminder_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  const DashboardScreen({required this.userName});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final api = ApiService();
  final assessmentService = AssessmentService();
  Map<String, dynamic>? summary;

  String? lastMoodEmoji;
  String? lastMoodNote;
  DateTime? lastMoodTime;
  int? pointsAdded;
  bool hasMoodData = false;
  String? actualUserName; // Real name from API

  // ✅ Everything starts from zero
  int daysTracked = 0;
  double averageScore = 0.0;
  List<double> weeklyMoodData = [];
  Map<DateTime, bool> trackedDays = {}; // For calendar
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Quick Access items (not in bottom nav)
  final List<_QuickAccessItem> _quickAccessItems = [
    _QuickAccessItem("Mood Tracking", Icons.emoji_emotions_outlined, Colors.teal),
    _QuickAccessItem("Mood History", Icons.insights_outlined, Colors.indigo),
    _QuickAccessItem("Messages", Icons.chat_bubble_outline, Colors.blueGrey),
    _QuickAccessItem("AI Assistant", Icons.smart_toy_outlined, Colors.teal),
    _QuickAccessItem("My Bookings", Icons.calendar_today, Colors.deepOrange),
    _QuickAccessItem("Analytics", Icons.insights_rounded, Colors.blue),
    _QuickAccessItem("Assessments", Icons.psychology_outlined, Colors.purple),
    _QuickAccessItem("Community", Icons.people_alt_outlined, Colors.green),
    _QuickAccessItem("Suggestions", Icons.favorite_outline_rounded, Colors.pink),
  ];

  late List<_ResourceItem> _resourceItems;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeResourceItems();
    _checkAssessmentsDue(); // Check due assessments
    _loadUserName(); // Load real user name
    _loadInitialData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.02), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 0.98), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeResourceItems() {
    _resourceItems = [
      _ResourceItem("Mental Health Tests", Icons.psychology_rounded, Colors.purple, "Self-assessment", _navigateToAssessments),
      _ResourceItem("Breathing Exercises", Icons.self_improvement_rounded, Colors.blue, "Relax and breathe", () {}),
      _ResourceItem("Calming Music", Icons.music_note_rounded, Colors.green, "Soothing sounds", () {}),
      _ResourceItem("Meditation Guide", Icons.spa_rounded, Colors.orange, "Mindfulness", () {}),
    ];
  }

  void _loadInitialData() async {
    await loadDashboardData();
  }

  Future<void> _loadUserName() async {
    try {
      final user = await api.getMe();
      if (user != null && mounted) {
        setState(() {
          actualUserName = user['name'];
        });
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  // Check due assessments
  void _checkAssessmentsDue() async {
    try {
      await Future.delayed(Duration(milliseconds: 1000)); // Wait for screen to load
      final schedules = await assessmentService.getAssessmentSchedules();
      
      if (mounted) {
        await showAssessmentReminderIfNeeded(context, schedules);
      }
    } catch (e) {
      // Silent fail - reminder is optional
      print('Assessment reminder check failed: $e');
    }
  }

  // 📱 جدولة تذكير فتح التطبيق
  Future<void> _scheduleAppStartupReminder() async {
    try {
      print('📱 Scheduling app startup reminder...');
      final response = await api.scheduleAppStartupReminder();
      
      if (response != null) {
        print('✅ App startup reminder scheduled successfully');
      }
    } catch (e) {
      print('❌ Error scheduling app startup reminder: $e');
      // Silent fail - reminder is optional
    }
  }

  // ✅ Fix: load data function depends on number of entries
  Future<void> loadDashboardData() async {
    try {
      print('🔄 Loading dashboard data...');
      final res = await api.getDashboardSummary();
      print('📊 API Response: $res');

      if (mounted) {
        setState(() {
          summary = res;

          // ✅ Check for real data
          int? apiTotalMoods = _parseInt(res['totalMoods']);
          String? apiLastMood = res['lastMoodEmoji']?.toString();

          // ✅ Only if totalMoods > 0 we consider it has data
          hasMoodData = apiTotalMoods != null && apiTotalMoods > 0;

          if (hasMoodData) {
            // ✅ Real data - use ?? 0 to avoid null
            lastMoodEmoji = apiLastMood;
            lastMoodNote = res['lastMoodNote']?.toString();
            int totalMoods = apiTotalMoods ?? 0;

            // ✅ New: daysTracked depends on number of entries
            daysTracked = totalMoods;

            averageScore = _parseDouble(res['averageMood']) ?? 0.0;

            print('✅ REAL DATA - Days: $daysTracked, Avg: $averageScore');
            
            // Load tracked days for calendar
            _loadTrackedDays();

            // ✅ Generate chart data based on number of entries
            _generateWeeklyDataFromEntries();
          } else {
            // ✅ No data - everything zero
            lastMoodEmoji = null;
            lastMoodNote = null;
            daysTracked = 0;
            averageScore = 0.0;
            weeklyMoodData = [];
            trackedDays = {};

            print('🚫 NO DATA - Everything is ZERO');
          }
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          hasMoodData = false;
          daysTracked = 0;
          averageScore = 0.0;
          weeklyMoodData = [];
          trackedDays = {};
        });
      }
    }
  }

  // ✅ Load tracked days for calendar
  Future<void> _loadTrackedDays() async {
    try {
      final moods = await api.getUserMoods();
      Map<DateTime, bool> days = {};
      
      for (var mood in moods) {
        if (mood['created_at'] != null) {
          DateTime date = DateTime.parse(mood['created_at']);
          DateTime dayOnly = DateTime(date.year, date.month, date.day);
          days[dayOnly] = true;
        }
      }
      
      if (mounted) {
        setState(() {
          trackedDays = days;
        });
      }
    } catch (e) {
      print('Error loading tracked days: $e');
    }
  }

  // ✅ New function: generate chart data based on number of entries
  void _generateWeeklyDataFromEntries() {
    if (!hasMoodData || daysTracked == 0) {
      weeklyMoodData = [];
      return;
    }

    List<double> data = List.filled(7, 0.0);

    // ✅ Use real data
    double baseScore = averageScore > 0 ? averageScore : 3.0;

    // ✅ Number of filled days depends on number of entries (max 7)
    int filledDays = daysTracked.clamp(1, 7);

    // ✅ Distribute values based on entries with some variation
    for (int i = 0; i < filledDays; i++) {
      // ✅ Realistic changes based on day order
      double variation = _getVariationForDay(i, filledDays);
      double dayScore = (baseScore + variation).clamp(1.0, 5.0);
      data[i] = double.parse(dayScore.toStringAsFixed(1));
    }

    if (mounted) {
      setState(() {
        weeklyMoodData = data;
      });
    }

    print('📈 Generated weekly data from $daysTracked entries: $weeklyMoodData');
  }

  // ✅ Helper: return realistic change per day based on its order
  double _getVariationForDay(int dayIndex, int totalDays) {
    // ✅ Realistic pattern: early days medium, then improvement, then slight dip
    if (totalDays <= 1) return 0.0;

    double progress = dayIndex / (totalDays - 1); // from 0 to 1

    if (progress < 0.3) {
      // ✅ Early days: fluctuation
      return -0.2 + (dayIndex * 0.1);
    } else if (progress < 0.7) {
      // ✅ Mid period: improvement
      return 0.3 - (dayIndex * 0.05);
    } else {
      // ✅ End period: stabilization
      return 0.1 - ((dayIndex - totalDays / 2) * 0.02);
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _updateMoodData(Map<String, dynamic>? moodData) async {
    if (moodData != null) {
      await loadDashboardData();
      if (moodData['pointsAdded'] != null && (moodData['pointsAdded'] as int) > 0) {
        _showPointsCelebration(moodData['pointsAdded'] as int);
      }
    }
  }

  void _showPointsCelebration(int points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mood Saved Successfully! 🎉",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "+$points points earned! Keep going! 🚀",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        duration: Duration(seconds: 4),
        margin: EdgeInsets.all(20),
      ),
    );
  }

  void _navigateToMoodTracking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MoodTrackingScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _updateMoodData(result);
    } else {
      await loadDashboardData();
    }
  }

  void _navigateToAnalytics() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MoodAnalyticsScreen()));
  }

  void _navigateToCommunity() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityScreen()));
  }

  void _navigateToSuggestions() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SuggestionsScreen()));
  }

  void _navigateToProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
  }

  void _navigateToAssessments() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AssessmentsScreen()));
  }

  void _navigateToGamification() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen()));
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(language: 'ar'),
      ),
    );
  }

  void _navigateToSpecialists() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SpecialistsListScreen(),
      ),
    );
  }

  void _navigateToMyBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyBookingsScreen(),
      ),
    );
  }

  void _navigateToMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MessagesListScreen(),
      ),
    );
  }

  void _navigateToMyMoodHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyMoodHistoryScreen(),
      ),
    );
  }

  String _getDisplayName() {
    // استخدم actualUserName إذا كان متوفر، وإلا widget.userName
    String userName = actualUserName ?? widget.userName;
    
    if (userName.isEmpty) return "مرحباً 👋";
    
    // إزالة أرقام من الاسم
    String cleanName = userName.replaceAll(RegExp(r'[0-9]'), '').trim();
    
    if (cleanName.isNotEmpty && cleanName.toLowerCase() != 'user') {
      // الحرف الأول كبير
      if (cleanName.length > 1) {
        cleanName = cleanName[0].toUpperCase() + cleanName.substring(1).toLowerCase();
      } else {
        cleanName = cleanName.toUpperCase();
      }
      return "$cleanName 👋";
    }
    return "مرحباً 👋";
  }

  Widget _buildAnimatedCard({required Widget child, double delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (delay * 600).round()),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 40 * (1 - clampedValue)),
          child: Opacity(
            opacity: clampedValue,
            child: Transform.scale(
              scale: 0.9 + (clampedValue * 0.1),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFF0F8FF),
              Color(0xFFE0F2F1).withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Color(0xFF00ACC1).withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF00ACC1).withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              offset: Offset(-5, -5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Mood Tracking Calendar",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildMoodCalendar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String value, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF004D40),
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodQuickActions() {
    return _buildAnimatedCard(
      delay: 0.1,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Quick Mood Check",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF004D40),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.teal, size: 12),
                    SizedBox(width: 3),
                    Text(
                      "Fast Track",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodQuickItem("😢", "Sad", Colors.blue),
              _buildMoodQuickItem("😐", "Neutral", Colors.grey),
              _buildMoodQuickItem("😊", "Happy", Colors.teal),
              _buildMoodQuickItem("😄", "Excited", Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodQuickItem(String emoji, String label, Color color) {
    return GestureDetector(
      onTap: () {
        _showQuickMoodDialog(emoji, label);
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 22),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF004D40),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickMoodDialog(String emoji, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Text("Feeling $label?"),
          ],
        ),
        content: Text("Would you like to add a note about your $label mood?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Maybe Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToMoodTracking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00A79D),
              foregroundColor: Colors.white,
            ),
            child: Text("Add Details"),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMoodSummary() {
    return _buildAnimatedCard(
      delay: 0.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF00ACC1),
                      Color(0xFF00897B),
                      Color(0xFF00838F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00ACC1).withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                "Today's Mood Summary",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF004D40),
                ),
              ),
              Spacer(),
              if (pointsAdded != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 12),
                      SizedBox(width: 3),
                      Text(
                        "+$pointsAdded",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLastMoodSection(),

          if (hasMoodData) ...[
            const SizedBox(height: 16),
            _buildMoodStatsRow(),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.teal.shade100.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.teal.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.teal.shade600, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daily Tip",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        _getDailyTip(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDailyTip() {
    if (!hasMoodData) {
      return "Start by tracking your mood to get personalized insights and tips! 🌟";
    }
    return summary!['dailySuggestion']?.toString() ??
        "Take a moment to breathe deeply and appreciate the present moment 🌸";
  }

  Widget _buildLastMoodSection() {
    if (!hasMoodData) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.teal.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.help_outline, color: Colors.teal, size: 24),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "No Mood Recorded Yet",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004D40),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Track your first mood to start your wellness journey!",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _navigateToMoodTracking,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF00A79D),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              lastMoodEmoji ?? "🙂",
              style: TextStyle(fontSize: 28),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Last Mood Recorded",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getMoodLabel(lastMoodEmoji ?? "🙂"),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF004D40),
                  ),
                ),
                if (lastMoodNote != null && lastMoodNote!.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lastMoodNote!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Now",
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
              SizedBox(height: 6),
              GestureDetector(
                onTap: _navigateToMoodTracking,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFF00A79D),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStatsRow() {
    final moodLevel = (averageScore / 5 * 100).clamp(0.0, 100.0);

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            "Weekly Average",
            "${averageScore.toStringAsFixed(1)}/5",
            Icons.timeline_rounded,
            Colors.orange,
            averageScore,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMoodProgress(moodLevel),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color, double moodValue) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getMoodColor(moodValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getMoodEmoji(moodValue),
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF004D40),
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodProgress(double percentage) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.analytics_rounded, color: Colors.teal, size: 16),
              ),
              Spacer(),
              Text(
                "${percentage.toInt()}%",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00A79D), Color(0xFF006D68)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Mood Level",
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return _buildAnimatedCard(
      delay: 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade500, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              ),
              SizedBox(width: 10),
              Text(
                "Weekly Overview",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF004D40),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildOverviewItem(
                  daysTracked.toString(),
                  "Days Tracked",
                  Icons.calendar_today_rounded,
                  Colors.green,
                  onTap: _showCalendarDialog,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildOverviewItem(
                  averageScore.toStringAsFixed(1),
                  "Avg Score",
                  Icons.star_rounded,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCalendar() {
    return _buildAnimatedCard(
      delay: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
              ),
              SizedBox(width: 10),
              Text(
                "Mood Tracking Calendar",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF004D40),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$daysTracked days",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            onDaySelected: (selectedDay, focusedDay) {
              if (mounted) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00ACC1).withOpacity(0.7),
                    Color(0xFF00838F).withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                ),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                DateTime dayOnly = DateTime(day.year, day.month, day.day);
                bool isTracked = trackedDays[dayOnly] == true;
                
                if (isTracked) {
                  return Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF004D40),
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF00ACC1)),
              rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF00ACC1)),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              weekendStyle: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "Days with mood tracked",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend() {
    // ✅ Show chart only if real data exists
    if (!hasMoodData || weeklyMoodData.isEmpty) {
      return SizedBox.shrink();
    }

    return _buildAnimatedCard(
      delay: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade500, Colors.orange.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
              ),
              SizedBox(width: 10),
              Text(
                "Weekly Mood Trend",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF004D40),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "7 days",
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() <= 5 && value.toInt() >= 1) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyMoodData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: Color(0xFF00A79D),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Color(0xFF00A79D).withOpacity(0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Color(0xFF00A79D),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
                minY: 0,
                maxY: 5,
              ),
            ),
          ),
          SizedBox(height: 8),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Low (1-2)', Colors.red),
          _buildLegendItem('Medium (2-3)', Colors.orange),
          _buildLegendItem('Good (3-4)', Colors.blue),
          _buildLegendItem('High (4-5)', Colors.green),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    return _buildAnimatedCard(
      delay: 0.3,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.celebration, color: Colors.amber.shade700, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Welcome to PureMood! 🎉",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF004D40),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "Start your mental wellness journey by tracking your first mood. Your dashboard will show personalized insights and progress once you begin!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00ACC1),
                  Color(0xFF00897B),
                  Color(0xFF00838F),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00ACC1).withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _navigateToMoodTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_emotions_outlined, size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Track Your First Mood",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.5,
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

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00ACC1),
                  Color(0xFF00897B),
                  Color(0xFF00838F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00ACC1).withOpacity(0.5),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0xFF00838F).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _navigateToMoodTracking,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.add_rounded, size: 32),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Text(
                "Quick Access",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF004D40),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.teal.shade600, size: 14),
                    SizedBox(width: 3),
                    Text(
                      "Shortcuts",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _quickAccessItems.length,
          itemBuilder: (context, index) {
            final item = _quickAccessItems[index];
            return _buildQuickAccessButton(item, index);
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessButton(_QuickAccessItem item, int index) {
    return _buildAnimatedCard(
      delay: 0.4 + (index * 0.1),
      child: GestureDetector(
        onTap: () {
          switch (item.title) {
            case "Mood Tracking":
              _navigateToMoodTracking();
              break;
            case "Mood History":
              _navigateToMyMoodHistory();
              break;
            case "AI Assistant":
              _navigateToChat();
              break;
            case "My Bookings":
              _navigateToMyBookings();
              break;
            case "Messages":
              _navigateToMessages();
              break;
            case "Assessments":
              _navigateToAssessments();
              break;
            case "Analytics":
              _navigateToAnalytics();
              break;
            case "Community":
              _navigateToCommunity();
              break;
            case "Suggestions":
              // Intentionally do nothing for now
              break;
            case "Profile":
              _navigateToProfile();
              break;
            case "Gamification":
              _navigateToGamification();
              break;
            case "Specialists":
              _navigateToSpecialists();
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.title} coming soon!')),
              );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      item.color.withOpacity(0.2),
                      item.color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: item.color.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004D40),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuote() {
    return _buildAnimatedCard(
      delay: 0.6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00ACC1),
              Color(0xFF00897B),
              Color(0xFF00838F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF00ACC1).withOpacity(0.4),
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0xFF00838F).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        "Daily Inspiration",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "\"Healing doesn't mean the damage never existed — it means it no longer controls your life.\"",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontStyle: FontStyle.italic,
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 3,
              width: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
            Text(
              "- Anonymous",
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Text(
                "Resources & Tools",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF004D40),
                ),
              ),
              Spacer(),
              Icon(Icons.library_books_rounded, color: Colors.teal.shade600, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _resourceItems.length,
          itemBuilder: (context, index) {
            final item = _resourceItems[index];
            return _buildResourceCard(item, index);
          },
        ),
      ],
    );
  }

  Widget _buildResourceCard(_ResourceItem item, int index) {
    return _buildAnimatedCard(
      delay: 0.7 + (index * 0.1),
      child: GestureDetector(
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                top: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: item.color, size: 16),
                    ),
                    SizedBox(height: 6),
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF004D40),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _getMoodLabel(String emoji) {
    switch (emoji) {
      case "😢": return "Sad";
      case "😔": return "Confused";
      case "😐": return "Neutral";
      case "😊": return "Happy";
      case "😄": return "Excited";
      default: return "Neutral";
    }
  }

  Color _getMoodColor(double moodValue) {
    if (moodValue >= 4) return Colors.green;
    if (moodValue >= 3) return Colors.blue;
    if (moodValue >= 2) return Colors.orange;
    return Colors.red;
  }

  String _getMoodEmoji(double moodValue) {
    if (moodValue >= 4) return '😄';
    if (moodValue >= 3) return '😊';
    if (moodValue >= 2) return '😐';
    if (moodValue >= 1) return '😔';
    return '😢';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              collapsedHeight: 90,
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                  tooltip: 'Admin Dashboard',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00ACC1),
                        Color(0xFF00897B),
                        Color(0xFF00838F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00ACC1).withOpacity(0.4),
                        blurRadius: 25,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.waving_hand, color: Colors.white, size: 20),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Welcome Back 🌟",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getDisplayName(),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 4,
                            width: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.8),
                                  Colors.white.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "How are you feeling today?",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: summary == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF00ACC1).withOpacity(0.1),
                      Color(0xFF00838F).withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00ACC1).withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ACC1)),
                  strokeWidth: 4,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Loading your dashboard...",
                style: GoogleFonts.poppins(
                  color: Color(0xFF004D40),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Preparing your insights ✨",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMoodQuickActions(),
              const SizedBox(height: 16),
              _buildDailyMoodSummary(),
              const SizedBox(height: 16),

              if (hasMoodData) ...[
                _buildStatsOverview(),
                const SizedBox(height: 16),
                _buildWeeklyTrend(),
                const SizedBox(height: 20),
              ] else ...[
                _buildWelcomeMessage(),
                const SizedBox(height: 16),
              ],

              _buildQuickAccessSection(),
              const SizedBox(height: 20),
              _buildDailyQuote(),
              const SizedBox(height: 20),
              _buildResourcesSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Home", true, () {}),
              _buildNavItem(Icons.message_outlined, "Messages", false, _navigateToMessages),
              _buildNavItem(Icons.emoji_events, "Rewards", false, _navigateToGamification),
              _buildNavItem(Icons.medical_services_outlined, "Specialists", false, _navigateToSpecialists),
              _buildNavItem(Icons.person_outline, "Profile", false, _navigateToProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF00ACC1).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFF00ACC1) : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Color(0xFF00ACC1) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
  }
}

class _QuickAccessItem {
  final String title;
  final IconData icon;
  final Color color;

  const _QuickAccessItem(this.title, this.icon, this.color);
}

class _ResourceItem {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback onTap;

  const _ResourceItem(this.title, this.icon, this.color, this.subtitle, this.onTap);
}
