import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puremood_frontend/utils/image_provider_utils.dart';
import '../models/specialist.dart';
import '../services/specialist_service.dart';
import '../config/api_config.dart';

class SpecialistOwnProfileScreen extends StatefulWidget {
  final int specialistId;

  const SpecialistOwnProfileScreen({Key? key, required this.specialistId}) : super(key: key);

  @override
  _SpecialistOwnProfileScreenState createState() => _SpecialistOwnProfileScreenState();
}

class _SpecialistOwnProfileScreenState extends State<SpecialistOwnProfileScreen> {
  final dynamic _specialistService = SpecialistService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  Specialist? _specialist;
  XFile? _profileImageFile;
  List<XFile> _portfolioImages = [];
  XFile? _certificateFile;

  // Rating & reviews
  double _currentRating = 0;
  int _totalReviews = 0;
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = false;

  // Form controllers
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _sessionPriceController = TextEditingController();
  final TextEditingController _sessionDurationController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  
  List<String> _selectedLanguages = [];
  final List<String> _availableLanguages = ['Arabic', 'English', 'French', 'German', 'Spanish'];

  @override
  void initState() {
    super.initState();
    _loadSpecialistData();
  }

  Future<void> _pickCertificateFile() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (file != null) {
        setState(() {
          _certificateFile = file;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick certificate file');
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _educationController.dispose();
    _licenseController.dispose();
    _sessionPriceController.dispose();
    _sessionDurationController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialistData() async {
    setState(() => _isLoading = true);
    try {
      final specialist = await _specialistService.getSpecialistById(widget.specialistId);
      if (specialist != null) {
        setState(() {
          _specialist = specialist;
          _bioController.text = specialist.bio ?? '';
          _educationController.text = specialist.education ?? '';
          _licenseController.text = specialist.licenseNumber;
          _sessionPriceController.text = specialist.sessionPrice.toString();
          _sessionDurationController.text = specialist.sessionDuration.toString();
          _specializationController.text = specialist.specialization;
          _selectedLanguages = List.from(specialist.languages);
          _currentRating = specialist.rating;
          _totalReviews = specialist.totalReviews;
        });
        await _loadReviews();
      }
    } catch (e) {
      _showErrorDialog('Failed to load profile data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await _specialistService.getSpecialistReviews(widget.specialistId);
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      print('Error loading specialist reviews: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImageFile = image;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image');
    }
  }

  Future<void> _pickPortfolioImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _portfolioImages.addAll(images);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick images');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedData = {
        'bio': _bioController.text,
        'education': _educationController.text,
        'license_number': _licenseController.text,
        'session_price': double.parse(_sessionPriceController.text),
        'session_duration': int.parse(_sessionDurationController.text),
        'specialization': _specializationController.text,
        'languages': _selectedLanguages,
      };

      await _specialistService.updateSpecialistProfile(
        widget.specialistId,
        updatedData,
        profileImage: _profileImageFile,
        portfolioImages: _portfolioImages,
        certificateFile: _certificateFile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _loadSpecialistData();
      setState(() {
        _profileImageFile = null;
        _portfolioImages.clear();
        _certificateFile = null;
      });
    } catch (e) {
      _showErrorDialog('Failed to update profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationNotice() {
    final isVerified = _specialist?.isVerified ?? false;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.warning_amber_rounded,
            color: isVerified ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              isVerified
                  ? 'Your account is verified by the admin.'
                  : 'Please upload your certificate so the admin can verify your account.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateSection() {
    final hasCertificate =
        _certificateFile != null || (_specialist?.certificateFile != null);
    final existingName = _specialist?.certificateFile != null
        ? 'Certificate on file'
        : 'No certificate uploaded yet';

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
              Icon(Icons.assignment_turned_in, color: Color(0xFF008080)),
              SizedBox(width: 8),
              Text(
                'Verification Document',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            hasCertificate
                ? (_certificateFile != null
                    ? 'Selected file: ${_certificateFile!.name}'
                    : existingName)
                : existingName,
            style:
                GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickCertificateFile,
            icon: Icon(Icons.upload_file),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF008080),
            ),
            label: Text(
              'Upload Certificate',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
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
              Icon(Icons.reviews, color: Color(0xFF008080)),
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
              'You have no reviews yet.',
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

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF008080),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileImageSection(),
                    _buildBasicInfoSection(),
                    _buildVerificationNotice(),
                    _buildProfessionalInfoSection(),
                    _buildCertificateSection(),
                    _buildLanguagesSection(),
                    _buildReviewsSection(),
                    _buildPortfolioSection(),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isSaving
          ? CircularProgressIndicator()
          : FloatingActionButton.extended(
              onPressed: _saveProfile,
              backgroundColor: Color(0xFF008080),
              icon: Icon(Icons.save),
              label: Text(
                'Save Changes',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF008080), Color(0xFF00A79D)],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
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
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImageFile != null
                        ? buildLocalImageProvider(_profileImageFile!.path)
                        : _specialist?.profileImage != null
                            ? NetworkImage(
                                _specialist!.profileImage!.startsWith('http')
                                    ? _specialist!.profileImage!
                                    : '${ApiConfig.baseUrl.replaceFirst('/api', '')}${_specialist!.profileImage!}',
                              )
                            : null,
                    child: (_profileImageFile == null && _specialist?.profileImage == null)
                        ? Icon(
                            Icons.medical_services,
                            size: 60,
                            color: Color(0xFF008080),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Color(0xFF008080),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            _specialist?.name ?? 'Specialist',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _specialist?.email ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              _specialist?.specialization ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF008080)),
              SizedBox(width: 8),
              Text(
                'Basic Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell us about yourself...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF008080)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your bio';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _educationController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Education',
              hintText: 'Your educational background...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.school, color: Color(0xFF008080)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoSection() {
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
              Icon(Icons.work_outline, color: Color(0xFF008080)),
              SizedBox(width: 8),
              Text(
                'Professional Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _specializationController,
            decoration: InputDecoration(
              labelText: 'Specialization',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.medical_services, color: Color(0xFF008080)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your specialization';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _licenseController,
            decoration: InputDecoration(
              labelText: 'License Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.badge, color: Color(0xFF008080)),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sessionPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Session Price (\$)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.attach_money, color: Color(0xFF008080)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _sessionDurationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration (min)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.access_time, color: Color(0xFF008080)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
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
              Icon(Icons.language, color: Color(0xFF008080)),
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
            children: _availableLanguages.map((lang) {
              final isSelected = _selectedLanguages.contains(lang);
              return FilterChip(
                selected: isSelected,
                label: Text(lang),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(lang);
                    } else {
                      _selectedLanguages.remove(lang);
                    }
                  });
                },
                selectedColor: Color(0xFF008080).withOpacity(0.3),
                checkmarkColor: Color(0xFF008080),
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Color(0xFF008080) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library, color: Color(0xFF008080)),
                  SizedBox(width: 8),
                  Text(
                    'Portfolio Images',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _pickPortfolioImages,
                icon: Icon(Icons.add_photo_alternate, color: Color(0xFF008080)),
                tooltip: 'Add Images',
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_portfolioImages.isEmpty)
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No portfolio images yet',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickPortfolioImages,
                      icon: Icon(Icons.add),
                      label: Text('Add Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008080),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _portfolioImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: buildLocalImageProvider(_portfolioImages[index].path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _portfolioImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

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
}
