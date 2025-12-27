import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:puremood_frontend/providers/theme_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool notificationsEnabled = true;
  bool emailNotifications = false;
  bool autoApprove = false;
  bool? darkMode;

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      // محاولة تحميل تفضيل الثيم من التخزين الآمن
      final themePreference = await _secureStorage.read(key: 'darkMode');

      if (themePreference != null) {
        // إذا كان هناك تفضيل محفوظ، استخدامه
        setState(() {
          darkMode = themePreference == 'true';
        });
      } else {
        // إذا لم يكن هناك تفضيل محفوظ، استخدام الحالة الحالية للتطبيق
        final currentIsDark = Theme.of(context).brightness == Brightness.dark;
        setState(() {
          darkMode = currentIsDark;
        });
      }
    } catch (e) {
      // في حالة الخطأ، استخدام الحالة الحالية
      final currentIsDark = Theme.of(context).brightness == Brightness.dark;
      setState(() {
        darkMode = currentIsDark;
      });
    }
  }

  Future<void> _saveThemePreference(bool value) async {
    try {
      await _secureStorage.write(key: 'darkMode', value: value.toString());
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    // إذا darkMode لم يتم تحميله بعد، عرض loading
    if (darkMode == null) {
      return Scaffold(
        backgroundColor: isDark ? Color(0xFF0A0F1C) : Color(0xFFF8FAFF),
        appBar: AppBar(
          title: Text(
            'Settings',
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
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF008080)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0A0F1C) : Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          'Settings',
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(isDark),
            SizedBox(height: 32),

            // Notifications Section
            _buildSectionHeader('🔔 Notifications', isDark),
            SizedBox(height: 12),
            _buildSettingsCard(
              [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive notifications for new users',
                  notificationsEnabled,
                      (value) => setState(() => notificationsEnabled = value),
                  Icons.notifications_active_outlined,
                  isDark,
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  'Email Notifications',
                  'Get email updates for important events',
                  emailNotifications,
                      (value) => setState(() => emailNotifications = value),
                  Icons.email_outlined,
                  isDark,
                ),
              ],
              isDark,
            ),
            SizedBox(height: 28),

            // Appearance Section
            _buildSectionHeader('🎨 Appearance', isDark),
            SizedBox(height: 12),
            _buildSettingsCard(
              [
                _buildThemeSwitchTile(isDark),
              ],
              isDark,
            ),
            SizedBox(height: 28),

            // Admin Features Section
            _buildSectionHeader('⚙️ Admin Features', isDark),
            SizedBox(height: 12),
            _buildSettingsCard(
              [
                _buildSwitchTile(
                  'Auto-Approve Patients',
                  'Automatically approve patient registrations',
                  autoApprove,
                      (value) => setState(() => autoApprove = value),
                  Icons.auto_awesome_motion_rounded,
                  isDark,
                ),
              ],
              isDark,
            ),
            SizedBox(height: 28),

            // Support Section
            _buildSectionHeader('💼 Support', isDark),
            SizedBox(height: 12),
            _buildSettingsCard(
              [
                _buildNavigationTile(
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip_outlined,
                      () {
                    _showCustomSnackBar('Opening privacy policy...', Icons.privacy_tip, context);
                  },
                  isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  'Terms of Service',
                  'Read our terms of service',
                  Icons.description_outlined,
                      () {
                    _showCustomSnackBar('Opening terms of service...', Icons.description, context);
                  },
                  isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  'About PureMood',
                  'Version 1.0.0 • Build 2024',
                  Icons.info_outline_rounded,
                      () {
                    _showAboutDialog(context);
                  },
                  isDark,
                ),
              ],
              isDark,
            ),
            SizedBox(height: 28),

            // Danger Zone
            _buildSectionHeader('⚠️ Danger Zone', isDark),
            SizedBox(height: 12),
            _buildSettingsCard(
              [
                _buildNavigationTile(
                  'Clear Cache',
                  'Remove all cached data',
                  Icons.cleaning_services_rounded,
                      () {
                    _showClearCacheDialog(context);
                  },
                  isDark,
                  textColor: Colors.orange,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  'Logout',
                  'Sign out from your account',
                  Icons.logout_rounded,
                      () {
                    _showLogoutDialog(context);
                  },
                  isDark,
                  textColor: Colors.red,
                ),
              ],
              isDark,
            ),
            SizedBox(height: 40),

            // App Version
            _buildAppVersion(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitchTile(bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentIsDark = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              currentIsDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Color(0xFF008080),
              size: 22,
            ),
          ),
          SizedBox(width: 16),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentIsDark ? 'Dark Mode' : 'Light Mode',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  currentIsDark ? 'Switch to light theme' : 'Switch to dark theme',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),

          // Switch - يعكس القيمة الحالية للثيم
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: currentIsDark, // استخدام القيمة الحالية الفعلية للثيم
              onChanged: (value) async {
                // تحديث الثيم عالمستوى العام للتطبيق
                await themeProvider.toggleTheme();

                // تحديث الحالة المحلية لو أحببنا استخدامها في أماكن أخرى
                setState(() {
                  darkMode = value;
                });
              },
              activeColor: Color(0xFF008080),
              activeTrackColor: Color(0xFF008080).withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage your preferences and settings',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Administrator',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Color(0xFF2D3748),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Color(0xFF374151) : Color(0xFFF1F5F9),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged,
      IconData icon,
      bool isDark,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Color(0xFF008080),
              size: 22,
            ),
          ),
          SizedBox(width: 16),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),

          // Switch
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Color(0xFF008080),
              activeTrackColor: Color(0xFF008080).withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      bool isDark, {
        Color? textColor,
      }) {
    final tileColor = textColor ?? (isDark ? Colors.white : Color(0xFF2D3748));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tileColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: tileColor,
                    size: 22,
                  ),
                ),
                SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: tileColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white60 : Color(0xFFCBD5E0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion(bool isDark) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: Color(0xFF008080),
              size: 28,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'PureMood v1.0.0',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Color(0xFF718096),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Mental Health Platform',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white38 : Color(0xFFA0AEC0),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomSnackBar(String message, IconData icon, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(message, style: GoogleFonts.poppins()),
          ],
        ),
        backgroundColor: Color(0xFF008080),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF008080), Color(0xFF006666)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),

              // App Name
              Text(
                'PureMood',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 8),

              // Version
              Text(
                'Version 1.0.0 • Build 2024',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),

              // Description
              Text(
                'Mental Health Tracking & Support Platform',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),

              // Copyright
              Text(
                '© 2024 PureMood. All rights reserved.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008080),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
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
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),

              // Title
              Text(
                'Clear Cache?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'This will remove all cached data including temporary files and settings. This action cannot be undone.',
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
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      onPressed: () {
                        Navigator.pop(context);
                        _showCustomSnackBar('✅ Cache cleared successfully!', Icons.cleaning_services_rounded, context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Clear',
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
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
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),

              // Title
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'Are you sure you want to logout from your account? You will need to sign in again to access the admin panel.',
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
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog

                        // مسح تفضيل الثيم أيضاً عند تسجيل الخروج
                        await _secureStorage.delete(key: 'darkMode');

                        // Clear token
                        await _secureStorage.delete(key: 'jwt');

                        // Navigate to login and remove all routes
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Logged out successfully!', style: GoogleFonts.poppins()),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Logout',
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
}