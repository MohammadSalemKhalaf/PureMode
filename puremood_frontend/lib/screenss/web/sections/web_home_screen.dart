import 'package:flutter/material.dart';
import 'widgets/web_navbar.dart';
import 'sections/hero_section.dart';

class WebLandingScreen extends StatelessWidget {
  const WebLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Column(
        children: const [
          WebNavbar(),   // ✅ NAVBAR
          Expanded(
            child: SingleChildScrollView(
              child: HeroSection(),
            ),
          ),
        ],
      ),
    );
  }
}
