import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/booking_chat_service.dart';
import '../services/booking_service.dart';
import '../config/api_config.dart';
import 'patient_specialist_chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final _bookingService = BookingService();
  final _chatService = BookingChatService();
  final _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String _role = 'patient';
  List<_ConversationItem> _items = [];
  List<_ConversationItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final me = await _apiService.getMe();
      final role = me?['role']?.toString() ?? 'patient';
      _role = role;

      List<Booking> bookings;
      if (role == 'specialist') {
        final specialistId = me?['specialist_id'];
        if (specialistId == null) {
          bookings = [];
        } else {
          bookings = await _bookingService.getSpecialistBookings(specialistId as int);
        }
      } else {
        bookings = await _bookingService.getMyBookings();
      }

      final items = await Future.wait(
        bookings.map((booking) async {
          final lastMessage = await _chatService.getLastMessage(booking.bookingId);
          final otherName = role == 'specialist'
              ? (booking.patientName ?? 'Patient')
              : (booking.specialistName ?? 'Specialist');
          final otherPicture = role == 'specialist'
              ? booking.patientPicture
              : booking.specialistPicture;
          return _ConversationItem(
            booking: booking,
            displayName: otherName,
            lastMessage: lastMessage?.content ?? 'No messages yet',
            lastMessageTime: lastMessage?.createdAt,
            avatarUrl: _resolvePicture(otherPicture),
          );
        }),
      );

      items.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.booking.createdAt;
        final bTime = b.lastMessageTime ?? b.booking.createdAt;
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  String? _resolvePicture(String? rawPicture) {
    if (rawPicture == null || rawPicture.isEmpty) return null;
    if (rawPicture.startsWith('http')) return rawPicture;
    final baseHost = ApiConfig.baseUrl.replaceFirst('/api', '');
    return '$baseHost$rawPicture';
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredItems = _items);
      return;
    }

    setState(() {
      _filteredItems = _items.where((item) {
        return item.displayName.toLowerCase().contains(query) ||
            item.lastMessage.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _openChat(_ConversationItem item) {
    final booking = item.booking;
    final isPatientView = _role != 'specialist';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientSpecialistChatScreen(
          bookingId: booking.bookingId,
          patientId: booking.patientId,
          specialistId: booking.specialistId,
          title: item.displayName,
          isPatientView: isPatientView,
          avatarUrl: item.avatarUrl,
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hours = dt.hour.toString().padLeft(2, '0');
    final minutes = dt.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF8),
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF008080),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No conversations yet',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final initials = item.displayName.isNotEmpty
                              ? item.displayName.trim()[0].toUpperCase()
                              : '?';
                          return GestureDetector(
                            onTap: () => _openChat(item),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFD6F1EC),
                              backgroundImage: item.avatarUrl != null
                                  ? NetworkImage(item.avatarUrl!)
                                  : null,
                              child: item.avatarUrl == null
                                  ? Text(
                                      initials,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF008080),
                                      ),
                                    )
                                  : null,
                            ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.displayName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF008080),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatTime(item.lastMessageTime),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ConversationItem {
  final Booking booking;
  final String displayName;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? avatarUrl;

  _ConversationItem({
    required this.booking,
    required this.displayName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.avatarUrl,
  });
}
