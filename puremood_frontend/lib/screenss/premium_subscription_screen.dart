import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_subscription_service.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  @override
  _PremiumSubscriptionScreenState createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final UserSubscriptionService _subscriptionService = UserSubscriptionService();
  bool _isLoading = false;

  Future<void> _purchasePremium() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.purchasePremium();
      Navigator.pop(context, true);
    } catch (e) {
      print('Error purchasing premium: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error purchasing premium. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startFreeTrial() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.startFreeTrial();
      Navigator.pop(context, true);
    } catch (e) {
      print('Error starting trial: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting trial. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00695C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
                    SizedBox(height: 20),
                    Text('Go Premium',
                        style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        )),
                    SizedBox(height: 10),
                    Text('Unlock advanced mental wellness features',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70
                        )),
                  ],
                ),
              ),

              // Features
              Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeature('🧠 AI-Powered Mood Analysis', 'Advanced pattern recognition and insights'),
                    _buildFeature('👨‍⚕️ Professional Therapy Sessions', 'Access to licensed therapists'),
                    _buildFeature('📊 Detailed Analytics', 'Comprehensive mood tracking and insights'),
                    _buildFeature('🎯 Personalized Wellness Plans', 'Custom plans based on your patterns'),
                    _buildFeature('🔒 Ad-Free Experience', 'No interruptions or distractions'),
                    _buildFeature('💝 Priority Support', '24/7 dedicated customer support'),
                    _buildFeature('📚 Exclusive Content', 'Premium articles and resources'),
                    _buildFeature('🎮 Advanced Challenges', 'Personalized growth challenges'),
                  ],
                ),
              ),

              // Pricing Plans
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    // Annual Plan
                    _buildPlanCard(
                      'Annual Plan',
                      '\$49.99/year',
                      '\$4.17/month',
                      'Save 48% compared to monthly',
                      Colors.amber,
                      true,
                    ),
                    SizedBox(height: 15),

                    // Monthly Plan
                    _buildPlanCard(
                      'Monthly Plan',
                      '\$7.99/month',
                      'Billed monthly',
                      'Flexible monthly subscription',
                      Colors.blue,
                      false,
                    ),
                    SizedBox(height: 15),

                    // Free Trial
                    _buildTrialCard(),
                    SizedBox(height: 30),

                    // Purchase Buttons
                    _buildPurchaseButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String title, String subtitle) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16
                    )),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, String subtitle, String saving, Color color, bool isPopular) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D3047),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('MOST POPULAR',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold
                      )),
                ),
                SizedBox(height: 10),
              ],
              Text(title,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  )),
              SizedBox(height: 5),
              Text(price,
                  style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                  )),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12
                  )),
              SizedBox(height: 5),
              Text(saving,
                  style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.green, size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('7-Day Free Trial',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    )),
                Text('Try all premium features for free',
                    style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButtons() {
    return Column(
      children: [
        // Free Trial Button
        Container(
          width: double.infinity,
          height: 56,
          margin: EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _startFreeTrial,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Start 7-Day Free Trial',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                )),
          ),
        ),

        // Purchase Button
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _purchasePremium,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Purchase Premium',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                )),
          ),
        ),

        SizedBox(height: 10),
        Text('Cancel anytime. No commitment.',
            style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12
            )),

        // For testing: Reset to free button
        SizedBox(height: 20),
        TextButton(
          onPressed: () async {
            await _subscriptionService.resetToFree();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Reset to free account (for testing)')),
            );
          },
          child: Text('Reset to Free (Testing)',
              style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12
              )),
        ),
      ],
    );
  }
}