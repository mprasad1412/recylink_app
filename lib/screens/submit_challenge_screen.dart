import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:recylink/services/notification_service.dart';

class SubmitChallengeScreen extends StatefulWidget {
  final String challengeId;
  final String userChallengeId;
  final String challengeTitle;

  const SubmitChallengeScreen({
    super.key,
    required this.challengeId,
    required this.userChallengeId,
    required this.challengeTitle,
  });

  @override
  State<SubmitChallengeScreen> createState() => _SubmitChallengeScreenState();
}

class _SubmitChallengeScreenState extends State<SubmitChallengeScreen> {
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    // Automatically open camera when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePicture();
    });
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      } else {
        // User cancelled camera, go back
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<File?> _compressImage(File imageFile) async {
    try {
      final String targetPath = '${imageFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70,  // 70% quality (good balance)
        minWidth: 1024, // Max width 1024px
        minHeight: 768,  // Max height 768px
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        throw Exception('Image compression failed');
      }

      // Get file size for logging
      final originalSize = await imageFile.length();
      final compressedSize = await File(compressedFile.path).length();
      print('Original: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      print('Compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      print('Saved: ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}%');

      return File(compressedFile.path);
    } catch (e) {
      print('Compression error: $e');
      return null;
    }
  }

  Future<void> _uploadAndSubmit() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // 1. Compress the image first
      final File? compressedImage = await _compressImage(_imageFile!);
      if (compressedImage == null) {
        throw Exception('Failed to compress image');
      }

      // 2. Upload compressed photo to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('challenges/${widget.challengeId}/$userId/$timestamp.jpg');

      final uploadTask = storageRef.putFile(compressedImage);
      final snapshot = await uploadTask;
      final photoUrl = await snapshot.ref.getDownloadURL();

      // 3. Clean up temporary compressed file
      await compressedImage.delete();

      // 4. Add submission to Firestore
      final submissionId = 'sub_$timestamp';

      final userChallengeRef = FirebaseFirestore.instance
          .collection('userChallenges')
          .doc(widget.userChallengeId);

      final doc = await userChallengeRef.get();
      final data = doc.data() as Map<String, dynamic>;

      final currentProgress = (data['current_progress'] ?? 0) + 1;
      final targetCount = data['target_count'] ?? 1;
      final submissions = List<Map<String, dynamic>>.from(data['submissions'] ?? []);

      // Add new submission (use Timestamp.now() instead of serverTimestamp in arrays)
      submissions.add({
        'submission_id': submissionId,
        'photo_url': photoUrl,
        'submitted_at': Timestamp.now(),
        'status': 'pending',
      });

      // Determine new status
      String newStatus;
      if (currentProgress >= targetCount) {
        newStatus = 'pending_review'; // All submissions done
      } else {
        newStatus = 'in_progress';
      }

      // Update Firestore
      await userChallengeRef.update({
        'current_progress': currentProgress,
        'submissions': submissions,
        'status': newStatus,
      });

      //  SEND "ALMOST THERE" NOTIFICATION
      // Check if user is one item away from completing the challenge
      if (currentProgress == targetCount - 1) {
        try {
          await NotificationService().createNotification(
            userId: userId,
            type: 'challenge_progress',
            title: 'Almost There! 🎯',
            message: 'Only 1 more item needed to complete this challenge!',
            relatedId: widget.userChallengeId,
            additionalData: {
              'challenge_title': widget.challengeTitle,
              'items_remaining': 1,
            },
          );
        } catch (e) {
          print('Error sending progress notification: $e');
          // Fail silently - notification is not critical
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentProgress >= targetCount
                  ? 'All items submitted! Waiting for admin review.'
                  : 'Item submitted successfully! ($currentProgress/$targetCount)',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.challengeTitle,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _imageFile == null
          ? const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      )
          : Column(
        children: [
          Expanded(
            child: Center(
              child: Image.file(
                _imageFile!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Is this photo clear?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Make sure the recyclable item is visible',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _takePicture,
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text(
                            'Retake',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadAndSubmit,
                          icon: _isUploading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.check, color: Colors.white),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Submit',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}