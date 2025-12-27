import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/admin_service.dart';
import 'package:puremood_frontend/services/api_service.dart';
import 'package:puremood_frontend/services/notification_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final ApiService _apiService = ApiService();
  Map<String, dynamic> stats = {};
  Map<String, dynamic>? userInfo;
  bool loading = true;
  String error = '';
  int notificationCount = 0;
  List<dynamic> realNotifications = []; // الإشعارات الحقيقية من API
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadUserInfo();
    _loadNotificationsCount();
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadNotificationsCount();
    });
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _apiService.getMe();
      setState(() => userInfo = user);
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await _adminService.getDashboardStats();
      setState(() {
        stats = response;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadNotificationsCount() async {
    try {
      print('🔔 Loading notifications count...');
      final prev = notificationCount;
      final stats = await _adminService.getNotificationStats();
      print('📊 Stats received: $stats');
      final unreadCount = stats['unread_count'] ?? 0;
      print('✅ Unread count: $unreadCount');
      if (!mounted) return;
      setState(() {
        notificationCount = unreadCount;
      });
      if (unreadCount > prev) {
        await showAdminRegistrationNotification(newCount: unreadCount - prev);
      } else if (unreadCount == 0 && prev > 0) {
        await cancelAdminRegistrationNotification();
      }
    } catch (e) {
      print('❌ Error loading notifications count: $e');
      // Do not call setState here to avoid setState after dispose
    }
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      await _adminService.markAllNotificationsAsRead();
      setState(() {
        notificationCount = 0;
      });
      await cancelAdminRegistrationNotification();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0A0F1C) : Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
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
          // زر الإشعارات
          _buildNotificationButton(),
          SizedBox(width: 8),

          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 24),
            onPressed: () {
              _loadStats();
              _loadNotificationsCount();
              _loadUserInfo();
            },
            tooltip: 'Refresh',
          ),
          SizedBox(width: 8),
          _buildProfileMenu(),
          SizedBox(width: 8),
        ],
      ),
      body: loading
          ? _buildLoadingState()
          : error.isNotEmpty
          ? _buildErrorState()
          : _buildDashboardContent(size, isDark),
    );
  }

  // زر الإشعارات الجديد مع Dropdown
  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, size: 24),
          onPressed: () {
            _showNotificationDropdown(context);
          },
          tooltip: 'الإشعارات',
        ),
        if (notificationCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEngagementSection(bool isDark) {
    final totalBadges = stats['totalBadges'] ?? 0;
    final totalChallenges = stats['totalChallenges'] ?? 0;
    final avgMood = stats['averageMoodScore'];

    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF718096);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Badges & Challenges',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalBadges badges • $totalChallenges challenges',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mood_rounded,
                    color: Color(0xFF3B82F6),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Mood',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avgMood == null
                            ? 'N/A'
                            : avgMood.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // عرض قائمة الإشعارات المنسدلة (مثل الفيس بوك)
  void _showNotificationDropdown(BuildContext context) async {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    // جلب الإشعارات من API
    try {
      final notifs = await _adminService.getNotifications(limit: 5);
      setState(() {
        realNotifications = notifs;
      });
      
      // ✅ تحديد كل الإشعارات كمقروءة تلقائياً عند فتح القائمة
      if (realNotifications.isNotEmpty) {
        await _adminService.markAllNotificationsAsRead();
        setState(() {
          notificationCount = 0; // العداد يروح فوراً
        });
        await cancelAdminRegistrationNotification();
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 320, // من اليمين
        offset.dy + 60, // تحت الـ AppBar
        20,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _buildNotificationDropdownContent(),
        ),
      ],
    ).then((_) {
      // عند إغلاق القائمة، تأكد إن العداد صفر
      _loadNotificationsCount();
    });
  }

  // محتوى القائمة المنسدلة
  Widget _buildNotificationDropdownContent() {
    return Container(
      width: 320,
      constraints: BoxConstraints(maxHeight: 450),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              'الإشعارات',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Notifications List
          Flexible(
            child: realNotifications.isEmpty
                ? _buildEmptyNotifications()
                : _buildNotificationsList(),
          ),

          // Footer
          Divider(height: 1, thickness: 1),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              // يمكنك إضافة صفحة لعرض كل الإشعارات لاحقاً
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'عرض كل الإشعارات',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF008080),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: Color(0xFF008080)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد إشعارات جديدة',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    // استخدام الإشعارات الحقيقية من API
    if (realNotifications.isEmpty) {
      return _buildEmptyNotifications();
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: realNotifications.length,
      separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5),
      itemBuilder: (context, index) {
        final notification = realNotifications[index];
        final type = notification['type'] ?? '';
        
        // تحديد الأيقونة واللون حسب نوع الإشعار
        IconData icon = Icons.notifications_outlined;
        Color color = Colors.grey;
        String route = '/admin/pending';

        if (type == 'new_user_pending') {
          icon = Icons.person_add_outlined;
          color = Color(0xFF4361EE);
          route = '/admin/pending';
        } else if (type == 'new_post') {
          icon = Icons.article_outlined;
          color = Color(0xFF4CAF50);
          route = '/admin/posts';
        } else if (type == 'post_deleted') {
          icon = Icons.delete_outline;
          color = Color(0xFFE91E63);
          route = '/admin/posts';
        }

        return _buildNotificationItem(
          title: notification['title'] ?? 'إشعار',
          message: notification['message'] ?? '',
          time: _formatNotificationTime(notification['created_at']),
          icon: icon,
          color: color,
          isRead: notification['is_read'] ?? false,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
        );
      },
    );
  }

  // تنسيق وقت الإشعار
  String _formatNotificationTime(String? createdAt) {
    if (createdAt == null) return '';
    
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color color,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isRead ? Colors.white : Color(0xFF4361EE).withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF4361EE),
                  shape: BoxShape.circle,
                ),
              ),
          ],
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
            width: 80,
            height: 80,
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
                    Icons.analytics_outlined,
                    color: Color(0xFF008080),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Dashboard...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008080),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(Size size, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      backgroundColor: Color(0xFF008080),
      color: Colors.white,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Welcome Section
            _buildWelcomeSection(isDark),
            SizedBox(height: 24),

            // Stats Overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('📊 System Overview', isDark),
                  SizedBox(height: 16),
                  _buildStatsGrid(size, isDark),
                  SizedBox(height: 24),
                  _buildSectionTitle('🎮 Engagement & Mood', isDark),
                  SizedBox(height: 16),
                  _buildEngagementSection(isDark),
                  SizedBox(height: 32),

                  // Quick Actions
                  _buildSectionTitle('⚡ Quick Actions', isDark),
                  SizedBox(height: 16),
                  _buildQuickActions(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark) {
    final userName = userInfo?['name']?.split(' ').first ?? 'Admin';
    final rawPicture = userInfo?['picture'] as String?;

    String? resolvedPicture;
    if (rawPicture != null && rawPicture.isNotEmpty) {
      // لو المسار نسبي مثل /uploads/..., أضيف له base URL مثل المستخدم العادي
      final baseHost = _apiService.baseUrl.replaceFirst('/api/users', '');
      resolvedPicture = rawPicture.startsWith('http') ? rawPicture : '$baseHost$rawPicture';
    }
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    String emoji = '🌅';

    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '☀️';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF008080),
            Color(0xFF006666),
            Color(0xFF004D4D),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF008080).withOpacity(0.3),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $emoji',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  userName,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insights_rounded, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Manage your platform efficiently',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.15),
              backgroundImage:
                  resolvedPicture != null ? NetworkImage(resolvedPicture) : null,
              child: resolvedPicture == null
                  ? Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 40,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildStatsGrid(Size size, bool isDark) {
    return Column(
      children: [
        // Main Stats Row
        Row(
          children: [
            Expanded(
              child: _buildMainStatCard(
                title: 'Total Users',
                value: stats['totalUsers'] ?? 0,
                icon: Icons.people_alt_rounded,
                color: Color(0xFF4361EE),
                subtitle: 'Registered users',
                trend: '+12%',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMainStatCard(
                title: 'Pending',
                value: stats['pendingUsers'] ?? 0,
                icon: Icons.pending_actions_rounded,
                color: Color(0xFFFF9F1C),
                subtitle: 'Awaiting approval',
                trend: '${stats['pendingUsers'] ?? 0} new',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Secondary Stats Grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _buildMiniStatCard(
              title: 'Patients',
              value: stats['totalPatients'] ?? 0,
              icon: Icons.person_rounded,
              color: Color(0xFF4CAF50),
            ),
            _buildMiniStatCard(
              title: 'Specialists',
              value: stats['totalSpecialists'] ?? 0,
              icon: Icons.medical_services_rounded,
              color: Color(0xFF009688),
            ),
            _buildMiniStatCard(
              title: 'Active',
              value: stats['activeUsers'] ?? 0,
              icon: Icons.trending_up_rounded,
              color: Color(0xFFE91E63),
            ),
            _buildMiniStatCard(
              title: 'Moods',
              value: stats['totalMoodEntries'] ?? 0,
              icon: Icons.emoji_emotions_rounded,
              color: Color(0xFF9C27B0),
            ),
            _buildMiniStatCard(
              title: 'Posts',
              value: stats['totalPosts'] ?? 0,
              icon: Icons.article_rounded,
              color: Color(0xFF3F51B5),
            ),
            _buildMiniStatCard(
              title: 'Comments',
              value: stats['totalComments'] ?? 0,
              icon: Icons.comment_rounded,
              color: Color(0xFF00BCD4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required String trend,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Color(0xFF2D3748),
              height: 1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Color(0xFF718096),
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark ? Colors.white38 : Color(0xFFA0AEC0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(height: 8),
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final pendingCount = stats['pendingUsers'] ?? 0;

    return Column(
      children: [
        _buildActionTile(
          title: 'Pending Approvals',
          subtitle: 'Review user registrations',
          icon: Icons.pending_actions_rounded,
          iconColor: Color(0xFFFF9F1C),
          onTap: () => Navigator.pushNamed(context, '/admin/pending'),
          badge: pendingCount > 0 ? pendingCount : null,
        ),
        SizedBox(height: 12),
        _buildActionTile(
          title: 'Manage Users',
          subtitle: 'View and manage all users',
          icon: Icons.people_outline_rounded,
          iconColor: Color(0xFF4361EE),
          onTap: () => Navigator.pushNamed(context, '/admin/users'),
        ),
        SizedBox(height: 12),
        _buildActionTile(
          title: 'Moderate Posts',
          subtitle: 'Review community content',
          icon: Icons.article_outlined,
          iconColor: Color(0xFF9C27B0),
          onTap: () => Navigator.pushNamed(context, '/admin/posts'),
        ),
        SizedBox(height: 12),
        _buildActionTile(
          title: 'Admin Profile',
          subtitle: 'View and edit your admin info',
          icon: Icons.person_outline_rounded,
          iconColor: Color(0xFF00A8E8),
          onTap: () async {
            await Navigator.pushNamed(context, '/admin/profile');
            await _loadUserInfo();
          },
        ),
        SizedBox(height: 12),
        _buildActionTile(
          title: 'Settings',
          subtitle: 'Theme, notifications & more',
          icon: Icons.settings_suggest_rounded,
          iconColor: Color(0xFF10B981),
          onTap: () => Navigator.pushNamed(context, '/admin/settings'),
        ),
        SizedBox(height: 12),
        _buildActionTile(
          title: 'System Health',
          subtitle: 'Monitor platform performance',
          icon: Icons.health_and_safety_outlined,
          iconColor: Color(0xFF4CAF50),
          onTap: () => Navigator.pushNamed(context, '/admin/health'),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    int? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Color(0xFFA0AEC0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenu() {
    final rawPicture = userInfo?['picture'] as String?;
    final userName = userInfo?['name']?.split(' ').first ?? 'Admin';
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    String? resolvedPicture;
    if (rawPicture != null && rawPicture.isNotEmpty) {
      // لو المسار نسبي مثل /uploads/..., أضيف له base URL مثل باقي الشاشات
      final baseHost = _apiService.baseUrl.replaceFirst('/api/users', '');
      resolvedPicture = rawPicture.startsWith('http') ? rawPicture : '$baseHost$rawPicture';
    }

    return PopupMenuButton<String>(
      offset: Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          backgroundImage: resolvedPicture != null ? NetworkImage(resolvedPicture) : null,
          child: resolvedPicture == null
              ? Text(
                  firstLetter,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF008080)),
              SizedBox(width: 12),
              Text('My Profile', style: GoogleFonts.poppins()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: Colors.grey[700]),
              SizedBox(width: 12),
              Text('Settings', style: GoogleFonts.poppins()),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Logout', style: GoogleFonts.poppins(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            () async {
              await Navigator.pushNamed(context, '/admin/profile');
              await _loadUserInfo();
            }();
            break;
          case 'settings':
            Navigator.pushNamed(context, '/admin/settings');
            break;
          case 'logout':
            _logout();
            break;
        }
      },
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout Confirmation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout from admin panel?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await _apiService.storage;
      await storage.delete(key: 'jwt');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}