import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
          child: isDesktop
              ? Row(
                  children: [
                    _TextContent(context),
                    const Spacer(),
                    _Logo(),
                  ],
                )
              : Column(
                  children: [
                    _Logo(),
                    const SizedBox(height: 40),
                    _TextContent(context),
                  ],
                ),
        );
      },
    );
  }

  Widget _TextContent(BuildContext context) {
    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Understand Your\nMood Better.',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Track your emotions, get AI insights, and improve your mental well-being in a private way.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Get Started'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/about');
                },
                child: const Text('Learn More'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _Logo() {
    return Icon(
      Icons.spa,
      size: 200,
      color: Colors.tealAccent.shade200,
    );
  }
}
