import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/admin_service.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({Key? key}) : super(key: key);

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> allPosts = [];
  List<dynamic> filteredPosts = [];
  bool loading = true;
  String error = '';
  String? selectedCategory;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await _adminService.getAllPosts();
      setState(() {
        allPosts = response['posts'] ?? [];
        _applyFilters();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _applyFilters() {
    List<dynamic> result = allPosts;

    // Filter by category
    if (selectedCategory != null) {
      result = result.where((post) => post['category'] == selectedCategory).toList();
    }

    // Filter by search
    if (searchController.text.isNotEmpty) {
      final searchTerm = searchController.text.toLowerCase();
      result = result.where((post) {
        final title = post['title']?.toString().toLowerCase() ?? '';
        final content = post['content']?.toString().toLowerCase() ?? '';
        final userName = post['User']?['name']?.toString().toLowerCase() ?? '';
        final userEmail = post['User']?['email']?.toString().toLowerCase() ?? '';

        return title.contains(searchTerm) ||
            content.contains(searchTerm) ||
            userName.contains(searchTerm) ||
            userEmail.contains(searchTerm);
      }).toList();
    }

    setState(() {
      filteredPosts = result;
    });
  }

  Future<void> _deletePost(int postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, size: 32, color: Colors.red),
              ),
              SizedBox(height: 16),

              // Title
              Text(
                'Delete Post?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'This action cannot be undone. The post and all its comments will be permanently deleted.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deletePost(postId);
        _showSuccessSnackBar('🗑️ Post deleted successfully');
        _loadPosts();
      } catch (e) {
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  Future<void> _deleteComment(int commentId, Map<String, dynamic> post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, size: 32, color: Colors.orange),
              ),
              SizedBox(height: 16),

              // Title
              Text(
                'Delete Comment?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'This action cannot be undone. The comment will be permanently deleted.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteComment(commentId);
        _showSuccessSnackBar('🗑️ Comment deleted successfully');
        _removeCommentFromList(commentId, post);
      } catch (e) {
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  void _removeCommentFromList(int commentId, Map<String, dynamic> post) {
    setState(() {
      // البحث عن المنشور في القائمة وتحديثه
      final postIndex = filteredPosts.indexWhere((p) => p['post_id'] == post['post_id']);
      if (postIndex != -1) {
        final updatedPost = Map<String, dynamic>.from(filteredPosts[postIndex]);
        final comments = List<dynamic>.from(updatedPost['comments'] ?? []);
        comments.removeWhere((comment) =>
        comment['comment_id'] == commentId || comment['id'] == commentId);
        updatedPost['comments'] = comments;
        updatedPost['comments_count'] = (updatedPost['comments_count'] ?? 1) - 1;

        filteredPosts[postIndex] = updatedPost;
      }
    });
  }

  void _showCommentsDialog(Map<String, dynamic> post) {
    final comments = post['comments'] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.comment_rounded, color: Color(0xFF008080), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Comments (${comments.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Color(0xFF2D3748),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Comments List
              if (comments.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment_outlined, size: 50, color: Colors.grey[400]),
                        SizedBox(height: 12),
                        Text(
                          'No Comments',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _buildCommentCard(comment, isDark, post);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, bool isDark, Map<String, dynamic> post) {
    final userName = comment['User']?['name'] ?? 'Anonymous';
    final userEmail = comment['User']?['email'] ?? '';
    final commentId = comment['comment_id'] ?? comment['id'] ?? 0;
    final content = comment['content'] ?? '';
    final createdAt = comment['created_at'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF374151) : Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Color(0xFF4B5563) : Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF008080),
                  size: 16,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      userEmail,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Color(0xFF718096),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                  onPressed: () => _deleteComment(commentId, post),
                  tooltip: 'Delete Comment',
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Comment Content
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white70 : Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
          SizedBox(height: 8),

          // Comment Date
          if (createdAt != null)
            Text(
              _formatDate(createdAt),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isDark ? Colors.white38 : Color(0xFFA0AEC0),
              ),
            ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return WebScaffold(
      backgroundColor: isDark ? Color(0xFF0A0F1C) : Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          'Posts Management',
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
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 24),
            onPressed: _loadPosts,
            tooltip: 'Refresh',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          _buildHeaderStats(isDark),

          // Filters Section
          _buildFiltersSection(isDark),

          // Posts List
          Expanded(
            child: loading
                ? _buildLoadingState()
                : error.isNotEmpty
                ? _buildErrorState(isDark)
                : filteredPosts.isEmpty
                ? _buildEmptyState(isDark)
                : _buildPostsList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(bool isDark) {
    final totalPosts = filteredPosts.length;
    final totalLikes = filteredPosts.fold<int>(0, (sum, post) => sum + ((post['likes_count'] as num?)?.toInt() ?? 0));
    final totalComments = filteredPosts.fold<int>(0, (sum, post) => sum + ((post['comments_count'] as num?)?.toInt() ?? 0));

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF008080),
            Color(0xFF006666),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF008080).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.article_rounded, totalPosts, 'Total Posts', Colors.white),
          _buildStatItem(Icons.thumb_up_rounded, totalLikes, 'Total Likes', Colors.orange.shade200),
          _buildStatItem(Icons.comment_rounded, totalComments, 'Total Comments', Colors.green.shade200),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF0F172A) : Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search posts by title, content, or user...',
                hintStyle: GoogleFonts.poppins(color: isDark ? Colors.white60 : Colors.grey[600]),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white60 : Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    searchController.clear();
                    _applyFilters();
                  },
                )
                    : null,
              ),
              style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
              onChanged: (value) => _applyFilters(),
            ),
          ),
          SizedBox(height: 12),

          // Category Filter
          Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF0F172A) : Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                hintText: 'Filter by Category',
                hintStyle: GoogleFonts.poppins(color: isDark ? Colors.white60 : Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: isDark ? Color(0xFF1E293B) : Colors.white,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('All Categories', style: GoogleFonts.poppins())),
                DropdownMenuItem(value: 'support', child: Text('Support', style: GoogleFonts.poppins())),
                DropdownMenuItem(value: 'question', child: Text('Question', style: GoogleFonts.poppins())),
                DropdownMenuItem(value: 'story', child: Text('Story', style: GoogleFonts.poppins())),
                DropdownMenuItem(value: 'tip', child: Text('Tip', style: GoogleFonts.poppins())),
                DropdownMenuItem(value: 'general', child: Text('General', style: GoogleFonts.poppins())),
              ],
              onChanged: (value) {
                setState(() => selectedCategory = value);
                _applyFilters();
              },
              icon: Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white60 : Colors.grey[500]),
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
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
                    Icons.article_rounded,
                    color: Color(0xFF008080),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading Posts...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load posts',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008080),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try Again', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFF008080).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.article_outlined, size: 50, color: Color(0xFF008080)),
            ),
            SizedBox(height: 20),
            Text(
              'No Posts Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      backgroundColor: Color(0xFF008080),
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          return _buildPostCard(post, isDark);
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    final categoryColors = {
      'support': Color(0xFFEC4899),
      'question': Color(0xFF3B82F6),
      'story': Color(0xFF8B5CF6),
      'tip': Color(0xFF10B981),
      'general': Color(0xFF6B7280),
    };

    final category = post['category'] ?? 'general';
    final categoryColor = categoryColors[category] ?? Colors.grey;
    final userName = post['User']?['name'] ?? 'Anonymous';
    final userEmail = post['User']?['email'] ?? '';
    final postId = post['post_id'] ?? 0;
    final likesCount = (post['likes_count'] as num?)?.toInt() ?? 0;
    final commentsCount = (post['comments_count'] as num?)?.toInt() ?? 0;
    final comments = post['comments'] ?? [];
    final createdAt = post['created_at'];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showCommentsDialog(post);
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user info and category
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(0xFF008080).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Color(0xFF008080),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Color(0xFF718096),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Color(0xFFA0AEC0),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Category Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: categoryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Post Title
                Text(
                  post['title'] ?? 'No Title',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Color(0xFF2D3748),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8),

                // Post Content
                Text(
                  post['content'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Color(0xFF4A5568),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),

                // Stats and Actions
                Row(
                  children: [
                    // Likes
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_rounded, size: 14, color: Color(0xFF008080)),
                          SizedBox(width: 4),
                          Text(
                            likesCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),

                    // Comments Button
                    GestureDetector(
                      onTap: () => _showCommentsDialog(post),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.comment_rounded, size: 14, color: Color(0xFF008080)),
                            SizedBox(width: 4),
                            Text(
                              commentsCount.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),

                    // Delete Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        onPressed: () => _deletePost(postId),
                        tooltip: 'Delete Post',
                        padding: EdgeInsets.all(6),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }
}