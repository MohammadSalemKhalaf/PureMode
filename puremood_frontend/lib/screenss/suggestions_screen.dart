import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: const Color(0xFFEFF5F5),
      appBar: AppBar(
        title: Text('Wellness Suggestions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌟 Daily Wellness Tips',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Personalized suggestions to improve your mental health',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 25),

            _buildSuggestionCard(
              context,
              'Breathing Exercise',
              'Take 5 minutes for deep breathing to reduce stress',
              Icons.air_rounded,
              Colors.blue,
              'Try the 4-7-8 technique: breathe in for 4 seconds, hold for 7, exhale for 8.',
            ),
            _buildSuggestionCard(
              context,
              'Mindful Meditation',
              'Practice 10 minutes of mindfulness today',
              Icons.self_improvement_rounded,
              Colors.purple,
              'Find a quiet space, close your eyes, and focus on your breath.',
            ),
            _buildSuggestionCard(
              context,
              'Physical Activity',
              'Get moving with a 15-minute walk or workout',
              Icons.directions_walk_rounded,
              Colors.green,
              'Exercise releases endorphins that boost your mood naturally.',
            ),
            _buildSuggestionCard(
              context,
              'Gratitude Journal',
              'Write down 3 things you\'re grateful for',
              Icons.book_rounded,
              Colors.orange,
              'Focusing on gratitude can shift your perspective positively.',
            ),
            _buildSuggestionCard(
              context,
              'Connect with Others',
              'Reach out to a friend or family member',
              Icons.people_rounded,
              Colors.pink,
              'Social connections are vital for emotional wellbeing.',
            ),
            _buildSuggestionCard(
              context,
              'Healthy Sleep',
              'Aim for 7-9 hours of quality sleep tonight',
              Icons.bedtime_rounded,
              Colors.indigo,
              'Good sleep is essential for mental and physical health.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String details,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF004D40),
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  details,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Got it!',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF008080),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF004D40),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
