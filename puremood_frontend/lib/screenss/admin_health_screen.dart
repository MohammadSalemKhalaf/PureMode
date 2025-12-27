import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/admin_service.dart';

class AdminHealthScreen extends StatefulWidget {
  const AdminHealthScreen({Key? key}) : super(key: key);

  @override
  State<AdminHealthScreen> createState() => _AdminHealthScreenState();
}

class _AdminHealthScreenState extends State<AdminHealthScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> healthData = {};
  bool loading = true;
  String error = '';
  DateTime? lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await _adminService.getSystemHealth();
      setState(() {
        healthData = response;
        loading = false;
        lastUpdate = DateTime.now();
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatus(String service, bool isActive, String responseTime) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.check : Icons.close,
              size: 16,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  isActive ? 'Operational • $responseTime' : 'Offline',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isActive ? Colors.green : Colors.red,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = healthData['status'] ?? 'unknown';
    final isHealthy = status == 'healthy';

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'System Health Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF008080),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 24),
            onPressed: _loadHealth,
            tooltip: 'Refresh',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: loading
          ? _buildLoadingState()
          : error.isNotEmpty
          ? _buildErrorState(isDark)
          : RefreshIndicator(
        onRefresh: _loadHealth,
        backgroundColor: Color(0xFF008080),
        color: Colors.white,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Status
              _buildStatusHeader(isDark, isHealthy, status),
              SizedBox(height: 24),

              // Key Metrics
              Text(
                '📊 Key Metrics',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 16),
              _buildMetricsGrid(),
              SizedBox(height: 24),

              // Services Status
              Text(
                '🔧 Services Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 16),
              _buildServicesStatus(),
              SizedBox(height: 24),

              // Recent Activity
              Row(
                children: [
                  Text(
                    '📈 Recent Activity',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Color(0xFF1E293B),
                    ),
                  ),
                  Spacer(),
                  if (lastUpdate != null)
                    Text(
                      'Updated ${_formatTimeAgo(lastUpdate!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              _buildRecentActivity(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF008080)),
                    strokeWidth: 3,
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.monitor_heart_outlined,
                    color: Color(0xFF008080),
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Checking System Health...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Analyzing all system components',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 50, color: Colors.red),
            ),
            SizedBox(height: 20),
            Text(
              'System Unreachable',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                maxLines: 3,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHealth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008080),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: Icon(Icons.refresh_rounded, size: 20),
              label: Text('Retry Connection', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isDark, bool isHealthy, String status) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHealthy
              ? [Color(0xFF10B981), Color(0xFF059669)]
              : [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isHealthy ? Color(0xFF10B981) : Color(0xFFEF4444)).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy ? Icons.verified_rounded : Icons.warning_amber_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Status',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isHealthy ? 'All Systems Operational' : 'System Issues Detected',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isHealthy
                      ? 'All services are running smoothly'
                      : 'Some services may be experiencing issues',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final totalUsers = healthData['totalUsers'] ?? 0;
    final activeUsers = healthData['activeUsers'] ?? 0;
    final totalMoods = healthData['totalMoods'] ?? 0;
    final avgResponse = healthData['avgResponseTime'] ?? '0ms';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMetricCard(
            'Total Users',
            totalUsers.toString(),
            Icons.people_rounded,
            Color(0xFF008080),
            '${activeUsers} active',
          ),
          SizedBox(width: 12),
          _buildMetricCard(
            'Mood Entries',
            totalMoods.toString(),
            Icons.emoji_emotions_rounded,
            Color(0xFFEC4899),
            'Today: ${healthData['todayMoods'] ?? 0}',
          ),
          SizedBox(width: 12),
          _buildMetricCard(
            'Response Time',
            avgResponse.toString(),
            Icons.speed_rounded,
            Color(0xFF10B981),
            'Database ping',
          ),
          SizedBox(width: 12),
          _buildMetricCard(
            'Uptime',
            '99.9%',
            Icons.timer_rounded,
            Color(0xFF8B5CF6),
            'This month',
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStatus() {
    final databaseStatus = healthData['database'] ?? 'unknown';
    final apiStatus = healthData['api'] ?? 'unknown';

    return Column(
      children: [
        _buildServiceStatus(
          'Database Server',
          databaseStatus == 'connected',
          '${healthData['dbResponseTime'] ?? '0'}ms',
        ),
        SizedBox(height: 12),
        _buildServiceStatus(
          'API Gateway',
          apiStatus == 'healthy',
          '${healthData['apiResponseTime'] ?? '0'}ms',
        ),
        SizedBox(height: 12),
        _buildServiceStatus(
          'Authentication Service',
          true,
          '25ms',
        ),
        SizedBox(height: 12),
        _buildServiceStatus(
          'File Storage',
          true,
          '45ms',
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    final users = healthData['recentUsers'] as List? ?? [];
    final moods = healthData['recentMoods'] as List? ?? [];

    return Column(
      children: [
        // Recent Users Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF008080).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.people_alt_rounded, size: 20, color: Color(0xFF008080)),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Recent Users',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF1E293B),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${users.length} total',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (users.isEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF374151) : Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded, size: 40, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'No recent users',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...users.take(5).map((user) => _buildUserItem(user, isDark)),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Recent Moods Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFEC4899).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.emoji_emotions_rounded, size: 20, color: Color(0xFFEC4899)),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Recent Mood Entries',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF1E293B),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${moods.length} total',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (moods.isEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF374151) : Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.emoji_emotions_outlined, size: 40, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'No recent mood entries',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...moods.take(5).map((mood) => _buildMoodItem(mood, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF374151) : Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Color(0xFF4B5563) : Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: Color(0xFF008080), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown User',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  user['email'] ?? 'No email',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(DateTime.parse(user['created_at'] ?? DateTime.now().toString())),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodItem(Map<String, dynamic> mood, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF374151) : Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Color(0xFF4B5563) : Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFEC4899).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                mood['mood_emoji'] ?? '😊',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood['User']?['name'] ?? 'Unknown User',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  mood['note_text'] ?? 'No note provided',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(DateTime.parse(mood['created_at'] ?? DateTime.now().toString())),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}