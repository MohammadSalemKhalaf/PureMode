import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/specialist.dart';
import '../services/specialist_service.dart';
import '../services/assessment_service.dart';
import '../models/assessment_models.dart';
import '../config/api_config.dart';
import 'specialist_profile_screen.dart';

class SpecialistsListScreen extends StatefulWidget {
  const SpecialistsListScreen({Key? key}) : super(key: key);

  @override
  State<SpecialistsListScreen> createState() => _SpecialistsListScreenState();
}

class _SpecialistsListScreenState extends State<SpecialistsListScreen> {
  final SpecialistService _service = SpecialistService();
  final AssessmentService _assessmentService = AssessmentService();
  List<Specialist> specialists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkReferralAndLoad();
  }

  Future<void> _checkReferralAndLoad() async {
    setState(() {
      loading = true;
    });

    try {
      final ProfessionalReferral referral =
          await _assessmentService.checkProfessionalReferral();

      if (!mounted) return;

      if (!referral.isNeeded) {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.psychology_alt,
                      color: Colors.teal, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Assessment Required',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Text(
                referral.message.isNotEmpty
                    ? referral.message
                    : 'You currently do not need a professional referral. Please complete your mood assessments first, and if your results indicate that you need extra support, you will be able to see specialists here.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      await _loadSpecialists();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check referral: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSpecialists() async {
    try {
      final result = await _service.getAllSpecialists();
      setState(() {
        specialists = result;
        loading = false;
      });
    } catch (e) {
      print('Error loading specialists: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      appBar: AppBar(
        title: Text(
          'Mental Health Specialists',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00ACC1), Color(0xFF00897B)],
            ),
          ),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : specialists.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSpecialists,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: specialists.length,
                    itemBuilder: (context, index) {
                      return _buildSpecialistCard(specialists[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No specialists available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for available specialists',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(Specialist specialist) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpecialistProfileScreen(specialist: specialist),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: specialist.profileImage != null
                        ? NetworkImage(
                            specialist.profileImage!.startsWith('http')
                                ? specialist.profileImage!
                                : '${ApiConfig.baseUrl.replaceFirst('/api', '')}${specialist.profileImage!}',
                          )
                        : null,
                    child: specialist.profileImage == null
                        ? Icon(Icons.person, size: 32)
                        : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          specialist.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF004D40),
                          ),
                        ),
                        SizedBox(height: 4),
                        // Specialization
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            specialist.specialization,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          specialist.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Bio
              if (specialist.bio != null)
                Text(
                  specialist.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              SizedBox(height: 12),
              // Info row
              Row(
                children: [
                  Icon(Icons.work_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${specialist.yearsOfExperience} years exp',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.language, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    specialist.languages.join(', '),
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  Spacer(),
                  Text(
                    '${specialist.sessionPrice.toStringAsFixed(0)} JOD',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00ACC1),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpecialistProfileScreen(specialist: specialist),
                      ),
                    );
                  },
                  icon: Icon(Icons.person_outline, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00ACC1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: Text(
                    'View Profile',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
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
}
