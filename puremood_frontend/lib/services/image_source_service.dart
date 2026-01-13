import 'package:puremood_frontend/utils/io_utils.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// خدمة للحصول على الصور من مصادر مختلفة
class ImageSourceService {
  final ImagePicker _picker = ImagePicker();

  // ==========================================
  // 1. اختيار صورة من معرض الصور (Gallery)
  // ==========================================
  Future<File?> pickImageFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // ==========================================
  // 2. اختيار عدة صور من المعرض
  // ==========================================
  Future<List<File>> pickMultipleImages({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // ==========================================
  // 3. التقاط صورة بالكاميرا
  // ==========================================
  Future<File?> takePhotoWithCamera({
    int imageQuality = 85,
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCamera,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // ==========================================
  // 4. تحميل صورة من الإنترنت (URL)
  // ==========================================
  Future<File?> downloadImageFromUrl(
    String imageUrl, {
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    try {
      // إنشاء اسم ملف
      final fileName = customFileName ?? 
          'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // تحميل الصورة
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      // حفظ مؤقت في cache
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }

  // ==========================================
  // 5. الحصول على صورة من Assets (يحتاج BuildContext)
  // ==========================================
  Future<File?> getImageFromAssets(
    BuildContext context,
    String assetPath,
  ) async {
    try {
      // قراءة الصورة من Assets
      final byteData = await DefaultAssetBundle.of(context).load(assetPath);
      
      // تحويلها لـ File
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsBytes(byteData.buffer.asUint8List());
      
      return file;
    } catch (e) {
      print('Error loading asset image: $e');
      return null;
    }
  }

  // ==========================================
  // 6. إنشاء صورة من Bytes
  // ==========================================
  Future<File?> createImageFromBytes(
    Uint8List bytes, 
    String fileName,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error creating image from bytes: $e');
      return null;
    }
  }

  // ==========================================
  // 7. الحصول على صورة البروفايل من الكاش
  // ==========================================
  Future<File?> getCachedProfileImage(String userId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/profile_$userId.jpg');
      
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error getting cached image: $e');
      return null;
    }
  }

  // ==========================================
  // 8. عرض Dialog لاختيار المصدر (كاميرا أو معرض)
  // ==========================================
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<File>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // عنوان
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Choose Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            // زر الكاميرا
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: Text('Camera'),
              subtitle: Text('Take a new photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await takePhotoWithCamera();
                if (image != null && context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            
            SizedBox(height: 10),
            
            // زر المعرض
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: Colors.green),
              ),
              title: Text('Gallery'),
              subtitle: Text('Choose from your photos'),
              onTap: () async {
                Navigator.pop(context);
                final image = await pickImageFromGallery();
                if (image != null && context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            
            SizedBox(height: 10),
            
            // زر الإلغاء
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 9. التحقق من صلاحيات الكاميرا والمعرض
  // ==========================================
  Future<bool> checkCameraPermission() async {
    // يتم التحقق تلقائياً بواسطة image_picker
    return true;
  }

  // ==========================================
  // 10. عرض Dialog لإدخال URL
  // ==========================================
  Future<File?> showUrlInputDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    
    final String? url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Image URL'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Download'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      // عرض مؤشر تحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Downloading image...'),
                ],
              ),
            ),
          ),
        ),
      );

      final file = await downloadImageFromUrl(url);
      
      if (context.mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
      }
      
      return file;
    }
    
    return null;
  }

  // ==========================================
  // 11. اختيار متعدد المصادر (معرض، كاميرا، URL)
  // ==========================================
  Future<File?> showAdvancedImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<File>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Text(
                'Add Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              
              // الخيارات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // كاميرا
                  _buildSourceOption(
                    context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await takePhotoWithCamera();
                      if (image != null && context.mounted) {
                        Navigator.pop(context, image);
                      }
                    },
                  ),
                  
                  // معرض
                  _buildSourceOption(
                    context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.green,
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await pickImageFromGallery();
                      if (image != null && context.mounted) {
                        Navigator.pop(context, image);
                      }
                    },
                  ),
                  
                  // URL
                  _buildSourceOption(
                    context,
                    icon: Icons.link,
                    label: 'URL',
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await showUrlInputDialog(context);
                      if (image != null && context.mounted) {
                        Navigator.pop(context, image);
                      }
                    },
                  ),
                ],
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
