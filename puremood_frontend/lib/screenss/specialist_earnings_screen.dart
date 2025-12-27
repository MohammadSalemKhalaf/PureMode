import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/refund_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// شاشة عرض الأرباح والدفعات للأخصائي
class SpecialistEarningsScreen extends StatefulWidget {
  const SpecialistEarningsScreen({Key? key}) : super(key: key);

  @override
  _SpecialistEarningsScreenState createState() => _SpecialistEarningsScreenState();
}

class _SpecialistEarningsScreenState extends State<SpecialistEarningsScreen> {
  final RefundService _refundService = RefundService();
  
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    
    try {
      // Test backend connection first
      print('🧪 Testing backend connection...');
      final testResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl.replaceAll('/api', '')}/test'),
      );
      print('🧪 Test Response: ${testResponse.statusCode} - ${testResponse.body}');
      
      final result = await _refundService.getSpecialistPayments();
      
      print('📊 Earnings Result: $result');
      print('📈 Stats: ${result['stats']}');
      print('📋 Bookings Count: ${result['bookings']?.length ?? 0}');
      
      setState(() {
        _stats = result['stats'] ?? {};
        _bookings = result['bookings'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Load Earnings Error: $e');
      setState(() => _isLoading = false);
      _showError('Failed to load data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Earnings & Payments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF008080),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _loadEarnings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(),
                    SizedBox(height: 24),
                    _buildPaymentsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings Summary',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 20),
        
        // Total Earnings
        _buildStatCard(
          title: 'Total Earnings',
          amount: _stats['total_earnings'] ?? 0,
          icon: Icons.account_balance_wallet_rounded,
          color: Color(0xFF4CAF50),
          subtitle: 'All completed sessions',
        ),
        
        SizedBox(height: 12),
        
        // Pending Earnings
        _buildStatCard(
          title: 'Pending Earnings',
          amount: _stats['pending_earnings'] ?? 0,
          icon: Icons.schedule_rounded,
          color: Color(0xFFFF9800),
          subtitle: 'Upcoming sessions',
        ),
        
        SizedBox(height: 12),
        
        // Total Refunded
        _buildStatCard(
          title: 'Total Refunded',
          amount: _stats['total_refunded'] ?? 0,
          icon: Icons.money_off_rounded,
          color: Color(0xFFF44336),
          subtitle: 'Cancelled bookings',
        ),
        
        SizedBox(height: 12),
        
        // صافي الأرباح
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF008080), Color(0xFF00A79D)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF008080).withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Earnings',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${(_stats['net_earnings'] ?? 0).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'After refunds',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required dynamic amount,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '\$${(amount ?? 0).toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'No Payments Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your payment history will appear here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _bookings.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = _bookings[index];
            return _buildPaymentCard(booking);
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> booking) {
    final bookingDate = DateTime.parse(booking['booking_date']);
    final status = booking['status'] ?? 'unknown';
    final paymentStatus = booking['payment_status'] ?? 'unknown';
    final price = double.tryParse(booking['total_price']?.toString() ?? '0') ?? 0.0;
    final refundAmount = double.tryParse(booking['refund_amount']?.toString() ?? '0') ?? 0.0;
    final patientName = booking['patient_name'] ?? 'Unknown';
    
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;
    String statusText = status;
    
    switch (status) {
      case 'confirmed':
        statusColor = Color(0xFF4CAF50);
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Confirmed';
        break;
      case 'completed':
        statusColor = Color(0xFF2196F3);
        statusIcon = Icons.done_all_rounded;
        statusText = 'Completed';
        break;
      case 'cancelled_patient':
        statusColor = Color(0xFFFF9800);
        statusIcon = Icons.cancel_rounded;
        statusText = 'Patient Cancelled';
        break;
      case 'cancelled_specialist':
        statusColor = Color(0xFFF44336);
        statusIcon = Icons.cancel_rounded;
        statusText = 'You Cancelled';
        break;
      case 'no_show':
        statusColor = Color(0xFF9C27B0);
        statusIcon = Icons.person_off_rounded;
        statusText = 'No Show';
        break;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF008080).withOpacity(0.1),
                child: Text(
                  patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF008080),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(bookingDate),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$$price',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              
              if (refundAmount > 0) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refunded',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '-\$$refundAmount',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF44336),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${(price - refundAmount).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008080),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
