import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/community_service.dart';
import 'package:puremood_frontend/screenss/post_details_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  List<dynamic> _posts = [];
  bool _loading = true;
  String? _error;
  static const Color _primary = Color(0xFF008080);

  DateTime _parseCreatedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.now();
  }

  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _communityService.getAllPosts();
      setState(() {
        _posts = response['posts'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F5),
      appBar: AppBar(
        title: Text(
          'Community',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error', style: GoogleFonts.poppins()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  color: _primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _posts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildHeaderCard();
                      }
                      final post = _posts[index - 1];
                      return _buildPostCard(post);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showNewPostDialog(context);
        },
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Share',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4F3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFE3E1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Share your journey anonymously in a safe, supportive space',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF0B4D4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => _showNewPostDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2F0EF)),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCFEAE8), width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFE7F5F4),
                    child: Icon(Icons.person, color: _primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "What's on your mind?",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6A7C7C),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Create post',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final userName = post['User']?['name'] ?? 'Anonymous';
    final createdAt = _parseCreatedAt(post['created_at']);
    final timeAgo = timeago.format(createdAt);
    final isRepost = post['original_post_id'] != null;
    final originalPost = post['OriginalPost'];
    final postId = _parseId(post['post_id']);
    final isLiked = post['liked_by_user'] == true;
    final category = (post['category'] ?? 'general').toString();
    final canDelete = post['can_delete'] == true;

    return InkWell(
      onTap: () {
        if (postId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid post')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsScreen(postId: postId),
          ),
        ).then((_) => _loadPosts());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2F0EF)),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCFEAE8), width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFE7F5F4),
                    child: Icon(Icons.person, color: _primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B4D4A),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _categoryColor(category).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _categoryColor(category),
                    ),
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _confirmDeletePost(post),
                    child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (isRepost) ...[
              Text(
                '$userName reposted',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (post['content'] != null && post['content'].toString().trim().isNotEmpty) ...[
                Text(
                  post['content'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FBFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2F0EF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE7F5F4),
                          radius: 12,
                          child: Icon(Icons.person, color: _primary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          originalPost?['User']?['name'] ?? 'Anonymous',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004D40),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      originalPost?['title'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      originalPost?['content'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                post['title'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF203B3A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                post['content'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (postId != null) {
                        _toggleLike(post);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        label: isLiked ? 'Liked' : 'Like',
                        count: '${post['likes_count'] ?? 0}',
                        color: isLiked ? Colors.red : const Color(0xFF5A6B6A),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (postId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailsScreen(postId: postId),
                          ),
                        ).then((_) => _loadPosts());
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildActionButton(
                        icon: Icons.comment_outlined,
                        label: 'Comment',
                        count: '${post['comments_count'] ?? 0}',
                        color: const Color(0xFF5A6B6A),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (postId != null) {
                        _showRepostDialog(post);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildActionButton(
                        icon: Icons.repeat,
                        label: 'Repost',
                        count: '${post['repost_count'] ?? 0}',
                        color: const Color(0xFF5A6B6A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final postId = _parseId(post['post_id']);
    if (postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid post')),
      );
      return;
    }

    try {
      final response = await _communityService.likePost(postId);
      setState(() {
        final updatedCount = response['likes_count'] ?? post['likes_count'];
        if (updatedCount is int) {
          post['likes_count'] = updatedCount < 0 ? 0 : updatedCount;
        } else {
          post['likes_count'] = updatedCount;
        }
        post['liked_by_user'] = response['liked'] ?? !(post['liked_by_user'] == true);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _confirmDeletePost(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete this post?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(post);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final postId = _parseId(post['post_id']);
    if (postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid post')),
      );
      return;
    }

    try {
      await _communityService.deletePost(postId);
      setState(() {
        _posts.removeWhere((item) => _parseId(item['post_id']) == postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post deleted', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'support':
        return const Color(0xFF3B7DCE);
      case 'question':
        return const Color(0xFF9C6ADE);
      case 'story':
        return const Color(0xFFEF6C00);
      case 'tip':
        return const Color(0xFF2E7D32);
      default:
        return _primary;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF7A8B8B),
          ),
        ),
      ],
    );
  }

  void _showNewPostDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String selectedCategory = 'general';
    bool isAnonymous = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.post_add, color: Colors.teal.shade700),
              const SizedBox(width: 10),
              Text(
                'Share Your Thoughts',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF004D40),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter title...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    hintText: 'Write something...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['general', 'support', 'question', 'story', 'tip']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      isAnonymous = value!;
                    });
                  },
                  title: Text('Post anonymously', style: GoogleFonts.poppins(fontSize: 14)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty &&
                    contentController.text.trim().isNotEmpty) {
                  try {
                    await _communityService.createPost(
                      title: titleController.text,
                      content: contentController.text,
                      category: selectedCategory,
                      isAnonymous: isAnonymous,
                    );
                    Navigator.pop(context);
                    _loadPosts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Post shared successfully!', style: GoogleFonts.poppins()),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Post',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepostDialog(Map<String, dynamic> post) {
    final TextEditingController contentController = TextEditingController();
    bool isAnonymous = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.repeat, color: Colors.green.shade700),
              const SizedBox(width: 10),
              Text(
                'Repost',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF004D40),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            radius: 12,
                            child: Icon(Icons.person, color: Colors.teal.shade700, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post['User']?['name'] ?? 'Anonymous',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF004D40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['content'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Add your thoughts (optional)',
                    hintText: 'What do you think about this?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      isAnonymous = value!;
                    });
                  },
                  title: Text('Repost anonymously', style: GoogleFonts.poppins(fontSize: 14)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _communityService.repostPost(
                    postId: post['post_id'],
                    content: contentController.text.trim().isEmpty ? null : contentController.text,
                    isAnonymous: isAnonymous,
                  );
                  Navigator.pop(context);
                  _loadPosts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reposted successfully!', style: GoogleFonts.poppins()),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Repost',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
