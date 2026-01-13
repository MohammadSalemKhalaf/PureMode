import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puremood_frontend/utils/io_utils.dart';
import 'package:puremood_frontend/services/api_service.dart';
import 'package:puremood_frontend/screenss/admin_edit_profile_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? userInfo;
  bool loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _editProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploading profile picture...'),
        ),
      );

      await _apiService.uploadProfilePicture(file);

      await _loadUserInfo();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update picture'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserInfo() async {
    setState(() => loading = true);
    try {
      final user = await _apiService.getMe();
      setState(() {
        userInfo = user;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0A0F1C) : Color(0xFFF8FAFF),
      body: loading
          ? _buildLoadingState(isDark)
          : CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          // Custom AppBar with profile header
          SliverAppBar(
            expandedHeight: size.height * 0.35,
            pinned: true,
            backgroundColor: Color(0xFF008080),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF008080),
                      Color(0xFF006666),
                      Color(0xFF004D4D),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      _buildProfileAvatar(),
                      SizedBox(height: 16),
                      Text(
                        userInfo?['name'] ?? 'Admin',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Administrator',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Section
                  _buildSectionTitle('👤 Personal Information', isDark),
                  SizedBox(height: 16),
                  _buildInfoCard(isDark),
                  SizedBox(height: 28),

                  // Account Details
                  _buildSectionTitle('📊 Account Details', isDark),
                  SizedBox(height: 16),
                  _buildAccountCard(isDark),
                  SizedBox(height: 28),

                  // Action Buttons
                  _buildActionButtons(isDark),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
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
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Profile...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final rawPicture = userInfo?['picture'] as String?;
    final userName = userInfo?['name'] ?? 'Admin';
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    String? resolvedPicture;
    if (rawPicture != null && rawPicture.isNotEmpty) {
      // لو المسار نسبي مثل /uploads/..., أضيف له base URL مثل المستخدم العادي
      final baseHost = _apiService.baseUrl.replaceFirst('/api/users', '');
      resolvedPicture = rawPicture.startsWith('http') ? rawPicture : '$baseHost$rawPicture';
    }

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white,
            backgroundImage: resolvedPicture != null ? NetworkImage(resolvedPicture) : null,
            child: resolvedPicture == null
                ? Text(
              firstLetter,
              style: GoogleFonts.poppins(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: Color(0xFF008080),
              ),
            )
                : null,
          ),
        ),
        Positioned(
          bottom: 6,
          right: 6,
          child: GestureDetector(
            onTap: _editProfilePicture,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF008080), Color(0xFF006666)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Color(0xFF2D3748),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.person_outline_rounded,
              'Full Name',
              userInfo?['name'] ?? 'Not provided',
              isDark,
            ),
            SizedBox(height: 20),
            _buildDivider(isDark),
            SizedBox(height: 20),
            _buildInfoRow(
              Icons.email_outlined,
              'Email Address',
              userInfo?['email'] ?? 'Not provided',
              isDark,
            ),
            if (userInfo?['age'] != null) ...[
              SizedBox(height: 20),
              _buildDivider(isDark),
              SizedBox(height: 20),
              _buildInfoRow(
                Icons.cake_rounded,
                'Age',
                '${userInfo?['age']} years',
                isDark,
              ),
            ],
            if (userInfo?['gender'] != null) ...[
              SizedBox(height: 20),
              _buildDivider(isDark),
              SizedBox(height: 20),
              _buildInfoRow(
                userInfo?['gender'] == 'male' ? Icons.male_rounded : Icons.female_rounded,
                'Gender',
                userInfo?['gender']?.toString().toUpperCase() ?? 'Not specified',
                isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(bool isDark) {
    final role = userInfo?['role']?.toString().toUpperCase() ?? 'ADMIN';
    final status = userInfo?['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final isVerified = userInfo?['verified'] == true;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAccountRow(
              Icons.admin_panel_settings_rounded,
              'Role',
              role,
              Color(0xFF008080),
              isDark,
            ),
            SizedBox(height: 20),
            _buildDivider(isDark),
            SizedBox(height: 20),
            _buildAccountRow(
              Icons.verified_user_rounded,
              'Status',
              status,
              status == 'ACTIVE' ? Color(0xFF10B981) : Colors.orange,
              isDark,
            ),
            SizedBox(height: 20),
            _buildDivider(isDark),
            SizedBox(height: 20),
            _buildAccountRow(
              isVerified ? Icons.verified_rounded : Icons.pending_rounded,
              'Verification',
              isVerified ? 'Verified' : 'Pending',
              isVerified ? Color(0xFF10B981) : Color(0xFFF59E0B),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFF008080).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Color(0xFF008080),
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Color(0xFF2D3748),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value.split(' ').first,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Color(0xFF374151) : Color(0xFFF1F5F9),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        // Edit Profile Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF008080), Color(0xFF006666)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminEditProfileScreen(userInfo: userInfo!),
                  ),
                );

                if (result == true) {
                  _loadUserInfo(); // Refresh the profile
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),

        // Change Password Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Color(0xFF374151) : Color(0xFFE2E8F0),
              width: 2,
            ),
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
                _showChangePasswordDialog(isDark);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_reset_rounded, color: Color(0xFF008080), size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Change Password',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF008080),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(bool isDark) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
        child: Container(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: Color(0xFF008080),
                  size: 32,
                ),
              ),
              SizedBox(height: 20),

              Text(
                'Change Password',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 8),

              Text(
                'Enter your current and new password',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Color(0xFF718096),
                ),
              ),
              SizedBox(height: 24),

              // Form
              Form(
                key: formKey,
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: oldPasswordController,
                      label: 'Current Password',
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 16),
                    _buildPasswordField(
                      controller: newPasswordController,
                      label: 'New Password',
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
                    ),
                    SizedBox(height: 16),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.verified_user_rounded,
                      isDark: isDark,
                      validator: (v) => v != newPasswordController.text ? 'Passwords do not match' : null,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? Color(0xFF4B5563) : Color(0xFFD1D5DB),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          _showSuccessSnackBar('✅ Password changed successfully!');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008080),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Update',
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
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.poppins(
        color: isDark ? Colors.white : Color(0xFF2D3748),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: isDark ? Colors.white60 : Color(0xFF6B7280),
        ),
        prefixIcon: Icon(icon, color: Color(0xFF008080)),
        filled: true,
        fillColor: isDark ? Color(0xFF374151) : Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF008080), width: 2),
        ),
      ),
      validator: validator,
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
