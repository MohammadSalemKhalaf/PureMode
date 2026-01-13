import 'package:puremood_frontend/utils/io_utils.dart';
import 'package:puremood_frontend/utils/image_provider_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/image_source_service.dart';
import '../services/image_storage_service.dart';

/// مثال شامل: كيف تجيب الصور وتحفظها
class ImageCompleteExampleScreen extends StatefulWidget {
  const ImageCompleteExampleScreen({Key? key}) : super(key: key);

  @override
  _ImageCompleteExampleScreenState createState() => _ImageCompleteExampleScreenState();
}

class _ImageCompleteExampleScreenState extends State<ImageCompleteExampleScreen> {
  final ImageSourceService _sourceService = ImageSourceService();
  final ImageStorageService _storageService = ImageStorageService();
  
  File? _selectedImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'كيف تجيب وتحفظ الصور',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF008080),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            SizedBox(height: 20),
            _buildImagePreviewSection(),
            SizedBox(height: 20),
            _buildGetImageMethodsSection(),
            SizedBox(height: 20),
            if (_selectedImage != null) _buildSaveOptionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF008080), Color(0xFF00A79D)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text(
            'أولاً: اختر من وين تجيب الصورة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'ثانياً: احفظ الصورة في المكان اللي تبيه',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewSection() {
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
            'الصورة المختارة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (_selectedImage != null)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: buildLocalImageProvider(_selectedImage!.path),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'المسار: ${_selectedImage!.path}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'ما فيه صورة محددة',
                      style: GoogleFonts.cairo(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          
          if (_isLoading) ...[
            SizedBox(height: 12),
            Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildGetImageMethodsSection() {
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
            '📸 طرق جلب الصور',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // 1. من المعرض (Gallery)
          _buildMethodCard(
            title: 'من معرض الصور',
            subtitle: 'اختر صورة من صور جهازك',
            icon: Icons.photo_library,
            color: Colors.green,
            onTap: () async {
              setState(() => _isLoading = true);
              final image = await _sourceService.pickImageFromGallery();
              setState(() {
                _selectedImage = image;
                _isLoading = false;
              });
              if (image != null) {
                _showSuccess('تم اختيار الصورة من المعرض');
              }
            },
          ),

          SizedBox(height: 12),

          // 2. من الكاميرا
          _buildMethodCard(
            title: 'التقاط صورة',
            subtitle: 'استخدم الكاميرا لالتقاط صورة جديدة',
            icon: Icons.camera_alt,
            color: Colors.blue,
            onTap: () async {
              setState(() => _isLoading = true);
              final image = await _sourceService.takePhotoWithCamera();
              setState(() {
                _selectedImage = image;
                _isLoading = false;
              });
              if (image != null) {
                _showSuccess('تم التقاط الصورة');
              }
            },
          ),

          SizedBox(height: 12),

          // 3. اختيار عدة صور
          _buildMethodCard(
            title: 'اختيار عدة صور',
            subtitle: 'اختر أكثر من صورة من المعرض',
            icon: Icons.photo,
            color: Colors.orange,
            onTap: () async {
              setState(() => _isLoading = true);
              final images = await _sourceService.pickMultipleImages();
              setState(() => _isLoading = false);
              
              if (images.isNotEmpty) {
                setState(() => _selectedImage = images.first);
                _showSuccess('تم اختيار ${images.length} صورة');
              }
            },
          ),

          SizedBox(height: 12),

          // 4. من رابط (URL)
          _buildMethodCard(
            title: 'تحميل من الإنترنت',
            subtitle: 'أدخل رابط الصورة للتحميل',
            icon: Icons.cloud_download,
            color: Colors.purple,
            onTap: () async {
              final image = await _sourceService.showUrlInputDialog(context);
              if (image != null) {
                setState(() => _selectedImage = image);
                _showSuccess('تم تحميل الصورة من الإنترنت');
              }
            },
          ),

          SizedBox(height: 12),

          // 5. Dialog شامل (كاميرا أو معرض)
          _buildMethodCard(
            title: 'اختيار من Dialog',
            subtitle: 'قائمة خيارات كاملة (معرض، كاميرا، URL)',
            icon: Icons.menu,
            color: Colors.teal,
            onTap: () async {
              final image = await _sourceService.showAdvancedImageSourceDialog(context);
              if (image != null) {
                setState(() => _selectedImage = image);
                _showSuccess('تم اختيار الصورة');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveOptionsSection() {
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
            '💾 طرق حفظ الصورة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // 1. حفظ في Gallery
          _buildSaveButton(
            label: 'حفظ في معرض الصور',
            subtitle: 'يقدر المستخدم يشوفها من تطبيق الصور',
            icon: Icons.photo_library,
            color: Colors.green,
            onPressed: () async {
              setState(() => _isLoading = true);
              final success = await _storageService.saveFileToGallery(_selectedImage!);
              setState(() => _isLoading = false);
              
              if (success) {
                _showSuccess('تم حفظ الصورة في المعرض ✅');
              } else {
                _showError('فشل حفظ الصورة');
              }
            },
          ),

          SizedBox(height: 12),

          // 2. حفظ في مجلد التطبيق
          _buildSaveButton(
            label: 'حفظ في مجلد التطبيق',
            subtitle: 'حفظ دائم داخل التطبيق',
            icon: Icons.folder,
            color: Colors.blue,
            onPressed: () async {
              setState(() => _isLoading = true);
              final fileName = 'saved_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final path = await _storageService.saveImageToAppDirectory(
                _selectedImage!,
                fileName,
              );
              setState(() => _isLoading = false);
              
              if (path != null) {
                _showSuccess('تم الحفظ في:\n$path');
              } else {
                _showError('فشل حفظ الصورة');
              }
            },
          ),

          SizedBox(height: 12),

          // 3. حفظ في Cache
          _buildSaveButton(
            label: 'حفظ مؤقت (Cache)',
            subtitle: 'يتم حذفها تلقائياً بعد فترة',
            icon: Icons.cached,
            color: Colors.orange,
            onPressed: () async {
              setState(() => _isLoading = true);
              final fileName = 'cache_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final path = await _storageService.saveImageToCache(
                _selectedImage!,
                fileName,
              );
              setState(() => _isLoading = false);
              
              if (path != null) {
                _showSuccess('تم الحفظ المؤقت');
              } else {
                _showError('فشل الحفظ');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
                      color: Colors.grey[800],
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

  Widget _buildSaveButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
