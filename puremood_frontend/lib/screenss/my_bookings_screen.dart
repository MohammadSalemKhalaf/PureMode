import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/specialist_service.dart';
import '../config/api_config.dart';
import '../widgets/cancel_booking_dialog.dart';
import 'patient_specialist_chat_screen.dart';
import 'video_call_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final SpecialistService _specialistService = SpecialistService();
  late TabController _tabController;
  
  List<Booking> _allBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];
  List<Booking> _cancelledBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  Future<void> _openVideoLink(Booking booking) async {
    final roomName = 'puremood_booking_${booking.bookingId}';
    final uri = Uri.https('meet.jit.si', '/$roomName');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open video link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _resolvePicture(String? rawPicture) {
    if (rawPicture == null || rawPicture.isEmpty) return null;
    if (rawPicture.startsWith('http')) return rawPicture;
    final baseHost = ApiConfig.baseUrl.replaceFirst('/api', '');
    return '$baseHost$rawPicture';
  }

  Future<void> _showRatingDialog(Booking booking) async {
    int selectedRating = 0;
    final TextEditingController commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Rate this session',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your session with ${booking.specialistName ?? 'the specialist'}?',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              selectedRating = starIndex;
                            });
                          },
                          icon: Icon(
                            starIndex <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber[700],
                            size: 30,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Add a comment (optional)',
                        labelStyle: GoogleFonts.poppins(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () async {
                          Navigator.pop(context);
                          try {
                            final success = await _specialistService.addReview(
                              specialistId: booking.specialistId,
                              rating: selectedRating,
                              comment: commentController.text.trim(),
                              appointmentId: null,
                              isAnonymous: false,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Thank you for your feedback!'
                                      : 'Failed to submit rating. Please try again.',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to submit rating: $e',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      final bookings = await _bookingService.getMyBookings();
      
      setState(() {
        _allBookings = bookings;
        
        // Filter upcoming (pending or confirmed, future dates)
        _upcomingBookings = bookings.where((b) {
          final isUpcoming = b.status == 'pending' || b.status == 'confirmed';
          final bookingDate = DateTime.parse(b.bookingDate);
          final isFuture = bookingDate.isAfter(DateTime.now().subtract(Duration(days: 1)));
          return isUpcoming && isFuture;
        }).toList();
        
        // Filter past (completed)
        _pastBookings = bookings.where((b) => b.status == 'completed').toList();
        
        // Filter cancelled (any status that starts with 'cancelled')
        _cancelledBookings = bookings
            .where((b) => b.status.startsWith('cancelled'))
            .toList();
      });
    } catch (e) {
      print('Error loading bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bookings'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to cancel this booking?\nCancellations within 24 hours may result in partial refund.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _bookingService.cancelBooking(booking.bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadBookings(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upcoming, size: 18),
                  SizedBox(width: 4),
                  Text('Upcoming', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 4),
                  Text('Past', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 18),
                  SizedBox(width: 4),
                  Text('Cancelled', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ),
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
                  _buildBookingsList(_upcomingBookings, 'upcoming'),
                  _buildBookingsList(_pastBookings, 'past'),
                  _buildBookingsList(_cancelledBookings, 'cancelled'),
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
              type == 'upcoming' ? Icons.event_busy : 
              type == 'past' ? Icons.history : Icons.cancel_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              type == 'upcoming' ? 'No Upcoming Bookings' :
              type == 'past' ? 'No Past Bookings' : 'No Cancelled Bookings',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

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
    IconData statusIcon = _getStatusIcon(booking.status);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        booking.specialistName ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking.specialization ?? '',
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        _getStatusText(booking.status),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow(Icons.calendar_today, 'Date', booking.formattedDate),
            _buildInfoRow(Icons.access_time, 'Time', booking.formattedTime),
            _buildInfoRow(Icons.videocam, 'Session Type', booking.sessionType ?? 'Video'),
            _buildInfoRow(Icons.attach_money, 'Price', '\$${booking.totalPrice.toStringAsFixed(2)}'),
            // Refund info for cancelled bookings
            if (booking.status.startsWith('cancelled')) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (booking.paymentStatus == 'refunded' ||
                          booking.paymentStatus == 'partial_refund')
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (booking.paymentStatus == 'refunded' ||
                            booking.paymentStatus == 'partial_refund')
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 18,
                      color: (booking.paymentStatus == 'refunded' ||
                              booking.paymentStatus == 'partial_refund')
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (booking.paymentStatus == 'refunded' ||
                                booking.paymentStatus == 'partial_refund')
                            ? (booking.paymentStatus == 'refunded'
                                ? 'Payment refunded to you: \$${booking.refundAmount.toStringAsFixed(2)}'
                                : 'Partial refund: \$${booking.refundAmount.toStringAsFixed(2)} returned to you')
                            : 'No payment was charged for this cancelled booking.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: (booking.paymentStatus == 'refunded' ||
                                  booking.paymentStatus == 'partial_refund')
                              ? Colors.green.shade900
                              : Colors.grey.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Notes:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                booking.notes!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (type == 'upcoming' && (booking.status == 'pending' || booking.status == 'confirmed')) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  if (booking.status == 'confirmed')
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoCallScreen(
                                    bookingId: booking.bookingId,
                                    userName: booking.patientName ?? 'You',
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.videocam, size: 18),
                            label: Text('Join Now', style: GoogleFonts.poppins(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openVideoLink(booking),
                            child: Text(
                              'Open video link in browser',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (booking.status == 'confirmed') SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showCancelBookingDialog(
                          context,
                          bookingId: booking.bookingId,
                          bookingDate: DateTime.parse(booking.bookingDate),
                          price: booking.totalPrice,
                          cancelledBy: 'patient',
                          onCancelled: () {
                            _loadBookings();
                          },
                        );
                      },
                      icon: Icon(Icons.cancel, size: 18, color: Colors.orange),
                      label: Text('Cancel', style: GoogleFonts.poppins(fontSize: 13, color: Colors.orange)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange),
                        padding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 8),
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
                        title: booking.specialistName ?? 'Specialist Chat',
                        isPatientView: true,
                        avatarUrl: _resolvePicture(booking.specialistPicture),
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat, size: 18, color: Colors.teal),
                label: Text('Chat', style: GoogleFonts.poppins(fontSize: 13, color: Colors.teal)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.teal),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (type == 'past' && booking.status == 'completed') ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRatingDialog(booking),
                  icon: Icon(Icons.star_rate_rounded, size: 18, color: Colors.amber[700]),
                  label: Text(
                    'Rate Session',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.amber[800]),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.amber.shade700),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
            if (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancellation Reason: ${booking.cancellationReason}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    if (status.startsWith('cancelled')) {
      return Colors.red;
    }

    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    if (status.startsWith('cancelled')) {
      return Icons.cancel;
    }

    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    if (status == 'cancelled_specialist') {
      return 'Cancelled by specialist';
    }
    if (status == 'cancelled_patient') {
      return 'Cancelled by you';
    }
    if (status.startsWith('cancelled')) {
      return 'Cancelled';
    }

    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
