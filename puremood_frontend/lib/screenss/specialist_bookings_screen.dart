import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/api_service.dart';
import '../services/refund_service.dart';
import 'patient_specialist_chat_screen.dart';
import 'video_call_screen.dart';

class SpecialistBookingsScreen extends StatefulWidget {
  const SpecialistBookingsScreen({Key? key}) : super(key: key);

  @override
  _SpecialistBookingsScreenState createState() => _SpecialistBookingsScreenState();
}

class _SpecialistBookingsScreenState extends State<SpecialistBookingsScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final ApiService _apiService = ApiService();
  final RefundService _refundService = RefundService();
  late TabController _tabController;
  
  List<Booking> _allBookings = [];
  List<Booking> _pendingBookings = [];
  List<Booking> _confirmedBookings = [];
  List<Booking> _completedBookings = [];
  bool _isLoading = true;
  int? _specialistId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      final userInfo = await _apiService.getUserInfo();
      _specialistId = userInfo['specialist_id'];
      
      if (_specialistId != null) {
        final bookings = await _bookingService.getSpecialistBookings(_specialistId!);
        
        setState(() {
          _allBookings = bookings;
          _pendingBookings = bookings.where((b) => b.status == 'pending').toList();
          _confirmedBookings = bookings.where((b) => b.status == 'confirmed').toList();
          _completedBookings = bookings.where((b) => b.status == 'completed').toList();
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bookings')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isBookingTimePassed(Booking booking) {
    try {
      final bookingDateTime = DateTime.parse('${booking.bookingDate} ${booking.endTime}');
      return DateTime.now().isAfter(bookingDateTime);
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleBookingAction(int bookingId, String action) async {
    try {
      if (action == 'confirm') {
        await _bookingService.confirmBooking(bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking confirmed ✅'), backgroundColor: Colors.green),
        );
      } else if (action == 'complete') {
        await _bookingService.completeBooking(bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session completed ✅'), backgroundColor: Colors.blue),
        );
      }
      _loadBookings(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelBookingWithPaymentLogic(Booking booking) async {
    try {
      if (booking.paymentStatus == 'paid') {
        final result = await _refundService.cancelBooking(
          bookingId: booking.bookingId,
          cancelledBy: 'specialist',
          reason: 'Cancelled by specialist',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Booking cancelled & refund processed 💰'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _bookingService.cancelBooking(
          booking.bookingId,
          reason: 'Cancelled by specialist',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'All (${_allBookings.length})'),
            Tab(text: 'Pending (${_pendingBookings.length})'),
            Tab(text: 'Confirmed (${_confirmedBookings.length})'),
            Tab(text: 'Completed (${_completedBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(_allBookings, 'all'),
                  _buildBookingsList(_pendingBookings, 'pending'),
                  _buildBookingsList(_confirmedBookings, 'confirmed'),
                  _buildBookingsList(_completedBookings, 'completed'),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pending' ? Icons.pending_actions :
              type == 'confirmed' ? Icons.check_circle :
              type == 'completed' ? Icons.done_all : Icons.calendar_today,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              type == 'pending' ? 'No Pending Bookings' :
              type == 'confirmed' ? 'No Confirmed Bookings' :
              type == 'completed' ? 'No Completed Sessions' : 'No Bookings',
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

    // Sort bookings by date and time
    bookings.sort((a, b) {
      final dateCompare = a.bookingDate.compareTo(b.bookingDate);
      if (dateCompare != 0) return dateCompare;
      return a.startTime.compareTo(b.startTime);
    });

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, type);
      },
    );
  }

  Widget _buildBookingCard(Booking booking, String type) {
    Color statusColor = _getStatusColor(booking.status);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal.shade700, size: 28),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.patientName ?? 'Patient',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking.patientEmail ?? '',
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
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    booking.statusArabic,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            // Details
            _buildInfoRow(Icons.calendar_today, 'Date', booking.formattedDate),
            _buildInfoRow(Icons.access_time, 'Time', booking.formattedTime),
            _buildInfoRow(Icons.videocam, 'Session Type', booking.sessionTypeArabic),
            _buildInfoRow(Icons.attach_money, 'Price', '\$${booking.totalPrice.toStringAsFixed(0)}'),
            
            // Patient info
            if (booking.patientAge != null || booking.patientGender != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Info:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 4),
                    if (booking.patientAge != null)
                      Text('Age: ${booking.patientAge}', 
                           style: GoogleFonts.poppins(fontSize: 11)),
                    if (booking.patientGender != null)
                      Text('Gender: ${booking.patientGender}', 
                           style: GoogleFonts.poppins(fontSize: 11)),
                  ],
                ),
              ),
            ],
            
            // Notes
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Text(
                          'Patient Notes:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      booking.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Actions
            if (booking.status == 'pending') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleBookingAction(booking.bookingId, 'confirm'),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept', style: GoogleFonts.poppins(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBookingWithPaymentLogic(booking),
                      icon: Icon(Icons.close, size: 18, color: Colors.red),
                      label: Text('Reject', style: GoogleFonts.poppins(fontSize: 13, color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == 'confirmed') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoCallScreen(
                              bookingId: booking.bookingId,
                              userName: booking.specialistName ?? 'Specialist',
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.videocam, size: 18),
                      label: Text('Start Session', style: GoogleFonts.poppins(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleBookingAction(booking.bookingId, 'complete'),
                      icon: Icon(Icons.done_all, size: 18, color: Colors.green),
                      label: Text('Complete', style: GoogleFonts.poppins(fontSize: 13, color: Colors.green)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelBookingWithPaymentLogic(booking),
                  icon: Icon(Icons.cancel, size: 18, color: Colors.orange),
                  label: Text('Cancel Booking', style: GoogleFonts.poppins(fontSize: 13, color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              // Check if booking time has passed
              if (_isBookingTimePassed(booking)) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Confirm No-Show', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          content: Text(
                            'Did the patient not show up?\nNo refund will be issued.',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel', style: GoogleFonts.poppins()),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                              ),
                              child: Text('Confirm', style: GoogleFonts.poppins()),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        try {
                          await _refundService.markNoShow(
                            bookingId: booking.bookingId,
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ No-show marked successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          _loadBookings();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.person_off, size: 18, color: Colors.purple),
                    label: Text('Mark No-Show', style: GoogleFonts.poppins(fontSize: 13, color: Colors.purple)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.purple),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientSpecialistChatScreen(
                        bookingId: booking.bookingId,
                        patientId: booking.patientId,
                        specialistId: booking.specialistId,
                        title: booking.patientName ?? 'Patient Chat',
                        isPatientView: false,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat, size: 18, color: Colors.teal),
                label: Text('Chat', style: GoogleFonts.poppins(fontSize: 13, color: Colors.teal)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.teal),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
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
