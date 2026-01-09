import 'package:flutter/material.dart';

class AboutWebScreen extends StatelessWidget {
  const AboutWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f172a),
        elevation: 0,
        title: const Text('About PureMood'),
      ),
      body: const Center(
        child: Text(
          'PureMood helps you understand and track your mental well-being\nusing simple tools and AI insights.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
