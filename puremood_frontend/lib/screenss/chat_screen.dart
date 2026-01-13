import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/ai_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int? sessionId;
  final String language;
  final Map<String, dynamic>? context;

  const ChatScreen({
    Key? key,
    this.sessionId,
    this.language = 'ar',
    this.context,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<ChatSession> _sessions = [];
  bool _isLoading = false;
  bool _isLoadingSessions = false;
  int? _currentSessionId;
  final AIChatService _aiService = AIChatService();
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    _currentLanguage = widget.language;
    
    _loadSessions(); // Load sessions list
    if (_currentSessionId != null) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await _aiService.getSessions();
      setState(() {
        _sessions.clear();
        _sessions.addAll(sessions);
      });
    } catch (e) {
      print('Error loading sessions: $e');
    } finally {
      setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_currentSessionId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final data = await _aiService.getSessionMessages(_currentSessionId!);
      setState(() {
        _messages.clear();
        _messages.addAll(data['messages']);
      });
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to load chat');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openSession(int sessionId) {
    setState(() {
      _currentSessionId = sessionId;
      _messages.clear();
    });
    _loadMessages();
    Navigator.pop(context); // Close drawer
  }

  void _newChat() {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
    });
    // Close drawer
    try {
      Navigator.pop(context);
    } catch (e) {
      // Drawer already closed
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      role: 'user',
      content: _controller.text.trim(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.sendMessage(
        sessionId: _currentSessionId,
        language: _currentLanguage,
        messages: [userMessage],
        context: widget.context,
      );

      setState(() {
        _currentSessionId = response['sessionId'];
        _messages.add(ChatMessage(
          role: 'assistant',
          content: response['reply'],
          safetyFlags: List<String>.from(response['safetyFlags'] ?? []),
        ));
      });
      _scrollToBottom();
      
      // Reload sessions list if this was a new chat
      if (_messages.length == 2) { // First exchange
        _loadSessions();
      }
    } catch (e) {
      _showError('Failed to send message');
      setState(() {
        _messages.removeLast(); // Remove failed user message
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * (0.5 - (value - index * 0.2).abs()).clamp(0.0, 0.5) * 2),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isLoading) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildLanguageButton(String text, String lang) {
    final isSelected = _currentLanguage == lang;
    return GestureDetector(
      onTap: () {
        if (_currentLanguage != lang) {
          setState(() {
            _currentLanguage = lang;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'ar' 
                  ? 'Switched to Arabic ✓' 
                  : 'Switched to English ✓',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Color(0xFF00ACC1),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Color(0xFF00838F) : Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (_currentSessionId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _currentLanguage == 'ar' ? 'Delete Chat' : 'Delete Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          _currentLanguage == 'ar' 
            ? 'Are you sure you want to delete this conversation?'
            : 'Are you sure you want to delete this conversation?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _currentLanguage == 'ar' ? 'Cancel' : 'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _currentLanguage == 'ar' ? 'Delete' : 'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && _currentSessionId != null) {
      try {
        await _aiService.deleteSession(_currentSessionId!);
        await _loadSessions(); // Refresh sessions list
        _newChat(); // Clear current chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_currentLanguage == 'ar' ? 'Chat deleted ✓' : 'Chat deleted ✓'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showError('Failed to delete chat');
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF0F8FF),
              Color(0xFFE0F2F1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00ACC1),
                    Color(0xFF00897B),
                    Color(0xFF00838F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00ACC1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _currentLanguage == 'ar' ? 'My Chats' : 'My Chats',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _currentLanguage == 'ar' 
                      ? '${_sessions.length} conversations' 
                      : '${_sessions.length} conversations',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // New Chat Button
            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00ACC1).withOpacity(0.4),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _newChat,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            _currentLanguage == 'ar' ? 'New Chat' : 'New Chat',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Divider(height: 1),

            // Sessions List
            Expanded(
              child: _isLoadingSessions
                ? Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
                : _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_outlined, size: 60, color: Colors.grey[300]),
                          SizedBox(height: 12),
                          Text(
                            _currentLanguage == 'ar' 
                              ? 'No conversations' 
                              : 'No conversations',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (ctx, index) {
                        final session = _sessions[index];
                        final isActive = session.sessionId == _currentSessionId;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: isActive
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFF00ACC1).withOpacity(0.15),
                                    Color(0xFF00838F).withOpacity(0.1),
                                  ],
                                )
                              : null,
                            color: !isActive ? Colors.white : null,
                            borderRadius: BorderRadius.circular(16),
                            border: isActive 
                              ? Border.all(color: Color(0xFF00ACC1), width: 2)
                              : Border.all(color: Colors.grey.shade200, width: 1),
                            boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Color(0xFF00ACC1).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                          ),
                          child: ListTile(
                            leading: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isActive
                                    ? [Color(0xFF00ACC1), Color(0xFF00838F)]
                                    : [Color(0xFFB2DFDB), Color(0xFF80CBC4)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: isActive
                                      ? Color(0xFF00ACC1).withOpacity(0.4)
                                      : Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isActive ? Icons.chat : Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              session.title ?? (_currentLanguage == 'ar' ? 'Chat' : 'Chat'),
                              style: GoogleFonts.poppins(
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                                color: isActive ? Color(0xFF00838F) : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _formatDate(session.updatedAt),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () => _openSession(session.sessionId),
                            trailing: isActive 
                              ? Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF00ACC1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) {
      return _currentLanguage == 'ar' ? 'Now' : 'Now';
    } else if (diff.inHours < 1) {
      return _currentLanguage == 'ar' 
        ? '${diff.inMinutes}m ago' 
        : '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return _currentLanguage == 'ar' 
        ? '${diff.inHours}h ago' 
        : '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return _currentLanguage == 'ar' 
        ? '${diff.inDays}d ago' 
        : '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                _currentLanguage == 'ar' ? 'AI Assistant' : 'AI Assistant',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF00ACC1),
                Color(0xFF00897B),
                Color(0xFF00838F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Color(0xFF00ACC1).withOpacity(0.5),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            tooltip: 'Back to dashboard',
          ),
          // Language toggle button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildLanguageButton('AR', 'ar'),
                _buildLanguageButton('EN', 'en'),
              ],
            ),
          ),
          if (_currentSessionId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _confirmDelete,
              tooltip: _currentLanguage == 'ar' ? 'Delete Chat' : 'Delete Chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer banner with gradient
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF8E1),
                  Color(0xFFFFECB3),
                  Color(0xFFFFE082),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFFFFCA28).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFFB300).withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF8F00).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _currentLanguage == 'ar'
                      ? 'This is general support, not medical advice. Consult a professional for accurate evaluation.'
                      : 'This is general support, not medical advice. Consult a professional for accurate evaluation.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF008080)),
                        const SizedBox(height: 16),
                        Text(
                          _currentLanguage == 'ar' ? 'Loading chat...' : 'Loading chat...',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.teal.shade200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentLanguage == 'ar' ? 'Start a new conversation' : 'Start a new conversation',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentLanguage == 'ar' 
                                ? 'Ask me anything about your mental wellbeing'
                                : 'Ask me anything about your mental wellbeing',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isUser = msg.isUser;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isUser 
                                ? MainAxisAlignment.end 
                                : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF00ACC1),
                                          Color(0xFF00897B),
                                          Color(0xFF00838F),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF00ACC1).withOpacity(0.5),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.transparent,
                                      child: Icon(
                                        Icons.psychology_rounded,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Flexible(
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isUser 
                                        ? LinearGradient(
                                            colors: [
                                              Color(0xFF00ACC1),
                                              Color(0xFF00897B),
                                              Color(0xFF00838F),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Color(0xFFF5F5F5).withOpacity(0.5),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                      border: isUser
                                        ? null
                                        : Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1.5,
                                          ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                        bottomLeft: isUser ? Radius.circular(24) : Radius.circular(6),
                                        bottomRight: isUser ? Radius.circular(6) : Radius.circular(24),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isUser 
                                            ? Color(0xFF00ACC1).withOpacity(0.4)
                                            : Colors.black.withOpacity(0.1),
                                          blurRadius: 16,
                                          offset: Offset(0, 6),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.content,
                                          style: GoogleFonts.poppins(
                                            color: isUser 
                                              ? Colors.white 
                                              : Color(0xFF263238),
                                            fontSize: 14.5,
                                            height: 1.6,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        if (msg.hasSafetyFlags) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 16,
                                                  color: Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    _currentLanguage == 'ar' ? 'Safety warning' : 'Safety warning',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.red.shade700,
                                                      fontWeight: FontWeight.w500,
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
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 12),
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF80CBC4),
                                          Color(0xFF4DB6AC),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF4DB6AC).withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.transparent,
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
          
          // Beautiful typing indicator
          if (_isLoading && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00ACC1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        SizedBox(width: 4),
                        _buildTypingDot(1),
                        SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _currentLanguage == 'ar' ? 'Typing...' : 'Typing...',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Color(0xFF00838F),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          
          // Beautiful input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFF5F5F5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00ACC1).withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: _currentLanguage == 'ar' ? 'Type your message...' : 'Type your message...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(color: Color(0xFF00ACC1), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          color: Color(0xFF263238),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00ACC1).withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: _isLoading ? null : _sendMessage,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _isLoading 
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        ),
                      ),
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
