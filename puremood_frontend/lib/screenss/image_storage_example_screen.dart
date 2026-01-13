import 'package:puremood_frontend/utils/io_utils.dart';
import 'package:puremood_frontend/utils/image_provider_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_storage_service.dart';

/// شاشة توضيحية لاستخدام خدمة حفظ الصور
class ImageStorageExampleScreen extends StatefulWidget {
  const ImageStorageExampleScreen({Key? key}) : super(key: key);

  @override
  _ImageStorageExampleScreenState createState() => _ImageStorageExampleScreenState();
}

class _ImageStorageExampleScreenState extends State<ImageStorageExampleScreen> {
  final ImageStorageService _imageService = ImageStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  List<File> _savedImages = [];
  bool _isLoading = false;
  String _storageInfo = '';

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    setState(() => _isLoading = true);
    
    final images = await _imageService.getAllSavedImages();
    final totalSize = await _imageService.getTotalImagesSize();
    
    setState(() {
      _savedImages = images;
      _storageInfo = '${images.length} images • ${_imageService.formatBytes(totalSize)}';
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Image Storage Examples',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF008080),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedImageSection(),
            SizedBox(height: 20),
            _buildActionsSection(),
            SizedBox(height: 20),
            _buildSavedImagesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImageSection() {
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
            'Selected Image',
            style: GoogleFonts.poppins(
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
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text('Change Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Tap to select an image',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
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
            'Save Options',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          // 1. حفظ في Gallery
          _buildActionButton(
            'Save to Gallery',
            Icons.photo_library,
            Colors.blue,
            () async {
              if (_selectedImage == null) {
                _showError('Please select an image first');
                return;
              }
              
              setState(() => _isLoading = true);
              final success = await _imageService.saveFileToGallery(_selectedImage!);
              setState(() => _isLoading = false);
              
              _imageService.showSaveResult(context, success);
            },
          ),
          
          SizedBox(height: 8),
          
          // 2. حفظ في مجلد التطبيق
          _buildActionButton(
            'Save to App Directory',
            Icons.folder,
            Colors.green,
            () async {
              if (_selectedImage == null) {
                _showError('Please select an image first');
                return;
              }
              
              setState(() => _isLoading = true);
              final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final path = await _imageService.saveImageToAppDirectory(
                _selectedImage!,
                fileName,
              );
              setState(() => _isLoading = false);
              
              if (path != null) {
                _imageService.showSaveResult(context, true, 
                  customMessage: 'Saved to: $path');
                _loadSavedImages();
              } else {
                _imageService.showSaveResult(context, false);
              }
            },
          ),
          
          SizedBox(height: 8),
          
          // 3. حفظ من URL
          _buildActionButton(
            'Download from URL',
            Icons.cloud_download,
            Colors.purple,
            () async {
              final url = await _showUrlDialog();
              if (url == null || url.isEmpty) return;
              
              setState(() => _isLoading = true);
              final fileName = 'downloaded_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final path = await _imageService.downloadImageToAppDirectory(
                url,
                fileName,
                onProgress: (progress) {
                  print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
                },
              );
              setState(() => _isLoading = false);
              
              if (path != null) {
                _imageService.showSaveResult(context, true,
                  customMessage: 'Downloaded successfully!');
                _loadSavedImages();
              } else {
                _imageService.showSaveResult(context, false);
              }
            },
          ),
          
          SizedBox(height: 8),
          
          // 4. حفظ في Cache
          _buildActionButton(
            'Save to Cache (Temporary)',
            Icons.cached,
            Colors.orange,
            () async {
              if (_selectedImage == null) {
                _showError('Please select an image first');
                return;
              }
              
              setState(() => _isLoading = true);
              final fileName = 'cache_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final path = await _imageService.saveImageToCache(_selectedImage!, fileName);
              setState(() => _isLoading = false);
              
              if (path != null) {
                _imageService.showSaveResult(context, true,
                  customMessage: 'Saved to cache: $path');
              } else {
                _imageService.showSaveResult(context, false);
              }
            },
          ),
          
          if (_isLoading) ...[
            SizedBox(height: 16),
            Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedImagesSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Images',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _storageInfo,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: Color(0xFF008080)),
                    onPressed: _loadSavedImages,
                  ),
                  if (_savedImages.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_sweep, color: Colors.red),
                      onPressed: () async {
                        final confirm = await _showDeleteAllDialog();
                        if (confirm == true) {
                          await _imageService.clearAllImages();
                          _loadSavedImages();
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_savedImages.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No saved images',
                  style: GoogleFonts.poppins(color: Colors.grey),
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
              itemCount: _savedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: buildLocalImageProvider(_savedImages[index].path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () async {
                          await _imageService.deleteImage(_savedImages[index].path);
                          _loadSavedImages();
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<String?> _showUrlDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Image URL'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
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
  }

  Future<bool?> _showDeleteAllDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Images?'),
        content: Text('This will permanently delete all saved images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
