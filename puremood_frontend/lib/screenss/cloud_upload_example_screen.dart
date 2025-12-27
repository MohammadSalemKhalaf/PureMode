import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/image_source_service.dart';
import '../services/cloud_upload_service.dart';

/// مثال كامل: جلب الصورة ورفعها على Cloud
class CloudUploadExampleScreen extends StatefulWidget {
  const CloudUploadExampleScreen({Key? key}) : super(key: key);

  @override
  _CloudUploadExampleScreenState createState() => _CloudUploadExampleScreenState();
}

class _CloudUploadExampleScreenState extends State<CloudUploadExampleScreen> {
  final ImageSourceService _sourceService = ImageSourceService();
  final CloudUploadService _uploadService = CloudUploadService();
  
  File? _selectedImage;
  String? _uploadedUrl;
  bool _isUploading = false;
  double _uploadProgress = 0;
  
  // معلومات Cloudinary (غيّرها بمعلوماتك)
  final String cloudName = 'YOUR_CLOUD_NAME'; // من cloudinary.com
  final String uploadPreset = 'YOUR_UPLOAD_PRESET'; // من Settings > Upload
  
  // أو معلومات imgbb
  final String imgbbApiKey = 'YOUR_IMGBB_KEY'; // من api.imgbb.com

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'رفع الصور على Cloud',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF008080),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: 20),
            _buildImageSection(),
            SizedBox(height: 20),
            _buildUploadOptionsSection(),
            if (_uploadedUrl != null) ...[
              SizedBox(height: 20),
              _buildResultSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'كيف يشتغل؟',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoStep('1', 'اختر صورة من جهازك أو التقطها'),
          SizedBox(height: 8),
          _buildInfoStep('2', 'اختر خدمة التخزين (Cloudinary أو imgbb)'),
          SizedBox(height: 8),
          _buildInfoStep('3', 'ارفع الصورة واحصل على الرابط'),
          SizedBox(height: 8),
          _buildInfoStep('4', 'احفظ الرابط في قاعدة البيانات'),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
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
          Text(
            'الخطوة 1: اختر الصورة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          if (_selectedImage != null)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.change_circle),
                  label: Text('تغيير الصورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.add_photo_alternate, size: 28),
              label: Text(
                'اختر صورة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008080),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadOptionsSection() {
    if (_selectedImage == null) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            'اختر صورة أولاً لعرض خيارات الرفع',
            style: GoogleFonts.cairo(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
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
          Text(
            'الخطوة 2: ارفع على Cloud',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // خيار 1: Cloudinary
          _buildUploadOption(
            title: 'Cloudinary (موصى به ⭐)',
            subtitle: 'مجاني حتى 25GB • سريع • احترافي',
            icon: Icons.cloud_upload,
            color: Colors.blue,
            onTap: _uploadToCloudinary,
          ),
          
          SizedBox(height: 12),
          
          // خيار 2: imgbb
          _buildUploadOption(
            title: 'imgbb (للاختبار)',
            subtitle: 'مجاني • سهل • سريع',
            icon: Icons.image,
            color: Colors.orange,
            onTap: _uploadToImgbb,
          ),
          
          SizedBox(height: 12),
          
          // خيار 3: السيرفر المحلي
          _buildUploadOption(
            title: 'السيرفر المحلي',
            subtitle: 'على السيرفر الخاص بك',
            icon: Icons.dns,
            color: Colors.green,
            onTap: _uploadToLocalServer,
          ),
          
          if (_isUploading) ...[
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              backgroundColor: Colors.grey[200],
              color: Color(0xFF008080),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'جاري الرفع...',
                style: GoogleFonts.cairo(color: Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'تم الرفع بنجاح! ✅',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'رابط الصورة:',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          SelectableText(
            _uploadedUrl!,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // نسخ الرابط
              // Clipboard.setData(ClipboardData(text: _uploadedUrl!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم نسخ الرابط')),
              );
            },
            icon: Icon(Icons.copy),
            label: Text('نسخ الرابط'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _sourceService.showImageSourceDialog(context);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _uploadedUrl = null; // إعادة تعيين
      });
    }
  }

  Future<void> _uploadToCloudinary() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final result = await _uploadService.uploadToCloudinary(
        _selectedImage!,
        cloudName: cloudName,
        uploadPreset: uploadPreset,
        folder: 'puremood/test',
      );

      if (result != null && result['url'] != null) {
        setState(() {
          _uploadedUrl = result['url'];
          _isUploading = false;
        });
        
        _showSuccess('تم رفع الصورة على Cloudinary!');
      } else {
        throw Exception('فشل الرفع');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('خطأ: تأكد من معلومات Cloudinary\n$e');
    }
  }

  Future<void> _uploadToImgbb() async {
    setState(() => _isUploading = true);

    try {
      final url = await _uploadService.uploadToImgbb(
        _selectedImage!,
        apiKey: imgbbApiKey,
      );

      setState(() => _isUploading = false);

      if (url != null) {
        setState(() => _uploadedUrl = url);
        _showSuccess('تم رفع الصورة على imgbb!');
      } else {
        throw Exception('فشل الرفع');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('خطأ: تأكد من API Key\n$e');
    }
  }

  Future<void> _uploadToLocalServer() async {
    setState(() => _isUploading = true);

    try {
      final url = await _uploadService.uploadToLocalServer(_selectedImage!);

      setState(() => _isUploading = false);

      if (url != null) {
        setState(() => _uploadedUrl = url);
        _showSuccess('تم رفع الصورة على السيرفر!');
      } else {
        throw Exception('فشل الرفع');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('خطأ: تأكد من رابط السيرفر\n$e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}
