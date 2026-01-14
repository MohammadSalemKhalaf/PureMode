import 'package:puremood_frontend/utils/io_utils.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:puremood_frontend/utils/image_provider_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/image_source_service.dart';
import '../services/cloud_upload_service.dart';

/// شاشة اختبار سريع - جرب رفع صورة على Cloudinary
class TestImageUploadScreen extends StatefulWidget {
  const TestImageUploadScreen({Key? key}) : super(key: key);

  @override
  _TestImageUploadScreenState createState() => _TestImageUploadScreenState();
}

class _TestImageUploadScreenState extends State<TestImageUploadScreen> {
  final ImageSourceService _sourceService = ImageSourceService();
  final CloudUploadService _uploadService = CloudUploadService();
  
  File? _selectedImage;
  String? _uploadedUrl;
  bool _isUploading = false;
  
  // ⚠️ ⚠️ ⚠️ غيّر هذي بمعلوماتك من Cloudinary ⚠️ ⚠️ ⚠️
  final String cloudName = 'YOUR_CLOUD_NAME';       // 👈 👈 👈 غيّره
  final String uploadPreset = 'YOUR_UPLOAD_PRESET'; // 👈 👈 👈 غيّره

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'اختبار رفع الصور',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF008080),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // عنوان
              Text(
                'جرب رفع صورة على Cloudinary',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 32),
              
              // عرض الصورة
              if (_selectedImage != null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image(
                        image: buildLocalImageProvider(_selectedImage!.path),
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                )
              else
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد صورة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 24),
              
              // زر اختيار صورة
              if (_selectedImage == null)
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_library, size: 28),
                  label: Text(
                    'اختر صورة من المعرض',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008080),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    minimumSize: Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              
              // أزرار بعد اختيار الصورة
              if (_selectedImage != null && !_isUploading) ...[
                ElevatedButton.icon(
                  onPressed: _uploadToCloudinary,
                  icon: Icon(Icons.cloud_upload, size: 28),
                  label: Text(
                    'ارفع على Cloudinary',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    minimumSize: Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                SizedBox(height: 12),
                
                TextButton(
                  onPressed: _pickImage,
                  child: Text(
                    'اختر صورة أخرى',
                    style: GoogleFonts.cairo(fontSize: 16),
                  ),
                ),
              ],
              
              // مؤشر التحميل
              if (_isUploading) ...[
                SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
                ),
                SizedBox(height: 16),
                Text(
                  'جاري الرفع...\nانتظر قليلاً',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              // نتيجة الرفع
              if (_uploadedUrl != null) ...[
                SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'نجح! 🎉',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'تم رفع الصورة على Cloudinary',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'الرابط:',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      SelectableText(
                        _uploadedUrl!,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.blue[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _uploadedUrl = null;
                          });
                        },
                        child: Text('جرب مرة ثانية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 32),
              
              // تعليمات
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'قبل ما تجرب:',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildInfoPoint('1. سجل في cloudinary.com'),
                    _buildInfoPoint('2. خذ Cloud Name و Upload Preset'),
                    _buildInfoPoint('3. غيّرهم في السطر 17-18 من هذا الملف'),
                    _buildInfoPoint('4. جرب رفع صورة!'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _sourceService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _uploadedUrl = null;
      });
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_selectedImage == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final result = await _uploadService.uploadToCloudinary(
        _selectedImage!,
        cloudName: cloudName,
        uploadPreset: uploadPreset,
        folder: 'test',
      );
      
      if (result != null && result['url'] != null) {
        setState(() {
          _uploadedUrl = result['url'];
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('تم الرفع بنجاح! ✅')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('فشل الرفع');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'خطأ في الرفع ❌',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('تأكد من Cloud Name و Upload Preset'),
              Text('$e', style: TextStyle(fontSize: 11)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
    }
  }
}
