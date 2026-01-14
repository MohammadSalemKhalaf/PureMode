import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mood_service.dart';
import '../services/smart_suggestions_service.dart';
import '../services/user_subscription_service.dart';
import 'premium_subscription_screen.dart';

class SmartSuggestionsScreen extends StatefulWidget {
  final Map<String, dynamic>? currentMoodData;

  const SmartSuggestionsScreen({super.key, this.currentMoodData});

  @override
  State<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends State<SmartSuggestionsScreen> {
  final SmartSuggestionsService _suggestionsService = SmartSuggestionsService();
  final UserSubscriptionService _subscriptionService = UserSubscriptionService();
  final MoodService _moodService = MoodService();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  bool _isPremiumUser = false;
  int _trialDaysLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndSuggestions();
  }

  Future<void> _loadUserDataAndSuggestions() async {
    try {
      // Get user status
      _isPremiumUser = await _subscriptionService.isPremiumUser();
      _trialDaysLeft = await _subscriptionService.getTrialDaysLeft();

      // Get mood history
      final moodHistory = await _moodService.getMoodHistory();

      // Get suggestions
      final suggestions = _suggestionsService.getSuggestionsForMood(
        widget.currentMoodData?['moodLabel'] ?? 'Neutral',
        widget.currentMoodData?['note'] ?? '',
        moodHistory,
        _isPremiumUser,
      );

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading suggestions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showPremiumLockDialog(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 10),
            Text('Premium Feature', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This feature requires Premium subscription',
                style: GoogleFonts.poppins()),
            SizedBox(height: 10),
            Text(suggestion['premiumDescription'] ?? 'Access advanced features and professional support',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Upgrade to unlock ${_suggestionsService.getTotalPremiumSuggestionsCount()}+ premium features',
                        style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Not Now', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPremiumScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: Text('Go Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _navigateToPremiumScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PremiumSubscriptionScreen()),
    );

    if (result == true) {
      // If user purchased subscription, reload data
      await _loadUserDataAndSuggestions();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF00897B)),
          SizedBox(height: 16),
          Text('Analyzing your mood and preparing suggestions...',
              style: GoogleFonts.poppins(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No suggestions available currently',
              style: GoogleFonts.poppins(fontSize: 18)),
          SizedBox(height: 8),
          Text('Record your mood to get personalized suggestions',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final moodLabel = widget.currentMoodData?['moodLabel'] ?? 'current';
    final emoji = widget.currentMoodData?['emoji'] ?? '😊';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: TextStyle(fontSize: 24)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personalized Suggestions',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                          )),
                      Text('For your $moodLabel mood',
                          style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14
                          )),
                    ],
                  ),
                ),
                if (_isPremiumUser)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium, size: 16, color: Colors.black),
                        SizedBox(width: 4),
                        Text('PREMIUM',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black
                            )),
                      ],
                    ),
                  ),
              ],
            ),
            if (_trialDaysLeft > 0) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text('Free Trial: $_trialDaysLeft days left',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion, int index) {
    final bool isPremium = suggestion['isPremium'] == true;
    final bool canAccess = _isPremiumUser || !isPremium;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => canAccess
              ? _showSuggestionDetails(suggestion)
              : _showPremiumLockDialog(suggestion),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with lock if premium feature
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: suggestion['color'].withOpacity(canAccess ? 0.1 : 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(suggestion['icon'],
                          color: canAccess ? suggestion['color'] : Colors.grey,
                          size: 24),
                    ),
                    if (!canAccess)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.lock, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(suggestion['title'],
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: canAccess ? Color(0xFF00695C) : Colors.grey
                                )),
                          ),
                          if (!canAccess) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('PREMIUM',
                                  style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold
                                  )),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(suggestion['description'],
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: canAccess ? Colors.grey.shade700 : Colors.grey
                          )),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(suggestion['duration'],
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey
                              )),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: suggestion['color'].withOpacity(canAccess ? 0.1 : 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(suggestion['category'],
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: canAccess ? suggestion['color'] : Colors.grey,
                                    fontWeight: FontWeight.bold
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                // Arrow
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: canAccess ? Colors.grey.shade400 : Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuggestionDetails(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: suggestion['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(suggestion['icon'], color: suggestion['color']),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(suggestion['title'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion['description'],
                style: GoogleFonts.poppins(fontSize: 14)),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(suggestion['duration'],
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: suggestion['color'].withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: suggestion['color'].withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 20, color: suggestion['color']),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('💡 ${suggestion['reason']}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: suggestion['color']
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start the activity
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Started activity: ${suggestion['title']}',
                      style: GoogleFonts.poppins()),
                  backgroundColor: suggestion['color'],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Start Now', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Column(
      children: [
        // Header
        _buildHeader(),
        SizedBox(height: 8),

        // Suggestions count and premium info
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text('${_suggestions.length} suggestions available',
                  style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12
                  )),
              Spacer(),
              if (!_isPremiumUser)
                GestureDetector(
                  onTap: _navigateToPremiumScreen,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium, size: 12, color: Colors.amber),
                        SizedBox(width: 4),
                        Text('Go Premium',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8),

        // Suggestions list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              return _buildSuggestionCard(_suggestions[index], index);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('Personalized Suggestions',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF00897B),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isPremiumUser)
            IconButton(
              icon: Icon(Icons.workspace_premium, color: Colors.amber),
              onPressed: _navigateToPremiumScreen,
              tooltip: 'Go Premium',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _suggestions.isEmpty
          ? _buildEmptyState()
          : _buildSuggestionsList(),
    );
  }
}