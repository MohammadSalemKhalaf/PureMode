import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:puremood_frontend/services/api_service.dart';
import 'package:puremood_frontend/services/email_verification_service.dart';
import 'package:puremood_frontend/screenss/email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ageController = TextEditingController();
  final pictureController = TextEditingController();

  String selectedRole = 'patient';
  String selectedGender = 'male';

  // Specialist fields
  final specializationController = TextEditingController();
  final licenseController = TextEditingController();
  final experienceController = TextEditingController();
  final bioController = TextEditingController();
  final educationController = TextEditingController();
  final sessionPriceController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _specialistCertificateFile;

  final api = ApiService();
  final emailService = EmailVerificationService();

  bool loading = false;

  // ========================= REGISTER LOGIC (بدون تعديل) =========================
  void register() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedRole == 'specialist' && _specialistCertificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload your certificate before completing registration.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    final emailResult =
        await emailService.sendVerificationCode(emailController.text);

    setState(() => loading = false);

    if (emailResult['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              emailResult['message'] ?? 'Failed to send verification code',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailVerificationScreen(
          email: emailController.text,
          onVerified: () async {
            setState(() => loading = true);

            Map<String, dynamic>? specialistData;
            if (selectedRole == 'specialist') {
              specialistData = {
                'specialization': specializationController.text,
                'licenseNumber': licenseController.text,
                'yearsOfExperience':
                    int.tryParse(experienceController.text) ?? 0,
                'bio': bioController.text,
                'education': educationController.text,
                'sessionPrice':
                    double.tryParse(sessionPriceController.text) ?? 50,
                'languages': ['Arabic', 'English'],
              };
            }

            final res = await api.register(
              nameController.text,
              emailController.text,
              passwordController.text,
              selectedRole,
              int.tryParse(ageController.text) ?? 0,
              selectedGender,
              specialistData: specialistData,
              certificateFile: _specialistCertificateFile,
              picture: pictureController.text,
            );

            setState(() => loading = false);

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['message'] ?? 'Registration failed',
                    style: GoogleFonts.poppins()),
                backgroundColor:
                    res['message']?.contains('successfully') ?? false
                        ? Colors.green
                        : Colors.red,
              ),
            );

            if (res['message']?.contains('successfully') ?? false) {
              Navigator.pop(context);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Future<void> _pickSpecialistCertificate() async {
    final XFile? file =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _specialistCertificateFile = File(file.path);
      });
    }
  }

  // ========================= BUILD =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F5),
      appBar: AppBar(
        title: Text('Create Account',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF008080),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth >= 900;

          // ================= MOBILE (كما هو تمامًا) =================
          if (!isWeb) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(child: _registerForm()),
            );
          }

          // ================= WEB =================
          return Center(
            child: SingleChildScrollView(
              child: Container(
                width: 720,
                margin: const EdgeInsets.symmetric(vertical: 40),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _registerForm(),
              ),
            ),
          );
        },
      ),
    );
  }

  // ========================= FORM (مشترك) =========================
  Widget _registerForm() {
    return Column(
      children: [
        Text("Join PureMood Today!",
            style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004D40))),
        const SizedBox(height: 8),
        Text("Fill in your details to get started",
            style:
                GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 30),

        _buildTextField("Full Name", nameController, Icons.person),
        _buildTextField("Email", emailController, Icons.email),
        _buildTextField("Password", passwordController, Icons.lock,
            obscure: true),
        _buildRoleDropdown(),
        _buildTextField("Age", ageController, Icons.calendar_today),
        _buildTextField(
            "Profile Picture URL (optional)", pictureController, Icons.image),
        _buildGenderDropdown(),

        if (selectedRole == 'specialist') ...[
          const SizedBox(height: 20),
          _buildSpecialistSection(),
        ],

        const SizedBox(height: 30),

        loading
            ? const CircularProgressIndicator(color: Color(0xFF008080))
            : ElevatedButton(
                onPressed: register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Register",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),

        const SizedBox(height: 20),

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Already have an account? Login",
              style: GoogleFonts.poppins(
                  color: const Color(0xFF008080),
                  fontWeight: FontWeight.w500)),
        )
      ],
    );
  }

  // ========================= UI HELPERS =========================
  Widget _buildTextField(String label, TextEditingController controller,
      IconData icon,
      {bool obscure = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF008080)),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide:
                const BorderSide(color: Color(0xFF008080), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return _dropdown(
      value: selectedRole,
      items: const ['patient', 'specialist', 'admin'],
      icon: Icons.person,
      onChanged: (v) => setState(() => selectedRole = v),
    );
  }

  Widget _buildGenderDropdown() {
    return _dropdown(
      value: selectedGender,
      items: const ['male', 'female'],
      icon: Icons.male,
      onChanged: (v) => setState(() => selectedGender = v),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.teal),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e[0].toUpperCase() + e.substring(1)),
                    ))
                .toList(),
            onChanged: (v) => onChanged(v!),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialistSection() {
    return Column(
      children: [
        _buildTextField(
            "Specialization", specializationController, Icons.psychology),
        _buildTextField("License Number", licenseController, Icons.badge),
        _buildTextField(
            "Years of Experience", experienceController, Icons.work),
        _buildTextField("Education", educationController, Icons.school),
        _buildTextField(
            "Session Price", sessionPriceController, Icons.attach_money),
        _buildTextField("Bio", bioController, Icons.description,
            maxLines: 3),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _pickSpecialistCertificate,
          icon: const Icon(Icons.upload_file),
          label: const Text("Upload Certificate"),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080)),
        ),
      ],
    );
  }
}
