import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/booking_chat_service.dart';

class PatientSpecialistChatScreen extends StatefulWidget {
  final int bookingId;
  final int patientId;
  final int specialistId;
  final String title;
  final bool isPatientView; // true when opened by patient, false for specialist
  final String? avatarUrl;

  const PatientSpecialistChatScreen({
    Key? key,
    required this.bookingId,
    required this.patientId,
    required this.specialistId,
    required this.title,
    required this.isPatientView,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<PatientSpecialistChatScreen> createState() => _PatientSpecialistChatScreenState();
}

class _PatientSpecialistChatScreenState extends State<PatientSpecialistChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<_LocalMessage> _messages = [];
  final BookingChatService _chatService = BookingChatService();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _typingController;
  final FocusNode _inputFocus = FocusNode();
  bool _showTyping = false;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _inputFocus.addListener(() {
      final shouldShow = _inputFocus.hasFocus && _controller.text.trim().isNotEmpty;
      if (shouldShow != _showTyping) {
        setState(() => _showTyping = shouldShow);
      }
    });
    _loadMessages();
  }

  @override
  void dispose() {
    _typingController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final dtos = await _chatService.getMessages(widget.bookingId);
      setState(() {
        _messages.clear();
        _messages.addAll(dtos.map((m) => _LocalMessage(
              text: m.content,
              isMe: _isMeFromRole(m.senderRole),
              time: m.createdAt,
            )));
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isMeFromRole(String senderRole) {
    // إذا الشاشة من منظور المريض، فرسائل patient هي أنا
    if (widget.isPatientView) {
      return senderRole == 'patient';
    }
    // وإذا من منظور الأخصائي، فرسائل specialist هي أنا
    return senderRole == 'specialist';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) {
      return 'Today';
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    if (_showTyping) {
      setState(() => _showTyping = false);
    }

    try {
      final dto = await _chatService.sendMessage(
        bookingId: widget.bookingId,
        content: text,
      );

      setState(() {
        _messages.add(_LocalMessage(
          text: dto.content,
          isMe: _isMeFromRole(dto.senderRole),
          time: dto.createdAt,
        ));
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _handleTypingChanged(String value) {
    final shouldShow = _inputFocus.hasFocus && value.trim().isNotEmpty;
    if (shouldShow != _showTyping) {
      setState(() => _showTyping = shouldShow);
      if (shouldShow) {
        _scrollToBottom();
      }
    }
  }

  Widget _buildTypingIndicator() {
    return AnimatedOpacity(
      opacity: _showTyping ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      child: _showTyping
          ? Container(
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TypingDot(controller: _typingController, delay: 0.0),
                  const SizedBox(width: 4),
                  _TypingDot(controller: _typingController, delay: 0.2),
                  const SizedBox(width: 4),
                  _TypingDot(controller: _typingController, delay: 0.4),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        toolbarHeight: 72,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFD6F1EC),
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null
                  ? Text(
                      widget.title.isNotEmpty ? widget.title[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF008080),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Online',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.isMe;
                          final showDayHeader = index == 0 ||
                              !_isSameDay(msg.time, _messages[index - 1].time);
                          final senderLabel = isMe
                              ? 'Me'
                              : (widget.title.isNotEmpty ? widget.title : 'User');
                          final timeFormatted =
                              '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';
                          return Column(
                            children: [
                              if (showDayHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2EF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _dayLabel(msg.time),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF008080),
                                      ),
                                    ),
                                  ),
                                ),
                              Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFF008080)
                                        : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        senderLabel,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isMe
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        msg.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeFormatted,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          if (_showTyping)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: _buildTypingIndicator(),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE5ECF4),
                    child: IconButton(
                      icon: const Icon(Icons.attach_file, size: 18, color: Color(0xFF008080)),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE5ECF4),
                    child: IconButton(
                      icon: const Icon(Icons.mic, size: 18, color: Color(0xFF008080)),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _inputFocus,
                      onChanged: _handleTypingChanged,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF008080),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalMessage {
  final String text;
  final bool isMe;
  final DateTime time;

  _LocalMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });
}

class _TypingDot extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _TypingDot({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, delay + 0.6, curve: Curves.easeInOut),
    );

    return FadeTransition(
      opacity: animation,
      child: const CircleAvatar(
        radius: 4,
        backgroundColor: Color(0xFF008080),
      ),
    );
  }
}
