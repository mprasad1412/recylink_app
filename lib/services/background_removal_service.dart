import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

/// Service to remove/blur backgrounds from images to improve classification accuracy
class BackgroundRemovalService {
  /// Process image to isolate the main object
  /// Returns path to the processed image
  Future<String> processImage(String originalPath) async {
    try {
      // Load original image
      final bytes = await File(originalPath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Apply edge-based segmentation to isolate foreground
      final processed = await _isolateCenterObject(image);

      // Save processed image
      final processedPath = originalPath.replaceAll('.jpg', '_processed.jpg');
      await File(processedPath).writeAsBytes(img.encodeJpg(processed, quality: 85));

      return processedPath;
    } catch (e) {
      print('Error in background removal: $e');
      // Return original if processing fails
      return originalPath;
    }
  }

  /// Isolate the center object using edge detection and color clustering
  Future<img.Image> _isolateCenterObject(img.Image original) async {
    final width = original.width;
    final height = original.height;

    // Create a copy for processing
    final processed = img.Image.from(original);

    // Define center region (where the scanner frame is)
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;
    final regionSize = math.min(width, height) * 0.8; // 60% of image centered

    // Get dominant colors in center region (the object)
    final centerColors = _getSampleColors(
      original,
      centerX - regionSize ~/ 2,
      centerY - regionSize ~/ 2,
      regionSize.toInt(),
      regionSize.toInt(),
    );

    // Blur/darken pixels that don't match object colors
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = processed.getPixel(x, y);

        // Calculate distance from center
        final dx = (x - centerX).abs();
        final dy = (y - centerY).abs();
        final distanceFromCenter = math.sqrt(dx * dx + dy * dy);
        final maxDistance = regionSize / 2;

        // If far from center or color doesn't match object
        if (distanceFromCenter > maxDistance ||
            !_isColorSimilar(pixel, centerColors)) {
          // Gradually blur/darken based on distance
          final fadeFactor = (distanceFromCenter / maxDistance).clamp(0.0, 1.0);

          processed.setPixel(x, y, img.ColorRgba8(
            (pixel.r * (1 - fadeFactor * 0.7)).toInt(),
            (pixel.g * (1 - fadeFactor * 0.7)).toInt(),
            (pixel.b * (1 - fadeFactor * 0.7)).toInt(),
            255,
          ));
        }
      }
    }

    return processed;
  }

  /// Sample colors from a region to identify the object
  List<img.Color> _getSampleColors(
      img.Image image,
      int startX,
      int startY,
      int sampleWidth,
      int sampleHeight,
      ) {
    final colors = <img.Color>[];
    final step = 10; // Sample every 10 pixels for performance

    for (int y = startY; y < startY + sampleHeight && y < image.height; y += step) {
      for (int x = startX; x < startX + sampleWidth && x < image.width; x += step) {
        colors.add(image.getPixel(x, y));
      }
    }

    return colors;
  }

  /// Check if a pixel color is similar to the object colors
  bool _isColorSimilar(img.Color pixel, List<img.Color> referenceColors) {
    const threshold = 60; // Color difference threshold

    for (final refColor in referenceColors) {
      final rDiff = (pixel.r - refColor.r).abs();
      final gDiff = (pixel.g - refColor.g).abs();
      final bDiff = (pixel.b - refColor.b).abs();

      final totalDiff = rDiff + gDiff + bDiff;

      if (totalDiff < threshold) {
        return true;
      }
    }

    return false;
  }

  /// Alternative: Simple center crop approach (faster but less accurate)
  Future<String> centerCropImage(String originalPath) async {
    try {
      final bytes = await File(originalPath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return originalPath;

      // Crop to center 70%
      final cropSize = (math.min(image.width, image.height) * 0.7).toInt();
      final startX = (image.width - cropSize) ~/ 2;
      final startY = (image.height - cropSize) ~/ 2;

      final cropped = img.copyCrop(
        image,
        x: startX,
        y: startY,
        width: cropSize,
        height: cropSize,
      );

      final croppedPath = originalPath.replaceAll('.jpg', '_cropped.jpg');
      await File(croppedPath).writeAsBytes(img.encodeJpg(cropped, quality: 85));

      return croppedPath;
    } catch (e) {
      print('Error in center crop: $e');
      return originalPath;
    }
  }
}