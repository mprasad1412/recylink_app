// lib/screens/feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recylink/services/notification_service.dart';
import 'dart:io';

class FeedbackScreen extends StatefulWidget {
  final String? imagePath;
  final String predictedType;
  final double confidenceScore;
  final String? detectionId;

  const FeedbackScreen({
    super.key,
    this.imagePath,
    required this.predictedType,
    required this.confidenceScore,
    this.detectionId,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _notificationService = NotificationService();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color surfaceColor = Color(0xFFF5F9F6);

  String? _selectedCorrectClass;
  bool _isSubmitting = false;

  final List<String> _wasteClasses = [
    'E-waste',
    'Glass',
    'Metal',
    'Organic',
    'Paper',
    'Plastic',
    'Textiles',
  ];

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCorrectClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the correct waste type'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload image to Firebase Storage
      String? imageUrl;
      if (widget.imagePath != null && File(widget.imagePath!).existsSync()) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('feedback_images')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(File(widget.imagePath!));
        imageUrl = await storageRef.getDownloadURL();
      }

      // Calculate priority with improved logic
      final priority = _calculatePriority();

      // Create feedback document
      final feedbackDoc = await FirebaseFirestore.instance.collection('feedback').add({
        'user_id': user.uid,
        'user_email': user.email,
        'detection_id': widget.detectionId,
        'predicted_class': widget.predictedType,
        'correct_class': _selectedCorrectClass,
        'confidence_score': widget.confidenceScore,
        'user_comments': _commentsController.text.trim(),
        'image_url': imageUrl,
        'status': 'pending',
        'priority': priority,
        'submitted_at': FieldValue.serverTimestamp(),
        'reviewed_at': null,
        'admin_notes': null,
        'admin_id': null,
      });

      // ✅ CREATE NOTIFICATION FOR USER
      await _notificationService.createNotification(
        userId: user.uid,
        type: 'feedback_submitted',
        title: 'Feedback Received! 📝',
        message: 'Thank you for reporting the incorrect result. Our team will review it soon.',
        relatedId: feedbackDoc.id,
        additionalData: {
          'predicted_class': widget.predictedType,
          'correct_class': _selectedCorrectClass,
          'priority': priority,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feedback submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // ✅ Navigate back to detection result screen (Option B)
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error submitting feedback: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _calculatePriority() {
    // ✅ Improved priority logic:
    // High confidence but wrong = HIGH priority (model is confidently wrong - serious issue)
    // Medium confidence but wrong = MEDIUM priority (model is unsure)
    // Low confidence but wrong = LOW priority (model already knows it's unsure)

    if (widget.confidenceScore >= 0.75) {
      return 'high'; // Very confident but wrong - needs attention
    } else if (widget.confidenceScore >= 0.55) {
      return 'medium'; // Moderately confident but wrong
    } else {
      return 'low'; // Low confidence - expected to be wrong sometimes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor, // Mint background
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(
                Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Issue',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CONTEXT CARD (Image + Prediction)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Small Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.imagePath != null &&
                          File(widget.imagePath!).existsSync()
                          ? Image.file(
                        File(widget.imagePath!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Prediction Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Predicted:',
                            style: TextStyle(fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.predictedType,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors
                                  .redAccent, // Red to indicate it's "Wrong"
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Confidence: ${(widget.confidenceScore * 100)
                                  .toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. CORRECTION FORM TITLE
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Correction Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // 3. DROPDOWN (Correct Class)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                decoration: _inputBoxDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text(
                      'Select the correct type',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    value: _selectedCorrectClass,
                    icon: const Icon(
                        Icons.keyboard_arrow_down_rounded, color: primaryGreen),
                    items: _wasteClasses.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCorrectClass = newValue;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. COMMENTS FIELD
              Container(
                decoration: _inputBoxDecoration(),
                child: TextFormField(
                  controller: _commentsController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Tell us more (e.g. "This is actually a crumpled can, not paper...")',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) {
                      return 'Please provide details';
                    }
                    if (value
                        .trim()
                        .length < 10) {
                      return 'Please provide at least 10 characters';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 30),

              // 5. BLUE INFO BOX (Subtle)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your feedback helps retrain the AI model for everyone. Thank you!',
                        style: TextStyle(
                            color: Colors.blue[800], fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 6. ACTION BUTTONS
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 5,
                    shadowColor: primaryGreen.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    'Submit Feedback',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: _isSubmitting ? null : () =>
                      Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}