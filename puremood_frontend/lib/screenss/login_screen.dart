import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'DashboardScreen.dart';
import 'specialist_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'package:puremood_frontend/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final api = ApiService();
  bool loading = false;
  bool isPasswordVisible = false;

  void login() async {
    setState(() => loading = true);
    final res = await api.login(
      emailController.text,
      passwordController.text,
    );
    setState(() => loading = false);

    if (res['token'] != null) {
      final role = res['role'] ?? 'patient';
      final userName =
          res['user'] != null ? res['user']['name'] ?? 'User' : 'User';

      Widget destination;
      if (role == 'specialist') {
        destination = SpecialistDashboardScreen();
      } else if (role == 'admin') {
        destination = const AdminDashboardScreen();
      } else {
        destination = DashboardScreen(userName: userName);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Login failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xfff4faf8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: isWebLayout
              ? _buildWebLayout()
              : _buildMobileLayout(),
        ),
      ),
    );
  }

  // ================= MOBILE =================
  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: _loginForm(),
    );
  }

  // ================= WEB =================
  Widget _buildWebLayout() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _loginForm(),
      ),
    );
  }

  // ================= SHARED FORM =================
  Widget _loginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.spa_rounded, size: 80, color: Colors.teal.shade400),
        const SizedBox(height: 10),
        Text(
          "PureMood",
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        const SizedBox(height: 40),

        TextField(
          controller: emailController,
          decoration: _inputDecoration(
            label: 'Email',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          decoration: _inputDecoration(
            label: 'Password',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.teal,
              ),
              onPressed: () =>
                  setState(() => isPasswordVisible = !isPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: loading ? null : login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Login",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
              );
            },
            child: Text(
              "Forgot Password?",
              style: GoogleFonts.poppins(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don’t have an account?",
              style: GoogleFonts.poppins(color: Colors.grey[800]),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                );
              },
              child: Text(
                "Sign Up",
                style: GoogleFonts.poppins(
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      prefixIcon: Icon(icon, color: Colors.teal),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }
}
