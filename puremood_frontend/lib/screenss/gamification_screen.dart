import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gamification_service.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({Key? key}) : super(key: key);

  @override
  _GamificationScreenState createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  final GamificationService _service = GamificationService();

  Map<String, dynamic>? userStats;
  bool isLoading = true;
  bool hasError = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<bool> _badgeAnimations = [];
  int _currentBadgeIndex = 0;
  bool _showCelebration = false;
  bool _showBadgeSection = false;

  @override
  void initState() {
    super.initState();
    print('🚀 Loading achievements data...');

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final stats = await _service.getUserStats();

      if (mounted) {
        setState(() {
          userStats = stats;
          isLoading = false;
        });

        _animationController.forward();

        Future.delayed(Duration(milliseconds: 1200), () {
          _startSequentialBadgeAnimations();
        });
      }

      print('📊 Updated data:');
      print('   Points: ${stats['totalPoints']}');
      print('   Badges: ${stats['badgesCount']}');
      print('   Active Challenges: ${stats['activeChallenges']}');
      print('   Completed Challenges: ${stats['completedChallenges']}');

    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  void _startSequentialBadgeAnimations() {
    final badges = userStats?['userBadges'] ?? [];
    if (badges.isEmpty) return;

    _badgeAnimations = List.generate(badges.length, (index) => false);
    setState(() => _showBadgeSection = true);

    Future.delayed(Duration(milliseconds: 500), () {
      for (int i = 0; i < badges.length; i++) {
        Future.delayed(Duration(milliseconds: 400 * i), () {
          if (mounted) setState(() {
            _badgeAnimations[i] = true;
            _currentBadgeIndex = i;
          });
        });
      }

      // Final fix for conversion bug - use toInt() correctly
      Future.delayed(Duration(milliseconds: (400 * badges.length).toInt()), () {
        if (mounted) setState(() => _showCelebration = true);
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) setState(() => _showCelebration = false);
        });
      });
    });
  }

  Future<void> _initializeChallenges() async {
    try {
      await _service.initializeUserChallenges();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenges started successfully! 🚀'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting challenges: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      await _service.updateChallengesProgress();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress updated! ✨'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _fixChallenges() async {
    try {
      await _service.fixCurrentChallenges();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenges fixed with original system! 🎯'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error fixing challenges: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xfff3f9f8),
      appBar: AppBar(
        title: Text('My Achievements 🏆', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color(0xFF00A79D),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context)
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _refreshData
          ),
          IconButton(
              icon: Icon(Icons.build_rounded, color: Colors.white),
              onPressed: _fixChallenges
          ),
        ],
      ),
      body: Stack(children: [
        _buildBody(),
        if (_showCelebration) _buildCelebrationEffects()
      ]),
    );
  }

  Widget _buildCelebrationEffects() {
    return IgnorePointer(
      child: Container(
        child: Column(children: [
          Expanded(child: Stack(children: [
            _buildFloatingEmoji('🎉', 0.1, 1000),
            _buildFloatingEmoji('⭐', 0.3, 1200),
            _buildFloatingEmoji('🏆', 0.5, 1400),
            _buildFloatingEmoji('👏', 0.7, 1600),
          ])),
          Container(margin: EdgeInsets.only(bottom: 100), child: _buildCelebrationMessage()),
        ]),
      ),
    );
  }

  Widget _buildFloatingEmoji(String emoji, double left, int duration) {
    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: -50,
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: duration),
        tween: Tween<double>(begin: 0.0, end: MediaQuery.of(context).size.height),
        builder: (context, value, child) {
          final screenHeight = MediaQuery.of(context).size.height;
          final baseHeight = screenHeight == 0 ? 1.0 : screenHeight;
          final rawOpacity = 1 - (value / baseHeight);
          final safeOpacity = rawOpacity.isNaN
              ? 0.0
              : rawOpacity.clamp(0.0, 1.0).toDouble();

          return Transform.translate(
            offset: Offset(0, value),
            child: Opacity(
              opacity: safeOpacity,
              child: Text(emoji, style: TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCelebrationMessage() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.elasticOut)
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          color: Colors.amber.withOpacity(0.9),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                        'Congratulations!',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14
                        )
                    ),
                  ]
              )
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return _buildLoadingState();
    if (hasError) return _buildErrorState();
    return FadeTransition(opacity: _fadeAnimation, child: _buildMainContent());
  }

  Widget _buildLoadingState() {
    return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A79D))
          ),
          SizedBox(height: 20),
          Text(
              'Loading your achievements...',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Color(0xFF004D40),
                  fontWeight: FontWeight.w600
              )
          ),
        ]
    ));
  }

  Widget _buildErrorState() {
    return Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
              SizedBox(height: 20),
              Text(
                  'Error loading data',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Color(0xFF004D40),
                      fontWeight: FontWeight.w700
                  )
              ),
              SizedBox(height: 12),
              Text(
                  'Check your internet connection and try again',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600
                  )
              ),
              SizedBox(height: 25),
              ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00A79D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12)
                  ),
                  child: Text(
                      'Try Again',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)
                  )
              ),
            ]
        )
    ));
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      backgroundColor: Color(0xFF00A79D),
      color: Colors.white,
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(delegate: SliverChildListDelegate([
            SizedBox(height: 16),
            _buildPointsCard(),
            SizedBox(height: 16),
            _buildStatsGrid(),
            SizedBox(height: 16),
          ])),
          if (_showBadgeSection) SliverToBoxAdapter(child: _buildBadgesSection()),
          SliverToBoxAdapter(child: Column(children: [
            SizedBox(height: 16),
            _buildChallengesSection(),
            SizedBox(height: 16)
          ])),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    final totalPoints = userStats?['totalPoints'] ?? 0;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4)
          )
        ],
      ),
      child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                  'Total Points',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700
                  )
              ),
            ]
        ),
        SizedBox(height: 8),
        Text(
            '$totalPoints',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w800
            )
        ),
        SizedBox(height: 6),
        Text(
            totalPoints >= 100 ?
            'Amazing! You are the points champion 👑' :
            totalPoints >= 50 ?
            'Keep going! You are awesome 🌟' :
            'Start your journey towards achievements! 🚀',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500
            )
        ),
      ]),
    );
  }

  Widget _buildStatsGrid() {
    final badgesCount = userStats?['badgesCount'] ?? 0;
    final activeChallenges = userStats?['activeChallenges'] ?? 0;
    final completedChallenges = userStats?['completedChallenges'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _buildStatItem(badgesCount.toString(), 'Badges', Icons.workspace_premium_rounded, Colors.blue),
        SizedBox(width: 10),
        _buildStatItem(activeChallenges.toString(), 'Active', Icons.flag_rounded, Colors.green),
        SizedBox(width: 10),
        _buildStatItem(completedChallenges.toString(), 'Completed', Icons.check_circle_rounded, Colors.purple),
      ]),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 3)
            )
          ]
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle
                ),
                child: Icon(icon, color: color, size: 18)
            ),
            SizedBox(height: 6),
            Text(
                value,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF004D40)
                )
            ),
            Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500
                )
            ),
          ]
      ),
    ));
  }

  Widget _buildBadgesSection() {
    final badges = userStats?['userBadges'] ?? [];
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 3)
            )
          ]
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.workspace_premium_rounded, color: Color(0xFF00A79D), size: 20),
              SizedBox(width: 6),
              Text(
                  'My Badges 🏆',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF004D40)
                  )
              ),
              Spacer(),
              if (badges.isNotEmpty) Text(
                  '${_currentBadgeIndex + 1}/${badges.length}',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600
                  )
              ),
            ]),
            SizedBox(height: 12),
            if (badges.isEmpty)
              _buildEmptyState(
                  'No badges yet',
                  'Complete challenges to earn amazing badges!',
                  Icons.emoji_events_outlined
              )
            else
              Container(
                height: screenHeight * 0.22,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.9
                  ),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: badges.length,
                  itemBuilder: (context, index) => _buildSequentialBadgeItem(badges[index], index),
                ),
              ),
          ]
      ),
    );
  }

  Widget _buildSequentialBadgeItem(Map<String, dynamic> badge, int index) {
    bool isAnimated = index < _badgeAnimations.length && _badgeAnimations[index];
    return AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        transform: Matrix4.identity()..scale(isAnimated ? 1.0 : 0.5),
        child: AnimatedOpacity(
            duration: Duration(milliseconds: 400),
            opacity: isAnimated ? 1.0 : 0.0,
            child: _buildBadgeItemContent(badge)
        )
    );
  }

  Widget _buildBadgeItemContent(Map<String, dynamic> badge) {
    final badgeData = badge['Badge'] ?? badge;
    final badgeName = badgeData['name']?.toString() ?? 'Badge';
    final badgeDesc = badgeData['description']?.toString() ?? '';

    return Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200, width: 1.5)
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle
                  ),
                  child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.amber.shade700,
                      size: 18
                  )
              ),
              SizedBox(height: 4),
              Text(
                  badgeName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF004D40)
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis
              ),
              if (badgeDesc.isNotEmpty) ...[
                SizedBox(height: 2),
                Text(
                    badgeDesc,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 7,
                        color: Colors.grey.shade600
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis
                )
              ],
            ]
        )
    );
  }

  Widget _buildChallengesSection() {
    final challenges = userStats?['userChallenges'] ?? [];
    List<dynamic> activeChallenges = challenges.where((c) =>
    (c['completed'] == false || c['completed'] == 0 || c['completed'] == null)
    ).toList();
    List<dynamic> completedChallenges = challenges.where((c) =>
    (c['completed'] == true || c['completed'] == 1)
    ).toList();

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.teal.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3)
              )
            ]
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.flag_rounded, color: Color(0xFF00A79D), size: 20),
                SizedBox(width: 6),
                Text(
                    'My Challenges 🚀',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF004D40)
                    )
                ),
                Spacer(),
                if (challenges.isEmpty) IconButton(
                    onPressed: _initializeChallenges,
                    icon: Icon(Icons.add_circle_rounded, color: Color(0xFF00A79D), size: 20),
                    tooltip: 'Start Challenges'
                ),
              ]),
              SizedBox(height: 12),
              if (challenges.isEmpty)
                _buildEmptyState(
                    'No challenges',
                    'Start your journey with challenges to earn points and badges!',
                    Icons.flag_outlined,
                    showButton: true
                )
              else
                Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeChallenges.isNotEmpty) ...[
                        Text(
                            'Active Challenges (${activeChallenges.length})',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00A79D)
                            )
                        ),
                        SizedBox(height: 8),
                        ...activeChallenges.map((challenge) => _buildChallengeItem(challenge, false)),
                        if (completedChallenges.isNotEmpty) SizedBox(height: 16),
                      ],
                      if (completedChallenges.isNotEmpty) ...[
                        Text(
                            'Completed Challenges ✅ (${completedChallenges.length})',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.green
                            )
                        ),
                        SizedBox(height: 8),
                        ...completedChallenges.map((challenge) => _buildChallengeItem(challenge, true)),
                      ],
                    ]
                ),
            ]
        )
    );
  }

  Widget _buildChallengeItem(Map<String, dynamic> challenge, bool isCompleted) {
    final challengeData = challenge['Challenge'] ?? challenge;
    final progress = challenge['progress'] ?? 0;
    final challengeName = challengeData['name']?.toString() ?? 'Challenge';
    final challengeDesc = challengeData['description']?.toString() ?? '';

    final target = _getChallengeTarget(challengeName);
    final percentage = (progress / target).clamp(0.0, 1.0);

    return Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isCompleted ? Colors.green.shade200 : Colors.teal.shade200,
                width: 1.5
            )
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)
                    ),
                    child: Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.flag_rounded,
                        color: isCompleted ? Colors.green : Colors.teal,
                        size: 14
                    )
                ),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        challengeName,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF004D40)
                        )
                    )
                ),
                if (isCompleted) Icon(Icons.verified_rounded, color: Colors.green, size: 16),
              ]),
              if (challengeDesc.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                    challengeDesc,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis
                )
              ],
              SizedBox(height: 8),
              LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade200,
                  color: isCompleted ? Colors.green : Colors.teal,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2)
              ),
              SizedBox(height: 6),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Progress: $progress/$target',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600
                        )
                    ),
                    Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? Colors.green : Colors.teal
                        )
                    ),
                  ]
              ),
            ]
        )
    );
  }

  int _getChallengeTarget(String challengeName) {
    switch (challengeName) {
      case 'Week Challenge': return 7;
      case 'Mood Explorer': return 5;
      case 'Detail Champion': return 3;
      case 'Strong Start': return 3;
      case 'Positive Weekend': return 2;
      default: return 3;
    }
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, {bool showButton = false}) {
    return Container(
        padding: EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey.shade400, size: 48),
              SizedBox(height: 12),
              Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600
                  )
              ),
              SizedBox(height: 6),
              Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade500
                  )
              ),
              if (showButton) ...[
                SizedBox(height: 16),
                ElevatedButton(
                    onPressed: _initializeChallenges,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00A79D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                    ),
                    child: Text(
                        'Start Challenges Now',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)
                    )
                )
              ],
            ]
        )
    );
  }
}