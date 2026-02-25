import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Controllers for text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            _usernameController.text = data?['username'] ?? '';
            _emailController.text = data?['email'] ?? user.email ?? '';
            _phoneController.text = data?['phone_number'] ?? '';
            _profileImageUrl = data?['profile_picture'];
            _isLoading = false;
          });
        } else {
          // If no Firestore doc, use Auth data
          setState(() {
            _usernameController.text = user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading profile: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 50, // Higher compression for storage efficiency
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showSnackBar('Image selected. Save to upload.');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Error selecting image: $e');
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Use a fixed path with user's UID to overwrite the old profile picture.
      // This is more secure and storage-friendly.
      final String path = 'profile_pictures/${user.uid}/profile_image.jpg';

      // Upload to Firebase Storage
      final Reference storageRef = _storage.ref().child(path);
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      _showSnackBar('Error uploading image: $e');
      return null;
    }
  }

  String? _validateUsername(String username) {
    if (username.trim().isEmpty) {
      return 'Please enter your username';
    }
    if (username.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.trim().length > 30) {
      return 'Username must not exceed 30 characters';
    }
    // Allow letters, numbers, spaces, underscores
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_ ]+$');
    if (!usernameRegex.hasMatch(username.trim())) {
      return 'Username can only contain letters, numbers, spaces, and underscores';
    }
    return null;
  }

  String? _validatePhone(String phone) {
    if (phone.trim().isEmpty) {
      return null; // Phone is optional
    }
    // Remove spaces and dashes for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    // Malaysian phone: 10-11 digits, can start with 0 or 60
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return 'Phone number must be 10-11 digits';
    }
    // Check if all characters are digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'Phone number can only contain digits';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    // Validate username
    final usernameError = _validateUsername(_usernameController.text);
    if (usernameError != null) {
      _showSnackBar(usernameError);
      return;
    }

    // Validate phone (if provided)
    final phoneError = _validatePhone(_phoneController.text);
    if (phoneError != null) {
      _showSnackBar(phoneError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Upload image if selected
        String? imageUrl = _profileImageUrl;
        if (_selectedImage != null) {
          final uploadedUrl = await _uploadImageToStorage(_selectedImage!);
          if (uploadedUrl != null) {
            imageUrl = uploadedUrl;
          }
        }

        // Update display name in Firebase Auth
        await user.updateDisplayName(_usernameController.text.trim());

        // Prepare data for Firestore (only fields that exist in your database)
        final Map<String, dynamic> userData = {
          'username': _usernameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'profile_picture': imageUrl ?? '',
        };

        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update(userData);

        debugPrint('✅ Profile updated successfully');

        if (mounted) {
          _showSnackBar('Profile updated successfully!');
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error: ${e.code} - ${e.message}');
      _showSnackBar('Error updating profile: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      _showSnackBar('Error updating profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
        ),
      )
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Picture with Camera Icon
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage('lib/assets/profilr.png')
                      as ImageProvider),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isSaving ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isSaving ? Colors.grey : primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildTextField('Username', _usernameController),
                _buildTextField('Email', _emailController,
                    enabled: false), // Email can't be changed
                _buildTextField('Phone Number', _phoneController,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      disabledBackgroundColor:
                      primaryGreen.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : const Text(
                      'Save',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled && !_isSaving,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Colors.black : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}