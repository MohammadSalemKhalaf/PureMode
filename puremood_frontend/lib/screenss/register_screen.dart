import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puremood_frontend/utils/io_utils.dart';
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

  void register() async {
    // التحقق من الحقول المطلوبة
    if (emailController.text.isEmpty || passwordController.text.isEmpty || nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // إذا specialist، التحقق من الشهادة
    if (selectedRole == 'specialist') {
      if (specializationController.text.trim().isEmpty ||
          licenseController.text.trim().isEmpty ||
          experienceController.text.trim().isEmpty ||
          educationController.text.trim().isEmpty ||
          sessionPriceController.text.trim().isEmpty ||
          bioController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please complete all specialist information fields.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_specialistCertificateFile == null) {
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
    }

    setState(() => loading = true);

    // خطوة 1: إرسال رمز التحقق إلى البريد
    final emailResult = await emailService.sendVerificationCode(emailController.text);
    setState(() => loading = false);

    if (emailResult['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailResult['message'] ?? 'Failed to send verification code', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // خطوة 2: فتح شاشة التحقق من البريد
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailVerificationScreen(
          email: emailController.text,
          onVerified: () async {
            // خطوة 3: بعد التحقق، أكمل التسجيل
            setState(() => loading = true);

            Map<String, dynamic>? specialistData;
            if (selectedRole == 'specialist') {
              specialistData = {
                'specialization': specializationController.text.isNotEmpty
                    ? specializationController.text
                    : 'General Mental Health',
                'licenseNumber': licenseController.text,
                'yearsOfExperience': int.tryParse(experienceController.text) ?? 0,
                'bio': bioController.text,
                'education': educationController.text,
                'sessionPrice': double.tryParse(sessionPriceController.text) ?? 50.0,
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

            final messageText = (res['message'] ?? 'Registration failed').toString();
            final messageLower = messageText.toLowerCase();
            final isSuccess = (res['status'] == 'accepted') || messageLower.contains('successful');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  messageText,
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: isSuccess ? Colors.green : Colors.red,
              ),
            );

            if (res['message']?.contains('successfully') ?? false) {
              Navigator.pop(context); // إغلاق شاشة التحقق
              Navigator.pop(context); // الرجوع لشاشة الدخول
            }
          },
        ),
      ),
    );
  }

  Future<void> _pickSpecialistCertificate() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (file != null) {
        setState(() {
          _specialistCertificateFile = File(file.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pick certificate file.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F5),
      appBar: AppBar(
        title: Text('Create Account',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Join PureMood Today!",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Fill in your details to get started",
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),
              _buildTextField("Full Name", nameController, Icons.person),
              _buildTextField("Email", emailController, Icons.email),
              _buildTextField("Password", passwordController, Icons.lock,
                  obscure: true),
              _buildRoleDropdown(),
              _buildTextField("Age", ageController, Icons.calendar_today),
              _buildTextField("Profile Picture URL (optional)", pictureController, Icons.image),
              _buildGenderDropdown(),
              
              // Specialist additional fields
              if (selectedRole == 'specialist') ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_services, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Specialist Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField("Specialization", specializationController, Icons.psychology),
                      _buildTextField("License Number", licenseController, Icons.badge),
                      _buildTextField("Years of Experience", experienceController, Icons.work),
                      _buildTextField("Education", educationController, Icons.school),
                      _buildTextField("Session Price (\$)", sessionPriceController, Icons.attach_money),
                      _buildTextField("Bio", bioController, Icons.description, maxLines: 3),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verification Document',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _specialistCertificateFile != null
                                      ? 'Selected file: '
                                          '${_specialistCertificateFile!.path.split('/').last}'
                                      : 'Please upload your professional certificate.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _pickSpecialistCertificate,
                            icon: const Icon(Icons.upload_file, size: 18),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF008080),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            label: Text(
                              'Upload',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ Your account will be reviewed by admin before activation',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 25),
              loading
                  ? const CircularProgressIndicator(color: Color(0xFF008080))
                  : ElevatedButton(
                onPressed: register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 100, vertical: 14),
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
                child: Text(
                  "Already have an account? Login",
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF008080),
                      fontWeight: FontWeight.w500),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
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
          labelStyle:
          GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.teal, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.teal, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedRole,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF008080)),
            style: GoogleFonts.poppins(color: Colors.grey[800], fontSize: 14),
            items: [
              DropdownMenuItem(
                value: 'patient',
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF008080)),
                    const SizedBox(width: 10),
                    Text('Patient', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'specialist',
                child: Row(
                  children: [
                    const Icon(Icons.medical_services, color: Color(0xFF008080)),
                    const SizedBox(width: 10),
                    Text('Specialist', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedRole = newValue;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.teal, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedGender,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF008080)),
            style: GoogleFonts.poppins(color: Colors.grey[800], fontSize: 14),
            items: [
              DropdownMenuItem(
                value: 'male',
                child: Row(
                  children: [
                    const Icon(Icons.male, color: Color(0xFF008080)),
                    const SizedBox(width: 10),
                    Text('Male', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'female',
                child: Row(
                  children: [
                    const Icon(Icons.female, color: Color(0xFF008080)),
                    const SizedBox(width: 10),
                    Text('Female', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedGender = newValue;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}
