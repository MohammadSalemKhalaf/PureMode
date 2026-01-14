import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/email_verification_service.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.onVerified,
  }) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final codeController = TextEditingController();
  final emailService = EmailVerificationService();
  bool loading = false;
  bool resending = false;
  int countdown = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  void startCountdown() {
    countdown = 60;
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (countdown > 0) {
        setState(() => countdown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> verifyCode() async {
    if (codeController.text.length != 6) {
      showMessage('Please enter a 6-digit code', Colors.red);
      return;
    }

    setState(() => loading = true);
    final result = await emailService.verifyCode(widget.email, codeController.text);
    setState(() => loading = false);

    if (result['success'] == true) {
      showMessage('Verified successfully! ✓', Colors.green);
      await Future.delayed(Duration(milliseconds: 800));
      widget.onVerified();
    } else {
      showMessage(result['message'] ?? 'Invalid code', Colors.red);
    }
  }

  Future<void> resendCode() async {
    if (countdown > 0) return;
    
    setState(() => resending = true);
    final result = await emailService.sendVerificationCode(widget.email);
    setState(() => resending = false);

    if (result['success'] == true) {
      showMessage('A new code has been sent ✓', Colors.green);
      startCountdown();
    } else {
      showMessage(result['message'] ?? 'Failed to send code', Colors.red);
    }
  }

  void showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: const Color(0xFFEFF5F5),
      appBar: AppBar(
        title: Text('Email Verification', 
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF008080),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF008080).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.email_outlined, size: 80, color: const Color(0xFF008080)),
              ),
              const SizedBox(height: 30),
              Text(
                'Check your email',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF004D40),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the code sent to',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Text(
                  widget.email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008080),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 15,
                        color: const Color(0xFF008080),
                      ),
                      decoration: InputDecoration(
                        hintText: '------',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 15,
                          color: Colors.grey[300],
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '6-digit code',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              loading
                  ? const CircularProgressIndicator(color: Color(0xFF008080))
                  : ElevatedButton(
                      onPressed: verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008080),
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Verify',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (resending)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF008080),
                      ),
                    )
                  else
                    Icon(
                      Icons.refresh,
                      color: countdown > 0 ? Colors.grey : const Color(0xFF008080),
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: countdown == 0 && !resending ? resendCode : null,
                    child: Text(
                      countdown > 0
                          ? 'Resend in $countdown seconds'
                          : 'Resend code',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: countdown > 0 ? Colors.grey : const Color(0xFF008080),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The code is valid for 10 minutes',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}