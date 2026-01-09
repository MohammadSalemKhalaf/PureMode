import 'package:flutter/material.dart';
import 'widgets/web_navbar.dart';

class AboutWebScreen extends StatelessWidget {
  const AboutWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          const WebNavbar(),
          const Expanded(
            child: Center(
              child: Text(
                'About PureMood',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
