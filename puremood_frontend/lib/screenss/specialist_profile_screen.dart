import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/specialist.dart';
import '../services/specialist_service.dart';
import '../config/api_config.dart';
// import '../services/rating_service.dart'; // TODO: Enable later
import 'book_appointment_screen.dart';

class SpecialistProfileScreen extends StatefulWidget {
  final Specialist specialist;

  const SpecialistProfileScreen({Key? key, required this.specialist}) : super(key: key);

  @override
  _SpecialistProfileScreenState createState() => _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState extends State<SpecialistProfileScreen> {
  double _currentRating = 0;
  int _currentReviews = 0;
  final SpecialistService _specialistService = SpecialistService();
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.specialist.rating;
    _currentReviews = widget.specialist.totalReviews;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await _specialistService.getSpecialistReviews(widget.specialist.specialistId);
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      // Keep silent in UI, we already show aggregate rating; reviews list is optional
      print('Error loading reviews: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildStatsRow(),
                _buildAboutSection(),
                _buildExperienceSection(),
                _buildReviewsSection(),
                // _buildRatingSection(), // TODO: Enable later
                _buildLanguagesSection(),
                _buildPricingSection(),
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildBookButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Color(0xFF008080),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF008080),
                Color(0xFF00A79D),
                Color(0xFF20B2AA),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Hero(
                tag: 'specialist_${widget.specialist.specialistId}',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.specialist.profileImage != null
                        ? NetworkImage(
                            widget.specialist.profileImage!.startsWith('http')
                                ? widget.specialist.profileImage!
                                : '${ApiConfig.baseUrl.replaceFirst('/api', '')}${widget.specialist.profileImage!}',
                          )
                        : null,
                    child: widget.specialist.profileImage != null
                        ? null
                        : Icon(
                            Icons.medical_services,
                            size: 50,
                            color: Color(0xFF008080),
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

  Widget _buildReviewsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reviews, color: Color(0xFF008080), size: 20),
              SizedBox(width: 8),
              Text(
                'Patient Feedback',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_isLoadingReviews)
            Center(child: CircularProgressIndicator())
          else if (_reviews.isEmpty)
            Text(
              'No reviews yet.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => Divider(height: 16),
              itemBuilder: (context, index) {
                final review = _reviews[index] as Map<String, dynamic>;
                final rating = (review['rating'] ?? 0).toDouble();
                final comment = (review['comment'] ?? '').toString();
                final userName = (review['user_name'] ?? 'Anonymous').toString();
                final createdAt = review['created_at']?.toString();

                String formattedDate = '';
                if (createdAt != null && createdAt.isNotEmpty) {
                  try {
                    final dt = DateTime.parse(createdAt);
                    formattedDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                  } catch (_) {}
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildRatingStars(rating, size: 16),
                      ],
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    if (comment.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(
                        comment,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.specialist.name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF008080),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.specialist.specialization,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF008080),
              ),
            ),
          ),
          SizedBox(height: 8),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRatingStars(_currentRating, size: 20),
              SizedBox(width: 8),
              Text(
                _currentRating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
              Text(
                ' (${_currentReviews} reviews)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.work_outline,
            '${widget.specialist.yearsOfExperience} Years',
            'Experience',
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            Icons.people_outline,
            '${widget.specialist.totalReviews}+',
            'Patients',
            Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            Icons.verified_outlined,
            'Verified',
            'Professional',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF008080), size: 20),
              SizedBox(width: 8),
              Text(
                'About',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.specialist.bio ?? 'Professional mental health specialist dedicated to helping patients achieve better mental wellness.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: Color(0xFF008080), size: 20),
              SizedBox(width: 8),
              Text(
                'Education & Expertise',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoRow(Icons.school, widget.specialist.education ?? 'Licensed Mental Health Professional'),
          SizedBox(height: 8),
          _buildInfoRow(Icons.badge_outlined, widget.specialist.licenseNumber ?? 'Licensed Professional'),
          SizedBox(height: 8),
          _buildInfoRow(Icons.access_time, '${widget.specialist.sessionDuration} min sessions'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  // TODO: Enable rating later
  /*
  Widget _buildRatingSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber[700], size: 24),
              SizedBox(width: 8),
              Text(
                'Rate This Specialist',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_isSubmittingRating)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
              ),
            )
          else
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () async {
                    if (_isSubmittingRating) return;
                    
                    setState(() {
                      _userRating = (index + 1).toDouble();
                    });
                    await _submitRating();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber[700],
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_hasRated) ...[
            SizedBox(height: 12),
            Center(
              child: Text(
                'Thank you for your rating! ⭐',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmittingRating = true);
    
    try {
      final result = await _ratingService.rateSpecialist(
        widget.specialist.specialistId,
        _userRating,
      );
      
      // Update the displayed rating
      setState(() {
        _currentRating = result['new_rating'].toDouble();
        _currentReviews = result['total_reviews'];
        _hasRated = true;
        _isSubmittingRating = false;
      });
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber[700]),
                SizedBox(width: 8),
                Text(
                  'Thank You!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Your ${_userRating.toInt()}-star rating has been recorded!\n\nNew rating: ${_currentRating.toStringAsFixed(1)} ⭐ ($_currentReviews reviews)',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmittingRating = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  */

  Widget _buildRatingStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star_rounded, color: Colors.amber[700], size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half_rounded, color: Colors.amber[700], size: size);
        } else {
          return Icon(Icons.star_outline_rounded, color: Colors.grey[400], size: size);
        }
      }),
    );
  }

  Widget _buildLanguagesSection() {
    final languages = widget.specialist.languages ?? ['English', 'Arabic'];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: Color(0xFF008080), size: 20),
              SizedBox(width: 8),
              Text(
                'Languages',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages.map((lang) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Text(
                  lang,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF008080),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Fee',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '\$${widget.specialist.sessionPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    ' / session',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(
            Icons.attach_money,
            size: 48,
            color: Colors.green[300],
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookAppointmentScreen(specialist: widget.specialist),
            ),
          );
        },
        icon: Icon(Icons.calendar_today, size: 22),
        label: Text(
          'Book Appointment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF008080),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          shadowColor: Color(0xFF008080).withOpacity(0.5),
        ),
      ),
    );
  }
}
