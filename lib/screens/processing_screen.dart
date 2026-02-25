// import 'package:flutter/material.dart';
// import 'package:recylink/screens/detection_result_screen.dart';
// import 'package:recylink/services/waste_classifier.dart';
// import 'package:recylink/services/firebase_detection_service.dart';
// import 'package:recylink/services/maintenance_check_helper.dart'; // âœ… ADD THIS IMPORT
//
// class ProcessingScreen extends StatefulWidget {
//   final String? imagePath;
//
//   const ProcessingScreen({super.key, this.imagePath});
//
//   @override
//   State<ProcessingScreen> createState() => _ProcessingScreenState();
// }
//
// class _ProcessingScreenState extends State<ProcessingScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   final WasteClassifier _classifier = WasteClassifier();
//   final FirebaseDetectionService _firebaseService = FirebaseDetectionService();
//
//   String _statusMessage = 'Initializing AI...';
//   bool _hasError = false;
//
//   static const Color primaryGreen = Color(0xFFAEE55B);
//   static const Color darkGreenNav = Color(0xFF4D8000);
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
//
//     _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
//
//     _processImage();
//   }
//
//   Future<void> _processImage() async {
//     // ============================================
//     // âœ… ADD MAINTENANCE CHECK HERE (FIRST THING)
//     // ============================================
//     final isInMaintenance = await MaintenanceCheckHelper.isMaintenanceMode();
//
//     if (isInMaintenance) {
//       if (mounted) {
//         // Show maintenance dialog
//         MaintenanceCheckHelper.showMaintenanceDialog(context);
//         // Go back to camera screen
//         Navigator.pop(context);
//       }
//       return; // Exit early, don't proceed with AI processing
//     }
//     // ============================================
//
//     if (widget.imagePath == null) {
//       _showError('No image provided');
//       return;
//     }
//
//     try {
//       setState(() {
//         _statusMessage = 'Loading AI model...';
//       });
//
//       await _classifier.loadModel();
//
//       setState(() {
//         _statusMessage = 'Analyzing waste type...';
//       });
//
//       final result = await _classifier.classifyImage(widget.imagePath!);
//
//       if (result['confidence_score'] < 0.30) {
//         _showError('Low confidence (${(result['confidence_score'] * 100).toStringAsFixed(1)}%). Please retake with better lighting and clear focus.');
//         return;
//       }
//
//       setState(() {
//         _statusMessage = 'Uploading to cloud...';
//       });
//
//       final imageUrl = await _firebaseService.uploadImage(widget.imagePath!);
//
//       setState(() {
//         _statusMessage = 'Saving detection...';
//       });
//
//       final detectionId = await _firebaseService.saveDetection(
//         wasteType: result['waste_type'],
//         confidenceScore: result['confidence_score'],
//         imageUrl: imageUrl,
//         isRecyclable: result['is_recyclable'],
//         category: result['category'],
//       );
//
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DetectionResultScreen(
//               imagePath: widget.imagePath,
//               detectionResult: result,
//               detectionId: detectionId,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       print('âŒ Error processing image: $e');
//       _showError('Failed to process image. ${e.toString()}');
//     }
//   }
//
//   void _showError(String message) {
//     setState(() {
//       _hasError = true;
//       _statusMessage = message;
//     });
//
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) {
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => AlertDialog(
//             title: const Text('Detection Error'),
//             content: Text(message),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text('Try Again'),
//               ),
//             ],
//           ),
//         );
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEDF8E5),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (!_hasError)
//               AnimatedBuilder(
//                 animation: _animation,
//                 builder: (context, child) {
//                   return Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildDot(primaryGreen, _animation.value * 2),
//                           const SizedBox(width: 20),
//                           _buildDot(primaryGreen, (1 - _animation.value) * 2),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildDot(darkGreenNav, (1 - _animation.value) * 2),
//                           const SizedBox(width: 20),
//                           _buildDot(darkGreenNav, _animation.value * 2),
//                         ],
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             if (_hasError)
//               const Icon(
//                 Icons.error_outline,
//                 size: 80,
//                 color: Colors.red,
//               ),
//             const SizedBox(height: 40),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 32),
//               child: Text(
//                 _statusMessage,
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: _hasError ? Colors.red : Colors.black,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 20),
//             if (!_hasError)
//               const SizedBox(
//                 width: 30,
//                 height: 30,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 3,
//                   valueColor: AlwaysStoppedAnimation<Color>(darkGreenNav),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDot(Color color, double scale) {
//     return Transform.scale(
//       scale: 0.8 + (scale * 0.2).clamp(0.0, 1.0),
//       child: Container(
//         width: 20,
//         height: 20,
//         decoration: BoxDecoration(
//           color: color,
//           shape: BoxShape.circle,
//         ),
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:recylink/screens/detection_result_screen.dart';
import 'package:recylink/services/waste_classifier.dart';
import 'package:recylink/services/firebase_detection_service.dart';
import 'package:recylink/services/maintenance_check_helper.dart';
import 'package:recylink/services/background_removal_service.dart'; // ✅ NEW

class ProcessingScreen extends StatefulWidget {
  final String? imagePath;

  const ProcessingScreen({super.key, this.imagePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final WasteClassifier _classifier = WasteClassifier();
  final FirebaseDetectionService _firebaseService = FirebaseDetectionService();
  final BackgroundRemovalService _bgRemoval = BackgroundRemovalService(); // ✅ NEW

  String _statusMessage = 'Initializing AI...';
  bool _hasError = false;

  static const Color primaryGreen = Color(0xFFAEE55B);
  static const Color darkGreenNav = Color(0xFF4D8000);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _processImage();
  }

  Future<void> _processImage() async {
    // Check maintenance mode first
    final isInMaintenance = await MaintenanceCheckHelper.isMaintenanceMode();

    if (isInMaintenance) {
      if (mounted) {
        MaintenanceCheckHelper.showMaintenanceDialog(context);
        Navigator.pop(context);
      }
      return;
    }

    if (widget.imagePath == null) {
      _showError('No image provided');
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Loading AI model...';
      });

      await _classifier.loadModel();

      // ✅ NEW: Process image to remove background
      // setState(() {
      //   _statusMessage = 'Isolating waste object...';
      // });
      //
      // final processedImagePath = await _bgRemoval.processImage(widget.imagePath!);

      // ✅ CHANGED: Use processed image instead of original
      setState(() {
        _statusMessage = 'Analyzing waste type...';
      });

      final result = await _classifier.classifyImage(widget.imagePath!);

      if (result['confidence_score'] < 0.35) {
        _showError('Low confidence (${(result['confidence_score'] * 100).toStringAsFixed(1)}%). Please retake with better lighting and clear focus.');
        return;
      }

      setState(() {
        _statusMessage = 'Uploading to cloud...';
      });

      // ✅ Upload ORIGINAL image (not processed) for display
      final imageUrl = await _firebaseService.uploadImage(widget.imagePath!);

      setState(() {
        _statusMessage = 'Saving detection...';
      });

      final detectionId = await _firebaseService.saveDetection(
        wasteType: result['waste_type'],
        confidenceScore: result['confidence_score'],
        imageUrl: imageUrl,
        isRecyclable: result['is_recyclable'],
        category: result['category'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetectionResultScreen(
              imagePath: widget.imagePath, // ✅ Show original image
              detectionResult: result,
              detectionId: detectionId,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error processing image: $e');
      _showError('Failed to process image. ${e.toString()}');
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _statusMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Detection Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF8E5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_hasError)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(primaryGreen, _animation.value * 2),
                          const SizedBox(width: 20),
                          _buildDot(primaryGreen, (1 - _animation.value) * 2),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(darkGreenNav, (1 - _animation.value) * 2),
                          const SizedBox(width: 20),
                          _buildDot(darkGreenNav, _animation.value * 2),
                        ],
                      ),
                    ],
                  );
                },
              ),
            if (_hasError)
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _hasError ? Colors.red : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            if (!_hasError)
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(darkGreenNav),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color, double scale) {
    return Transform.scale(
      scale: 0.8 + (scale * 0.2).clamp(0.0, 1.0),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}