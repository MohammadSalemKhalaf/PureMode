import 'package:puremood_frontend/utils/io_utils.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:puremood_frontend/utils/image_provider_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/recommendation_service.dart';
import '../models/mood_models.dart';

class WarmDrinksScreen extends StatefulWidget {
  final List<dynamic>? drinksList;
  final Recommendation? recommendation;

  const WarmDrinksScreen({
    Key? key,
    this.drinksList,
    this.recommendation,
  }) : super(key: key);

  @override
  _WarmDrinksScreenState createState() => _WarmDrinksScreenState();
}

class _WarmDrinksScreenState extends State<WarmDrinksScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> allDrinks = [];
  bool isLoading = true;
  String? selectedDrink;
  File? capturedImage;
  bool isUploadingProof = false;

  @override
  void initState() {
    super.initState();
    loadDrinks();
  }

  Future<void> loadDrinks() async {
    try {
      if (widget.drinksList != null && widget.drinksList!.isNotEmpty) {
        setState(() {
          allDrinks = widget.drinksList!.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        final drinks = await _recommendationService.getWarmDrinks();
        setState(() {
          allDrinks = drinks;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading drinks: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load drinks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          capturedImage = File(photo.path);
        });

        // Show confirmation dialog
        _showConfirmationDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          capturedImage = File(photo.path);
        });

        // Show confirmation dialog
        _showConfirmationDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Great photo! 📸',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9800),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (capturedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: buildLocalImageProvider(capturedImage!.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16),
            Text(
              'Do you want to save this photo as proof?',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                capturedImage = null;
              });
              Navigator.pop(context);
            },
            child: Text('Cancel', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await uploadProof();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF9800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Save ✓', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Future<void> uploadProof() async {
    if (capturedImage == null || widget.recommendation == null) return;

    setState(() {
      isUploadingProof = true;
    });

    try {
      // In real app, you would upload to a server and get URL
      // For now, we'll use local path
      final imagePath = capturedImage!.path;

      await _recommendationService.uploadProofImage(
        widget.recommendation!.recommendationId,
        imagePath,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image saved successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        isUploadingProof = false;
      });

      // Navigate back after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context, true);
      });
    } catch (e) {
      setState(() {
        isUploadingProof = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: Color(0xFFFF9800),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Warm Drinks ☕',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
              ),
            )
          : allDrinks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('☕', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 16),
                      Text(
                        'No drinks available',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header card
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFB74D).withOpacity(0.3),
                            Color(0xFFFF9800).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFFF9800).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF9800).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('☕', style: TextStyle(fontSize: 32)),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choose your favorite drink',
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF9800),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Then take a photo after you drink it!',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (capturedImage != null) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Photo captured successfully! ✓',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Drinks list
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allDrinks.length,
                        itemBuilder: (context, index) {
                          final drink = allDrinks[index];
                          final isSelected = selectedDrink == drink['name'];
                          return _buildDrinkCard(drink, isSelected);
                        },
                      ),
                    ),

                    // Camera buttons
                    if (selectedDrink != null)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isUploadingProof ? null : takePicture,
                                icon: Icon(Icons.camera_alt),
                                label: Text(
                                  'Take a photo',
                                  style: GoogleFonts.cairo(fontSize: 15),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF9800),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    isUploadingProof ? null : pickFromGallery,
                                icon: Icon(Icons.photo_library),
                                label: Text(
                                  'From gallery',
                                  style: GoogleFonts.cairo(fontSize: 15),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Color(0xFFFF9800),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Color(0xFFFF9800)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildDrinkCard(Map<String, dynamic> drink, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [Color(0xFFFF9800), Color(0xFFF57C00)]
              : [Color(0xFFFFB74D), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedDrink = drink['name'];
            });
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      drink['icon'] ?? '☕',
                      style: TextStyle(fontSize: 26),
                    ),
                  ),
                ),

                SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drink['name'] ?? 'Drink',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        drink['benefits'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
