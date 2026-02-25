import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recylink/screens/processing_screen.dart';
import 'package:recylink/services/maintenance_check_helper.dart';
import 'package:recylink/screens/ai_guide_screen.dart';
// import 'dart:io'; // Not currently used, but harmless

class CameraScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;

  const CameraScreen({super.key, this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  //  THEME COLORS
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _accentGreen = const Color(0xFFAEE55B);

  //static const bool DEBUG_MODE = true;

  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras == null || widget.cameras!.isEmpty) {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorSnackBar('No cameras found.');
        return;
      }
      _cameraController = CameraController(
        cameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
    } else {
      _cameraController = CameraController(
        widget.cameras![_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
    }

    try {
      _initializeControllerFuture = _cameraController!.initialize();
      setState(() {});
    } on CameraException catch (e) {
      _showErrorSnackBar('Error initializing camera: ${e.description}');
      _cameraController?.dispose();
      _cameraController = null;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _takePicture() async {
    final isInMaintenance = await MaintenanceCheckHelper.isMaintenanceMode();
    if (isInMaintenance) {
      if (mounted) MaintenanceCheckHelper.showMaintenanceDialog(context);
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorSnackBar('Error: Camera not initialized.');
      return;
    }

    try {
      await _initializeControllerFuture;
      final XFile imageFile = await _cameraController!.takePicture();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(imagePath: imageFile.path),
        ),
      );
    } on CameraException catch (e) {
      _showErrorSnackBar('Error taking picture: ${e.description}');
    }
  }

  // Future<void> _takePicture() async {
  //   final isInMaintenance = await MaintenanceCheckHelper.isMaintenanceMode();
  //   if (isInMaintenance) {
  //     if (mounted) MaintenanceCheckHelper.showMaintenanceDialog(context);
  //     return;
  //   }
  //
  //   if (_cameraController == null || !_cameraController!.value.isInitialized) {
  //     _showErrorSnackBar('Error: Camera not initialized.');
  //     return;
  //   }
  //
  //   try {
  //     await _initializeControllerFuture;
  //     final XFile imageFile = await _cameraController!.takePicture();
  //     if (!mounted) return;
  //
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => ProcessingScreen(
  //           imagePath: imageFile.path,
  //           debugMode: DEBUG_MODE, // ← Pass debug mode flag
  //         ),
  //       ),
  //     );
  //   } on CameraException catch (e) {
  //     _showErrorSnackBar('Error taking picture: ${e.description}');
  //   }
  // }

  Future<void> _pickImageFromGallery() async {
    final isInMaintenance = await MaintenanceCheckHelper.isMaintenanceMode();
    if (isInMaintenance) {
      if (mounted) MaintenanceCheckHelper.showMaintenanceDialog(context);
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  // Future<void> _pickImageFromGallery() async {
  //   final isInMaintenance = await MaintenanceCheckHelper.isMaintenanceMode();
  //   if (isInMaintenance) {
  //     if (mounted) MaintenanceCheckHelper.showMaintenanceDialog(context);
  //     return;
  //   }
  //
  //   try {
  //     final XFile? image = await _picker.pickImage(
  //       source: ImageSource.gallery,
  //       maxWidth: 1024,
  //       maxHeight: 1024,
  //       imageQuality: 85,
  //     );
  //
  //     if (image != null && mounted) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => ProcessingScreen(
  //             imagePath: image.path,
  //             debugMode: DEBUG_MODE, // ← Pass debug mode flag
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     _showErrorSnackBar('Error picking image: $e');
  //   }
  // }

  Future<void> _flipCamera() async {
    if (widget.cameras == null || widget.cameras!.isEmpty) {
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        _showErrorSnackBar('No other camera available.');
        return;
      }
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
    } else {
      if (widget.cameras!.length < 2) {
        _showErrorSnackBar('No other camera available.');
        return;
      }
      _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras!.length;
    }

    await _cameraController?.dispose();
    await _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine flash icon state safely
    final isFlashOn = _cameraController?.value.flashMode == FlashMode.always;

    return Scaffold(
      backgroundColor: Colors.black,
      // Removed AppBar to make it full screen immersive
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_cameraController == null || !_cameraController!.value.isInitialized) {
              return const Center(
                  child: Text('Failed to load camera preview.', style: TextStyle(color: Colors.white)));
            }
            return Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                // 1. CAMERA PREVIEW (Full Screen)
                CameraPreview(_cameraController!),

                // 2. DIMMED OVERLAY (Optional - focuses attention on center)
                // You can uncomment this if you want the outside of the box to be darker

                ColorFiltered(
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.srcOut),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                ),


                // 3. SCANNER BOX
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          // Transparent center
                          color: Colors.transparent,
                          // Rounded green border
                          border: Border.all(color: _accentGreen, width: 2),
                          borderRadius: BorderRadius.circular(20),
                          // Subtle glow effect
                          boxShadow: [
                            BoxShadow(
                              color: _accentGreen.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        // Corner decorations (Optional visual flair)
                        child: Stack(
                          children: [
                            // Top Left
                            Positioned(top: 10, left: 10, child: _buildCorner(0)),
                            // Top Right
                            Positioned(top: 10, right: 10, child: _buildCorner(1)),
                            // Bottom Left
                            Positioned(bottom: 10, left: 10, child: _buildCorner(2)),
                            // Bottom Right
                            Positioned(bottom: 10, right: 10, child: _buildCorner(3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Instruction Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Place waste item inside the frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. TOP CONTROLS (Flash)
                Positioned(
                  top: 50,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
// Flash Button (Middle)
                Positioned(
                  top: 50,
                  right: 70, // Shifted left to make room for AI Guide
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: isFlashOn ? Colors.yellow : Colors.white,
                      ),
                      onPressed: () {
                        if (_cameraController != null) {
                          _cameraController!.setFlashMode(
                            isFlashOn ? FlashMode.off : FlashMode.always,
                          );
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
// AI Guide Button (New!)
                Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIGuideScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 5. BOTTOM CONTROL BAR
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 150, // Height of the control area
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Gallery Button
                          _buildCircleButton(
                            icon: Icons.photo_library_outlined,
                            onTap: _pickImageFromGallery,
                          ),

                          // Shutter Button
                          GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: Colors.transparent,
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white, // Inner white circle
                                ),
                              ),
                            ),
                          ),

                          // Flip Camera Button
                          _buildCircleButton(
                            icon: Icons.flip_camera_ios_rounded,
                            onTap: _flipCamera,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator(color: _accentGreen));
          }
        },
      ),
    );
  }

  // Helper for small buttons
  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  // Helper for scanner corners (Just for visuals)
  Widget _buildCorner(int quarter) {
    return Transform.rotate(
      angle: quarter * (3.14159 / 2),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: _accentGreen, width: 4),
            left: BorderSide(color: _accentGreen, width: 4),
          ),
        ),
      ),
    );
  }
}