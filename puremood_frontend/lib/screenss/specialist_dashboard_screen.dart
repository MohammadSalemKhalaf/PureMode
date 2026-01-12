import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'specialist_bookings_screen.dart';
import 'availability_management_screen.dart';
import 'specialist_own_profile_screen.dart';
import 'specialist_earnings_screen.dart';
import 'messages_list_screen.dart';
import 'login_screen.dart';
import 'patient_mood_history_screen.dart';

class SpecialistDashboardScreen extends StatefulWidget {
  const SpecialistDashboardScreen({Key? key}) : super(key: key);

  @override
  _SpecialistDashboardScreenState createState() => _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState extends State<SpecialistDashboardScreen> {
  final BookingService _bookingService = BookingService();
  final ApiService _apiService = ApiService();
  
  List<Booking> _todayBookings = [];
  List<Booking> _pendingBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _recentBookings = [];
  int _totalBookings = 0;
  int _completedSessions = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _specialistData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _logout() async {
    await _apiService.storage.delete(key: 'jwt');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user info
      final userInfo = await _apiService.getUserInfo();
      
      // Get specialist_id from user info
      // We need to add this to the API or get it from specialists table
      final specialistId = userInfo['specialist_id'];
      
      if (specialistId != null) {
        final bookings = await _bookingService.getSpecialistBookings(specialistId);
        bookings.sort((a, b) {
          final createdCompare = b.createdAt.compareTo(a.createdAt);
          if (createdCompare != 0) return createdCompare;

          try {
            final aDate = DateTime.parse('${a.bookingDate} ${a.startTime}');
            final bDate = DateTime.parse('${b.bookingDate} ${b.startTime}');
            return bDate.compareTo(aDate);
          } catch (e) {
            return 0;
          }
        });
        
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        setState(() {
          _specialistData = userInfo;
          _totalBookings = bookings.length;

          _recentBookings = bookings
              .where((b) => b.status == 'pending')
              .take(5)
              .toList();
          
          // Today's bookings
          _todayBookings = bookings.where((b) {
            return b.bookingDate == todayStr && 
                   (b.status == 'confirmed' || b.status == 'pending');
          }).toList();
          _todayBookings.sort((a, b) {
            try {
              final aDt = DateTime.parse('${a.bookingDate} ${a.startTime}');
              final bDt = DateTime.parse('${b.bookingDate} ${b.startTime}');
              return aDt.compareTo(bDt);
            } catch (e) {
              return 0;
            }
          });
          
          // Pending bookings
          _pendingBookings = bookings.where((b) => b.status == 'pending').toList();
          
          // Upcoming bookings (confirmed, future dates)
          _upcomingBookings = bookings.where((b) {
            final bookingDate = DateTime.parse(b.bookingDate);
            return b.status == 'confirmed' && bookingDate.isAfter(today.subtract(Duration(days: 1)));
          }).toList();
          
          // Completed sessions
          _completedSessions = bookings.where((b) => b.status == 'completed').length;
        });
      }
    } catch (e) {
      print('Error loading dashboard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBookingAction(int bookingId, String action) async {
    try {
      if (action == 'confirm') {
        await _bookingService.confirmBooking(bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Booking Confirmed Successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (action == 'cancel') {
        await _bookingService.cancelBooking(bookingId, reason: 'Cancelled by specialist');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Booking Cancelled'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadDashboardData(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(
          'Specialist Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            tooltip: 'My Profile',
            onPressed: () {
              final specialistId = _specialistData?['specialist_id'];
              if (specialistId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpecialistOwnProfileScreen(
                      specialistId: specialistId,
                    ),
                  ),
                ).then((_) => _loadDashboardData());
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildWelcomeHeader(),
                    _buildStatsCards(),
                    _buildRecentBookingsSection(),
                    _buildTodaySection(),
                    _buildPendingSection(),
                    _buildQuickActions(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRecentBookingsSection() {
    if (_recentBookings.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Color(0xFF008080), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Latest Bookings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF008080),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpecialistBookingsScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._recentBookings.map((booking) => _buildBookingCard(booking)),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF008080),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  backgroundImage: _specialistData != null && _specialistData!['profile_image'] != null
                      ? NetworkImage(
                          _specialistData!['profile_image'].toString().startsWith('http')
                              ? _specialistData!['profile_image']
                              : '${ApiConfig.baseUrl.replaceFirst('/api', '')}${_specialistData!['profile_image']}',
                        )
                      : null,
                  child: _specialistData != null && _specialistData!['profile_image'] != null
                      ? null
                      : Icon(
                          Icons.person,
                          size: 28,
                          color: const Color(0xFF008080),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  _specialistData?['name'] ?? 'Specialist',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _specialistData?['email'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: Text(
              'Dashboard',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(
              'Messages',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            subtitle: Text(
              'Conversations with your patients',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(
              'My Profile',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              final specialistId = _specialistData?['specialist_id'];
              if (specialistId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpecialistOwnProfileScreen(
                      specialistId: specialistId,
                    ),
                  ),
                ).then((_) => _loadDashboardData());
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(
              'My Earnings',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistEarningsScreen(),
                ),
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              'Logout',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF008080).withOpacity(0.1),
            backgroundImage: _specialistData != null && _specialistData!['profile_image'] != null
                ? NetworkImage(
                    _specialistData!['profile_image'].toString().startsWith('http')
                        ? _specialistData!['profile_image']
                        : '${ApiConfig.baseUrl.replaceFirst('/api', '')}${_specialistData!['profile_image']}',
                  )
                : null,
            child: _specialistData != null && _specialistData!['profile_image'] != null
                ? null
                : const Icon(
                    Icons.medical_services,
                    size: 28,
                    color: Color(0xFF008080),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. ${_specialistData?['name'] ?? 'Specialist'}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _specialistData?['email'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_available, size: 16, color: Color(0xFF008080)),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalBookings total bookings',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Today',
              _todayBookings.length.toString(),
              Icons.today,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              _pendingBookings.length.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Completed',
              _completedSessions.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection() {
    if (_todayBookings.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: Color(0xFF008080), size: 24),
              SizedBox(width: 8),
              Text(
                'Today\'s Appointments',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF008080),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._todayBookings.map((booking) => _buildBookingCard(booking)),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    if (_pendingBookings.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'No pending bookings requiring approval',
                
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Pending Approval (${_pendingBookings.length})',
                
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._pendingBookings.take(3).map((booking) => _buildBookingCard(booking, showActions: true)),
          if (_pendingBookings.length > 3)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpecialistBookingsScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  color: Color(0xFF008080),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, {bool showActions = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal.shade700, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.patientName ?? 'Patient',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${booking.formattedTime} • ${booking.sessionTypeArabic}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(booking.status)),
                  ),
                  child: Text(
                    booking.statusArabic,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.notes!,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showActions && booking.status == 'pending') ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleBookingAction(booking.bookingId, 'confirm'),
                      icon: Icon(Icons.check, size: 16),
                      label: Text('Accept', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleBookingAction(booking.bookingId, 'cancel'),
                      icon: Icon(Icons.close, size: 16, color: Colors.red),
                      label: Text('Decline', style: GoogleFonts.poppins(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientMoodHistoryScreen(
                        patientId: booking.patientId,
                        patientName: booking.patientName ?? 'Patient',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.insights_outlined, size: 18, color: Colors.indigo),
                label: Text('Mood History', style: GoogleFonts.poppins(fontSize: 13, color: Colors.indigo)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.indigo),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'All Bookings',
                  Icons.calendar_month,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpecialistBookingsScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Availability',
                  Icons.access_time,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AvailabilityManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'My Profile',
                  Icons.person,
                  Color(0xFF008080),
                  () {
                    final specialistId = _specialistData?['specialist_id'];
                    if (specialistId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpecialistOwnProfileScreen(
                            specialistId: specialistId,
                          ),
                        ),
                      ).then((_) => _loadDashboardData());
                    }
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'My Earnings',
                  Icons.account_balance_wallet,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpecialistEarningsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
