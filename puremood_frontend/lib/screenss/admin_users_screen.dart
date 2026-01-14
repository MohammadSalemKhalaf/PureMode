import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> users = [];
  bool loading = true;
  String error = '';
  String? selectedRole;
  String? selectedStatus;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await _adminService.getAllUsers(
        role: selectedRole,
        status: selectedStatus,
        search: searchController.text.isEmpty ? null : searchController.text,
      );
      setState(() {
        users = response['users'] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Delete',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User deleted successfully', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _updateUserStatus(int userId, String status) async {
    try {
      await _adminService.updateUser(userId, status: status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User status updated to $status', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _updateUserRole(int userId, String role) async {
    try {
      await _adminService.updateUser(userId, role: role);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User role updated to $role', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating role: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return WebScaffold(
      backgroundColor: isDark ? Color(0xFF0A0F1C) : Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          'User Management',
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
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea( // ← الإصلاح 1: إضافة SafeArea
        child: Column(
          children: [
            // Header Stats
            _buildHeaderStats(isDark),

            // Filters Section
            _buildFiltersSection(isDark),

            // Users List - FIXED: Added Expanded to prevent overflow
            Expanded(
              child: loading
                  ? _buildLoadingState()
                  : error.isNotEmpty
                  ? _buildErrorState(isDark)
                  : users.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildUsersList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats(bool isDark) {
    final totalUsers = users.length;
    final activeUsers = users.where((user) => user['status'] == 'accepted').length;
    final specialistUsers = users.where((user) => user['role'] == 'specialist').length;

    return Container(
      margin: EdgeInsets.all(16), // ← الإصلاح 2: تقليل الـ margin
      padding: EdgeInsets.all(16), // ← الإصلاح 3: تقليل الـ padding
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
          _buildStatItem(Icons.people_alt_rounded, totalUsers, 'Total Users', Colors.white),
          _buildStatItem(Icons.verified_rounded, activeUsers, 'Active', Colors.green.shade200),
          _buildStatItem(Icons.medical_services_rounded, specialistUsers, 'Specialists', Colors.teal.shade200),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(10), // ← الإصلاح 4: تقليل حجم الأيقونة
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20), // ← الإصلاح 5: تقليل حجم الأيقونة
        ),
        SizedBox(height: 6), // ← الإصلاح 6: تقليل المسافات
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 20, // ← الإصلاح 7: تقليل حجم الخط
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2), // ← الإصلاح 8: تقليل المسافات
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10, // ← الإصلاح 9: تقليل حجم الخط
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // ← الإصلاح 10: تقليل الـ margin
      padding: EdgeInsets.all(12), // ← الإصلاح 11: تقليل الـ padding
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
                hintText: 'Search users by name or email...',
                hintStyle: GoogleFonts.poppins(color: isDark ? Colors.white60 : Colors.grey[600]),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white60 : Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ← الإصلاح 12: تقليل الـ padding
              ),
              style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
              onChanged: (value) => _loadUsers(),
            ),
          ),
          SizedBox(height: 8), // ← الإصلاح 13: تقليل المسافة

          // Filters Row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  value: selectedRole,
                  items: [
                    DropdownMenuItem(value: null, child: Text('All Roles', style: GoogleFonts.poppins())),
                    DropdownMenuItem(value: 'patient', child: Text('Patient', style: GoogleFonts.poppins())),
                    DropdownMenuItem(value: 'specialist', child: Text('Specialist', style: GoogleFonts.poppins())),
                    DropdownMenuItem(value: 'admin', child: Text('Admin', style: GoogleFonts.poppins())),
                  ],
                  hint: 'Filter by Role',
                  onChanged: (value) {
                    setState(() => selectedRole = value);
                    _loadUsers();
                  },
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 8), // ← الإصلاح 14: تقليل المسافة
              Expanded(
                child: _buildFilterDropdown(
                  value: selectedStatus,
                  items: [
                    DropdownMenuItem(value: null, child: Text('All Status', style: GoogleFonts.poppins())),
                    DropdownMenuItem(value: 'accepted', child: Text('Accepted', style: GoogleFonts.poppins())),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected', style: GoogleFonts.poppins())),
                  ],
                  hint: 'Filter by Status',
                  onChanged: (value) {
                    setState(() => selectedStatus = value);
                    _loadUsers();
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required String hint,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF0F172A) : Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: isDark ? Colors.white60 : Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ← الإصلاح 15: تقليل الـ padding
        ),
        dropdownColor: isDark ? Color(0xFF1E293B) : Colors.white,
        style: GoogleFonts.poppins(
          fontSize: 13, // ← الإصلاح 16: تقليل حجم الخط
          color: isDark ? Colors.white : Colors.black87,
        ),
        items: items,
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white60 : Colors.grey[500]),
        isExpanded: true,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50, // ← الإصلاح 17: تقليل الحجم
            height: 50, // ← الإصلاح 18: تقليل الحجم
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF008080)),
                    strokeWidth: 2, // ← الإصلاح 19: تقليل سمك الـ progress indicator
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.people_rounded,
                    color: Color(0xFF008080),
                    size: 20, // ← الإصلاح 20: تقليل حجم الأيقونة
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12), // ← الإصلاح 21: تقليل المسافة
          Text(
            'Loading Users...',
            style: GoogleFonts.poppins(
              fontSize: 13, // ← الإصلاح 22: تقليل حجم الخط
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16), // ← الإصلاح 23: تقليل الـ padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, // ← الإصلاح 24: تقليل الحجم
              height: 60, // ← الإصلاح 25: تقليل الحجم
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 30, color: Colors.red), // ← الإصلاح 26: تقليل حجم الأيقونة
            ),
            SizedBox(height: 12), // ← الإصلاح 27: تقليل المسافة
            Text(
              'Failed to load users',
              style: GoogleFonts.poppins(
                fontSize: 14, // ← الإصلاح 28: تقليل حجم الخط
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 6), // ← الإصلاح 29: تقليل المسافة
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16), // ← الإصلاح 30: تقليل الـ padding
              child: Text(
                error,
                style: GoogleFonts.poppins(
                  fontSize: 11, // ← الإصلاح 31: تقليل حجم الخط
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 12), // ← الإصلاح 32: تقليل المسافة
            ElevatedButton.icon(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008080),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // ← الإصلاح 33: تقليل الـ padding
              ),
              icon: Icon(Icons.refresh_rounded, size: 16), // ← الإصلاح 34: تقليل حجم الأيقونة
              label: Text('Try Again', style: GoogleFonts.poppins(fontSize: 12)), // ← الإصلاح 35: تقليل حجم الخط
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16), // ← الإصلاح 36: تقليل الـ padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, // ← الإصلاح 37: تقليل الحجم
              height: 80, // ← الإصلاح 38: تقليل الحجم
              decoration: BoxDecoration(
                color: Color(0xFF008080).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded, size: 35, color: Color(0xFF008080)), // ← الإصلاح 39: تقليل حجم الأيقونة
            ),
            SizedBox(height: 12), // ← الإصلاح 40: تقليل المسافة
            Text(
              'No Users Found',
              style: GoogleFonts.poppins(
                fontSize: 16, // ← الإصلاح 41: تقليل حجم الخط
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 6), // ← الإصلاح 42: تقليل المسافة
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.poppins(
                fontSize: 12, // ← الإصلاح 43: تقليل حجم الخط
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      backgroundColor: Color(0xFF008080),
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.all(12), // ← الإصلاح 44: تقليل الـ padding
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user, isDark);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isDark) {
    final roleColor = _getRoleColor(user['role']);
    final statusColor = _getStatusColor(user['status']);
    final userEmail = user['email'] ?? 'No email';
    final userName = user['name'] ?? 'Unknown User';
    final userId = user['user_id'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8), // ← الإصلاح 45: تقليل الـ margin
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
          onTap: () => _showUserDetails(userId),
          child: Padding(
            padding: EdgeInsets.all(12), // ← الإصلاح 46: تقليل الـ padding
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 40, // ← الإصلاح 47: تقليل الحجم
                  height: 40, // ← الإصلاح 48: تقليل الحجم
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getRoleIcon(user['role']),
                    color: roleColor,
                    size: 20, // ← الإصلاح 49: تقليل حجم الأيقونة
                  ),
                ),
                SizedBox(width: 12), // ← الإصلاح 50: تقليل المسافة

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 14, // ← الإصلاح 51: تقليل حجم الخط
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2), // ← الإصلاح 52: تقليل المسافة
                      Text(
                        userEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 11, // ← الإصلاح 53: تقليل حجم الخط
                          color: isDark ? Colors.white60 : Color(0xFF718096),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6), // ← الإصلاح 54: تقليل المسافة
                      Wrap(
                        spacing: 6, // ← الإصلاح 55: تقليل المسافة
                        runSpacing: 4,
                        children: [
                          _buildBadge(user['role']?.toString().toUpperCase() ?? '', roleColor),
                          _buildBadge(user['status']?.toString().toUpperCase() ?? '', statusColor),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                _buildUserActions(user, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // ← الإصلاح 56: تقليل الـ padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6), // ← الإصلاح 57: تقليل الـ border radius
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 8, // ← الإصلاح 58: تقليل حجم الخط
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUserActions(Map<String, dynamic> user, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white60 : Colors.grey[500], size: 20), // ← الإصلاح 59: تقليل حجم الأيقونة
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
              SizedBox(width: 6),
              Text('View Details', style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'change_role',
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.purple),
              SizedBox(width: 6),
              Text('Change Role', style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 6),
              Text('Delete User', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'view':
            _showUserDetails(user['user_id']);
            break;
          case 'change_role':
            await _showRoleChangeDialog(user);
            break;
          case 'delete':
            _deleteUser(user['user_id']);
            break;
        }
      },
    );
  }

  Future<void> _showRoleChangeDialog(Map<String, dynamic> user) async {
    String? newRole = user['role'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Change User Role',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16), // ← الإصلاح 75: تقليل حجم الخط
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current role: ${user['role']?.toString().toUpperCase()}',
              style: GoogleFonts.poppins(fontSize: 13), // ← الإصلاح 76: تقليل حجم الخط
            ),
            SizedBox(height: 12), // ← الإصلاح 77: تقليل المسافة
            DropdownButtonFormField<String>(
              value: newRole,
              decoration: InputDecoration(
                labelText: 'Select New Role',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ← الإصلاح 78: تقليل الـ padding
              ),
              style: GoogleFonts.poppins(fontSize: 13), // ← الإصلاح 79: تقليل حجم الخط
              items: [
                DropdownMenuItem(value: 'patient', child: Text('Patient', style: GoogleFonts.poppins(fontSize: 13))), // ← الإصلاح 80: تقليل حجم الخط
                DropdownMenuItem(value: 'specialist', child: Text('Specialist', style: GoogleFonts.poppins(fontSize: 13))), // ← الإصلاح 81: تقليل حجم الخط
                DropdownMenuItem(value: 'admin', child: Text('Admin', style: GoogleFonts.poppins(fontSize: 13))), // ← الإصلاح 82: تقليل حجم الخط
              ],
              onChanged: (value) {
                newRole = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 13)), // ← الإصلاح 83: تقليل حجم الخط
          ),
          ElevatedButton(
            onPressed: () {
              if (newRole != null && newRole != user['role']) {
                _updateUserRole(user['user_id'], newRole!);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF008080),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // ← الإصلاح 84: تقليل الـ padding
            ),
            child: Text('Update Role', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)), // ← الإصلاح 85: تقليل حجم الخط
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Color(0xFF8B5CF6);
      case 'specialist':
        return Color(0xFF008080);
      case 'patient':
        return Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'accepted':
        return Color(0xFF10B981);
      case 'rejected':
        return Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'specialist':
        return Icons.medical_services_rounded;
      case 'patient':
        return Icons.person_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  void _showUserDetails(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserDetailsScreen(userId: userId),
      ),
    );
  }
}

class AdminUserDetailsScreen extends StatefulWidget {
  final int userId;

  const AdminUserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> userDetails = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => loading = true);
    try {
      final response = await _adminService.getUserDetails(widget.userId);
      setState(() {
        userDetails = response;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = userDetails['user'] ?? {};
    final stats = userDetails['statistics'] ?? {};

    return WebScaffold(
      backgroundColor: isDark ? Color(0xFF0A0F1C) : Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          'User Details',
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
      ),
      body: loading
          ? _buildLoadingState()
          : _buildUserDetailsContent(user, stats, isDark),
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
                    Icons.person_rounded,
                    color: Color(0xFF008080),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading User Details...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsContent(Map<String, dynamic> user, Map<String, dynamic> stats, bool isDark) {
    final roleColor = _getRoleColor(user['role']);
    final statusColor = _getStatusColor(user['status']);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // User Profile Card
          _buildProfileCard(user, roleColor, statusColor, isDark),
          SizedBox(height: 20),

          // Statistics Cards
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _buildStatCard('Mood Entries', stats['moodCount'] ?? 0, Icons.emoji_emotions_rounded, Color(0xFF8B5CF6), isDark),
              _buildStatCard('Posts', stats['postCount'] ?? 0, Icons.article_rounded, Color(0xFF3B82F6), isDark),
              _buildStatCard('Comments', stats['commentCount'] ?? 0, Icons.comment_rounded, Color(0xFF10B981), isDark),
            ],
          ),
          SizedBox(height: 20),

          // User Information Card
          _buildInfoCard(user, isDark),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user, Color roleColor, Color statusColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF008080),
            Color(0xFF006666),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF008080).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              _getRoleIcon(user['role']),
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(width: 20),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown User',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  user['email'] ?? 'No email',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildDetailBadge(user['role']?.toString().toUpperCase() ?? '', roleColor),
                    _buildDetailBadge(user['status']?.toString().toUpperCase() ?? '', statusColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isDark ? Colors.white60 : Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> user, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 User Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow('User ID', user['user_id']?.toString() ?? 'N/A', isDark),
          _buildInfoRow('Registration Date', _formatDate(user['created_at']), isDark),
          _buildInfoRow('Last Login', _formatDate(user['last_login']), isDark),
          _buildInfoRow('Account Status', user['status']?.toString().toUpperCase() ?? 'N/A', isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white60 : Color(0xFF718096),
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Color(0xFF2D3748),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    // Add your date formatting logic here
    return date.toString();
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Color(0xFF8B5CF6);
      case 'specialist':
        return Color(0xFF008080);
      case 'patient':
        return Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'accepted':
        return Color(0xFF10B981);
      case 'rejected':
        return Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'specialist':
        return Icons.medical_services_rounded;
      case 'patient':
        return Icons.person_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }
}
