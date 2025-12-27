import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart'; // معطلة
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

/// خدمة شاملة لحفظ وإدارة الصور في Flutter
class ImageStorageService {
  
  /// ============================================
  /// 1. حفظ صورة من URL إلى معرض الصور (Gallery)
  /// ⚠️ معطلة - نستخدم Cloudinary بدلاً منها
  /// ============================================
  Future<bool> saveImageFromUrlToGallery(String imageUrl, {String? albumName}) async {
    throw UnimplementedError('Use CloudUploadService instead');
    /*
    try {
      // طلب الصلاحيات
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // تحميل الصورة من URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // حفظ الصورة في المعرض
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 100,
        name: 'puremood_${DateTime.now().millisecondsSinceEpoch}',
      );

      return result['isSuccess'] ?? false;
    } catch (e) {
      print('Error saving image from URL: $e');
      return false;
    }
  }

  /// ============================================
  /// 2. حفظ ملف صورة إلى معرض الصور
  /// ⚠️ معطلة - نستخدم Cloudinary بدلاً منها
  /// ============================================
  Future<bool> saveFileToGallery(File imageFile) async {
    throw UnimplementedError('Use CloudUploadService instead');
    /*String? albumName}) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // قراءة الصورة كـ bytes
      final bytes = await imageFile.readAsBytes();

      // حفظها في المعرض
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'puremood_${DateTime.now().millisecondsSinceEpoch}',
      );

      return result['isSuccess'] ?? false;
    } catch (e) {
      print('Error saving image to gallery: $e');
      return false;
    }
    */
  }

  /// ============================================
  /// 3. حفظ صورة في مجلد التطبيق (App Directory)
  /// ============================================
  Future<String?> saveImageToAppDirectory(File imageFile, String fileName) async {
    try {
      // الحصول على مسار مجلد التطبيق
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      
      // إنشاء المجلد إذا لم يكن موجوداً
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // مسار الملف الجديد
      final newPath = '${imagesDir.path}/$fileName';
      
      // نسخ الملف
      final savedFile = await imageFile.copy(newPath);
      
      return savedFile.path;
    } catch (e) {
      print('Error saving to app directory: $e');
      return null;
    }
  }

  /// ============================================
  /// 4. حفظ صورة من URL إلى مجلد التطبيق
  /// ============================================
  Future<String?> downloadImageToAppDirectory(
    String imageUrl, 
    String fileName,
    {Function(double)? onProgress}
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final savePath = '${imagesDir.path}/$fileName';

      // استخدام Dio للتحميل مع Progress
      final dio = Dio();
      await dio.download(
        imageUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      return savePath;
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }

  /// ============================================
  /// 5. حفظ صورة في Cache (للاستخدام المؤقت)
  /// ============================================
  Future<String?> saveImageToCache(File imageFile, String fileName) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imagesCache = Directory('${cacheDir.path}/images');
      
      if (!await imagesCache.exists()) {
        await imagesCache.create(recursive: true);
      }

      final newPath = '${imagesCache.path}/$fileName';
      final savedFile = await imageFile.copy(newPath);
      
      return savedFile.path;
    } catch (e) {
      print('Error saving to cache: $e');
      return null;
    }
  }

  /// ============================================
  /// 6. حفظ صورة من Bytes
  /// ============================================
  Future<String?> saveBytesToFile(
    Uint8List bytes, 
    String fileName, 
    {bool inCache = false}
  ) async {
    try {
      final dir = inCache 
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();
      
      final imagesDir = Directory('${dir.path}/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final filePath = '${imagesDir.path}/$fileName';
      final file = File(filePath);
      
      await file.writeAsBytes(bytes);
      
      return filePath;
    } catch (e) {
      print('Error saving bytes to file: $e');
      return null;
    }
  }

  /// ============================================
  /// 7. قراءة صورة محفوظة
  /// ============================================
  Future<File?> getImageFromAppDirectory(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/images/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error reading image: $e');
      return null;
    }
  }

  /// ============================================
  /// 8. حذف صورة
  /// ============================================
  Future<bool> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// ============================================
  /// 9. حذف جميع الصور في مجلد التطبيق
  /// ============================================
  Future<bool> clearAllImages({bool includingCache = false}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }

      if (includingCache) {
        final cacheDir = await getTemporaryDirectory();
        final cacheImagesDir = Directory('${cacheDir.path}/images');
        
        if (await cacheImagesDir.exists()) {
          await cacheImagesDir.delete(recursive: true);
        }
      }

      return true;
    } catch (e) {
      print('Error clearing images: $e');
      return false;
    }
  }

  /// ============================================
  /// 10. الحصول على قائمة جميع الصور المحفوظة
  /// ============================================
  Future<List<File>> getAllSavedImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      
      if (!await imagesDir.exists()) {
        return [];
      }

      final files = await imagesDir.list().toList();
      return files.whereType<File>().toList();
    } catch (e) {
      print('Error getting saved images: $e');
      return [];
    }
  }

  /// ============================================
  /// 11. حساب حجم الصور المحفوظة
  /// ============================================
  Future<int> getTotalImagesSize() async {
    try {
      final files = await getAllSavedImages();
      int totalSize = 0;
      
      for (var file in files) {
        totalSize += await file.length();
      }
      
      return totalSize; // بالبايتات
    } catch (e) {
      print('Error calculating total size: $e');
      return 0;
    }
  }

  /// ============================================
  /// دالة مساعدة: طلب صلاحيات التخزين
  /// ============================================
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ يستخدم صلاحيات مختلفة
      if (await Permission.photos.request().isGranted) {
        return true;
      }
      
      // للإصدارات الأقدم
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      
      return false;
    } else if (Platform.isIOS) {
      // iOS يحتاج صلاحية Photos
      return await Permission.photos.request().isGranted;
    }
    
    return true; // للمنصات الأخرى
  }

  /// ============================================
  /// دالة مساعدة: عرض رسالة نجاح/فشل
  /// ============================================
  void showSaveResult(BuildContext context, bool success, {String? customMessage}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              customMessage ?? 
              (success ? 'Image saved successfully!' : 'Failed to save image'),
            ),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// ============================================
  /// دالة مساعدة: تحويل حجم البايتات لصيغة قابلة للقراءة
  /// ============================================
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
