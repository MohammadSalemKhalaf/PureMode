import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/api_service.dart';
import 'package:puremood_frontend/screenss/DashboardScreen.dart';

class HomeScreen extends StatefulWidget {
  final int? userId; // ✅ Add userId
  const HomeScreen({super.key, this.userId}); // ✅ Init
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiService();
  String userName = '';
  bool _streakLoading = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _streakGoalDays = 7;
  DateTime? _lastMoodDate;

  @override
  void initState() {
    super.initState();
    loadUser();
    _loadMoodStreak();
  }

  // Fetch user data from API
  void loadUser() async {
    if (widget.userId == null) return; // Ensure userId exists
    final user = await api.getUserById(widget.userId!); // Use function to get user by id
    if (user != null) {
      setState(() {
        userName = user['name'] ?? '';
      });
    }
  }

  Future<void> _loadMoodStreak() async {
    try {
      final moods = await api.getUserMoods();
      if (!mounted) return;

      if (moods.isEmpty) {
        setState(() {
          _streakLoading = false;
          _currentStreak = 0;
          _longestStreak = 0;
          _lastMoodDate = null;
        });
        return;
      }

      final dateSet = <DateTime>{};
      for (final mood in moods) {
        final rawDate = (mood['created_at'] ?? mood['createdAt'])?.toString();
        if (rawDate == null) continue;
        final parsed = DateTime.tryParse(rawDate);
        if (parsed == null) continue;
        final local = parsed.toLocal();
        dateSet.add(DateTime(local.year, local.month, local.day));
      }

      if (dateSet.isEmpty) {
        setState(() {
          _streakLoading = false;
          _currentStreak = 0;
          _longestStreak = 0;
          _lastMoodDate = null;
        });
        return;
      }

      final dates = dateSet.toList()..sort();
      final latest = dates.last;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      int currentStreak = 0;
      if (latest == today) {
        var cursor = today;
        while (dateSet.contains(cursor)) {
          currentStreak += 1;
          cursor = cursor.subtract(const Duration(days: 1));
        }
      } else if (latest == yesterday) {
        currentStreak = 0;
      }

      int longest = 1;
      int running = 1;
      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]).inDays;
        if (diff == 1) {
          running += 1;
        } else {
          running = 1;
        }
        if (running > longest) longest = running;
      }

      setState(() {
        _streakLoading = false;
        _currentStreak = currentStreak;
        _longestStreak = longest;
        _lastMoodDate = latest;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _streakLoading = false;
        _currentStreak = 0;
        _longestStreak = 0;
        _lastMoodDate = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Widget _buildMoodStreakCard() {
    final progress = (_currentStreak / _streakGoalDays).clamp(0.0, 1.0);
    final lastMoodText = _lastMoodDate == null
        ? 'No mood logged yet'
        : 'Last log: ${_formatDate(_lastMoodDate!)}';
    final statusText =
        _currentStreak == 0 ? 'Start a new streak today' : 'Keep your streak alive';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.teal.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.teal.withOpacity(0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_currentStreak',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004D40),
                    ),
                  ),
                  Text(
                    'days',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood Streak',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Longest streak: $_longestStreak days',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastMoodText,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: const Color(0xFFEFF5F5),
      appBar: AppBar(
        title: Text(
          'PureMood 🌿',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.self_improvement, size: 90, color: Colors.teal.shade400),
              const SizedBox(height: 30),
              Text(
                "Welcome, $userName 👋",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004D40),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Wishing you a calm and positive day 🌸",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _streakLoading
                  ? const SizedBox(
                      height: 86,
                      width: 86,
                      child: CircularProgressIndicator(),
                    )
                  : _buildMoodStreakCard(),
              const SizedBox(height: 30),
              // Button to navigate to Dashboard
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(userName: userName),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(Icons.home, color: Colors.white),
                label: Text(
                  "Go to Dashboard",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
