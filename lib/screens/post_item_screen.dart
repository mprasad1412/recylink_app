import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color _surfaceColor = const Color(0xFFF5F9F6);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserContactInfo();
  }

  Future<void> _loadUserContactInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Fetch the user document from the 'users' collection
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data();
          // Check if 'phone_number' exists and is not empty
          if (data != null && data.containsKey('phone_number')) {
            final String? savedPhone = data['phone_number'];
            if (savedPhone != null && savedPhone.isNotEmpty) {
              setState(() {
                // Pre-fill the contact controller
                _contactController.text = savedPhone;
              });
              debugPrint('Auto-filled phone number: $savedPhone');
            }
          }
        }
      }
    } catch (e) {
      // If it fails, we just don't pre-fill it. No need to show an error to the user.
      debugPrint('Error auto-filling contact info: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final compressedImage = await _compressImage(File(image.path));
        setState(() {
          _selectedImage = compressedImage;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User is null during upload');
        return null;
      }

      final itemId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Updated path to match Storage rules
      final ref = _storage
          .ref()
          .child('marketplace_items')
          .child(user.uid)
          .child(itemId)
          .child(fileName);

      debugPrint('Starting upload to: marketplace_items/${user.uid}/$itemId/$fileName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = ref.putFile(image, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      final snapshot = await uploadTask.whenComplete(() => null);

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('Upload successful. URL: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint('Upload failed with state: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      return null;
    }
  }

  Future<void> _submitItem() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a product name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter product information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter contact information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('Current user: ${user.uid}');
      debugPrint('Starting image upload...');

      final imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) {
        throw Exception('Failed to upload image. Please check your internet connection and Firebase Storage permissions.');
      }

      debugPrint('Image uploaded successfully: $imageUrl');

      double price = 0;
      if (_priceController.text.trim().isNotEmpty) {
        price = double.tryParse(_priceController.text.trim()) ?? 0;
      }

      debugPrint('Creating Firestore document...');

      await _firestore.collection('items').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'images': imageUrl,
        'price': price,
        'user_id': user.uid,
        'contact_info': _contactController.text.trim(),
        'approval_status': 'pending',
        'approved_by': '',
        'post_date': FieldValue.serverTimestamp(),
      });

      debugPrint('Item submitted successfully!');

      // ✅ Navigate back with success result
      if (mounted) {
        Navigator.pop(context, true); // Pass true to indicate success
      }
    } catch (e) {
      debugPrint('Error submitting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit item: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          ),
          onPressed: _isUploading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'List Item',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO IMAGE UPLOADER
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_selectedImage!, fit: BoxFit.cover),
                      // Remove Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_a_photo_rounded, size: 40, color: primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to upload photo',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max size: 5MB',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. CLEAN FORM FIELDS
            _buildModernField(
              label: 'Product Name',
              controller: _titleController,
              hint: 'e.g. Recycled Glass Vase',
              enabled: !_isUploading,
            ),

            const SizedBox(height: 20),

            _buildModernField(
              label: 'Price (RM)',
              controller: _priceController,
              hint: '0.00 (Leave empty for Free)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isUploading,
            ),

            const SizedBox(height: 20),

            _buildModernField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'Describe the condition, material, and story of your item...',
              maxLines: 4,
              enabled: !_isUploading,
            ),

            const SizedBox(height: 20),

            _buildModernField(
              label: 'Contact Info',
              controller: _contactController,
              hint: 'WhatsApp number or preferred contact method',
              keyboardType: TextInputType.phone,
              enabled: !_isUploading,
            ),

            const SizedBox(height: 40),

            // 3. BIG SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 5,
                  shadowColor: primaryGreen.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isUploading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Post Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}