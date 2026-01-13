import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/community_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailsScreen extends StatefulWidget {
  final int postId;
  
  const PostDetailsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _commentController = TextEditingController();
  
  Map<String, dynamic>? post;
  List<dynamic> comments = [];
  bool loading = true;
  bool isAnonymousComment = true;
  String? error;

  DateTime _parseCreatedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  Future<void> _loadPostDetails() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final postResponse = await _communityService.getPostById(widget.postId);
      final commentsResponse = await _communityService.getComments(widget.postId);
      
      setState(() {
        post = postResponse['post'];
        comments = commentsResponse['comments'] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _communityService.createComment(
        postId: widget.postId,
        content: _commentController.text,
        isAnonymous: isAnonymousComment,
      );
      
      _commentController.clear();
      _loadPostDetails();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment added successfully!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (e is CommentModerationException) {
        final found = e.foundWords.isNotEmpty ? e.foundWords.join(', ') : '';
        final details = found.isNotEmpty ? ' ($found)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.message}$details')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await _communityService.deleteComment(commentId);
      _loadPostDetails();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment deleted!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F5),
      appBar: AppBar(
        title: Text('Post Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF008080),
        foregroundColor: Colors.white,
        actions: post != null && post?['can_delete'] == true
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _confirmDeletePost,
                ),
              ]
            : null,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008080)))
          : error != null
              ? Center(child: Text('Error: $error', style: GoogleFonts.poppins()))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPostCard(),
                      const SizedBox(height: 20),
                      _buildCommentsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPostCard() {
    if (post == null) return const SizedBox();

    final userName = post!['User']?['name'] ?? 'Anonymous';
    final createdAt = _parseCreatedAt(post!['created_at']);
    final timeAgo = timeago.format(createdAt);
    final category = (post!['category'] ?? 'general').toString();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2F0EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Icon(Icons.person, color: Colors.teal.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF004D40),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF008080).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008080),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post!['title'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF203B3A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            post!['content'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments (${comments.length})',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 20),
          _buildAddCommentField(),
          const SizedBox(height: 20),
          ...comments.map((comment) => _buildCommentCard(comment)).toList(),
        ],
      ),
    );
  }

  Widget _buildAddCommentField() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2F0EF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Send', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: isAnonymousComment,
              onChanged: (value) {
                setState(() {
                  isAnonymousComment = value!;
                });
              },
              activeColor: const Color(0xFF008080),
            ),
            Text('Post anonymously', style: GoogleFonts.poppins(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  void _confirmDeletePost() {
    if (post == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete this post?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    if (post == null) return;
    final postId = post?['post_id'];
    if (postId == null) return;
    try {
      await _communityService.deletePost(postId);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final userName = comment['User']?['name'] ?? 'Anonymous';
    final createdAt = _parseCreatedAt(comment['created_at']);
    final timeAgo = timeago.format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal.shade100,
                child: Icon(Icons.person, size: 16, color: Colors.teal.shade700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF004D40),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(comment['comment_id']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment['content'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Comment', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete this comment?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
