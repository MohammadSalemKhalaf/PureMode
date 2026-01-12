import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// خدمة رفع الصور على السيرفر/Cloud
class CloudUploadService {
  
  // =====================================
  // خيار 1: رفع على السيرفر المحلي (Node.js/PHP)
  // =====================================
  
  /// رفع صورة على السيرفر المحلي
  Future<String?> uploadToLocalServer(
    File imageFile, {
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    try {
      // رابط السيرفر (غيّره لرابط السيرفر تبعك)
      final url = Uri.parse('http://your-server.com/api/upload');
      
      var request = http.MultipartRequest('POST', url);
      
      // إضافة الصورة
      final fileName = customFileName ?? 
          'image_${DateTime.now().millisecondsSinceEpoch}${_getFileExtension(imageFile.path)}';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // اسم الحقل في السيرفر
          imageFile.path,
          filename: fileName,
        ),
      );
      
      // إرسال الطلب
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url']; // رابط الصورة من السيرفر
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading to local server: $e');
      return null;
    }
  }
  
  // =====================================
  // خيار 2: رفع على Cloudinary (موصى به ⭐)
  // =====================================
  
  /// رفع صورة على Cloudinary
  /// 
  /// للحصول على المعلومات:
  /// 1. سجل في https://cloudinary.com (مجاني)
  /// 2. خذ: cloud_name, api_key, api_secret
  Future<Map<String, dynamic>?> uploadToCloudinary(
    File imageFile, {
    required String cloudName,
    required String uploadPreset, // أو api_key
    String folder = 'puremood',
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload'
      );
      
      var request = http.MultipartRequest('POST', url);
      
      // إضافة المعلومات
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      
      // إضافة الصورة
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );
      
      // إرسال الطلب
      print('Uploading to Cloudinary...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'url': data['secure_url'], // رابط HTTPS
          'public_id': data['public_id'], // معرف الصورة (للحذف لاحقاً)
          'width': data['width'],
          'height': data['height'],
          'format': data['format'],
        };
      } else {
        print('Cloudinary error: ${response.body}');
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
  
  // =====================================
  // خيار 3: رفع على imgbb (مجاني وسهل)
  // =====================================
  
  /// رفع صورة على imgbb
  /// 
  /// للحصول على API Key:
  /// روح https://api.imgbb.com/ واحصل على key مجاني
  Future<String?> uploadToImgbb(
    File imageFile, {
    required String apiKey,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': apiKey,
          'image': base64Image,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['url'];
      } else {
        throw Exception('imgbb upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading to imgbb: $e');
      return null;
    }
  }
  
  // =====================================
  // خيار 4: رفع متعدد (Multiple Upload)
  // =====================================
  
  /// رفع عدة صور على Cloudinary
  Future<List<String>> uploadMultipleToCloudinary(
    List<File> images, {
    required String cloudName,
    required String uploadPreset,
    String folder = 'puremood',
    Function(int current, int total)? onProgress,
  }) async {
    List<String> urls = [];
    
    for (int i = 0; i < images.length; i++) {
      if (onProgress != null) {
        onProgress(i + 1, images.length);
      }
      
      final result = await uploadToCloudinary(
        images[i],
        cloudName: cloudName,
        uploadPreset: uploadPreset,
        folder: folder,
      );
      
      if (result != null && result['url'] != null) {
        urls.add(result['url']);
      }
    }
    
    return urls;
  }
  
  // =====================================
  // دوال مساعدة
  // =====================================
  
  /// الحصول على امتداد الملف
  String _getFileExtension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }
  
  /// ضغط الصورة قبل الرفع (اختياري)
  /// يمكنك استخدام مكتبة flutter_image_compress
  Future<File?> compressImage(File imageFile) async {
    // TODO: إضافة كود الضغط إذا أردت
    return imageFile;
  }
  
  /// حذف صورة من Cloudinary
  Future<bool> deleteFromCloudinary(
    String publicId, {
    required String cloudName,
    required String apiKey,
    required String apiSecret,
  }) async {
    try {
      // TODO: إضافة كود الحذف
      // يحتاج signature معقد، أفضل تعمله من السيرفر
      return true;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }
}

/// ========================================
/// مثال الاستخدام:
/// ========================================
/// 
/// ```dart
/// final uploadService = CloudUploadService();
/// 
/// // 1. رفع على Cloudinary
/// final result = await uploadService.uploadToCloudinary(
///   imageFile,
///   cloudName: 'your_cloud_name',
///   uploadPreset: 'your_upload_preset',
///   folder: 'specialists/profiles',
/// );
/// 
/// if (result != null) {
///   String imageUrl = result['url'];
///   print('Image URL: $imageUrl');
/// }
/// 
/// // 2. رفع على السيرفر المحلي
/// String? url = await uploadService.uploadToLocalServer(imageFile);
/// 
/// // 3. رفع عدة صور
/// List<String> urls = await uploadService.uploadMultipleToCloudinary(
///   [image1, image2, image3],
///   cloudName: 'your_cloud_name',
///   uploadPreset: 'your_upload_preset',
/// );
/// ```
