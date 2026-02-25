import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class WasteClassifier {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const int inputSize = 320;
  // UPDATED: 10 → 9 classes (removed Trash)
  static const int numClasses = 7;

  // ✅ UPDATED: Removed 'Trash' class, kept 9 classes
  static const Map<String, Map<String, dynamic>> wasteInfo = {
    'E-waste': {
      'recyclable': false,
      'category': 'hazardous',
      'icon': '🔌', // Electric plug or 📱
    },
    'Glass': {
      'recyclable': true,
      'category': 'recyclable',
      'icon': '🫙',
    },
    'Metal': {
      'recyclable': true,
      'category': 'recyclable',
      'icon': '🔩',
    },
    'Organic': {
      'recyclable': false,
      'category': 'organic',
      'icon': '🍎',
    },
    'Paper': {
      'recyclable': true,
      'category': 'recyclable',
      'icon': '📄',
    },
    'Plastic': {
      'recyclable': true,
      'category': 'recyclable',
      'icon': '♻️',
    },
    'Textiles': {
      'recyclable': false, // Usually recyclable via special bins
      'category': 'non-recyclable',
      'icon': '👕',
    },
    
  };

  static final WasteClassifier _instance = WasteClassifier._internal();
  factory WasteClassifier() => _instance;
  WasteClassifier._internal();

  Future<void> loadModel() async {
    try {
      print('📂 Attempting to load model...');

      // ✅ UPDATED: Load v2 model file
      final modelData = await rootBundle.load('lib/assets/models/waste_model_quant.tflite');
      print('✅ Model file loaded: ${modelData.lengthInBytes} bytes');

      _interpreter = await Interpreter.fromBuffer(modelData.buffer.asUint8List());
      print('✅ Interpreter created successfully');

      // ✅ UPDATED: Load v2 labels file
      final labelsData = await rootBundle.loadString('lib/assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();

      print('✅ Model loaded successfully. Classes: ${_labels?.length}');
      print('📋 Labels: $_labels');

      // ✅ NEW: Validation check
      if (_labels?.length != numClasses) {
        print('⚠️ Warning: Expected $numClasses classes but got ${_labels?.length}');
      }
    } catch (e) {
      print('❌ Error loading model: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    img.Image resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    var input = List.generate(
      1,
          (i) => List.generate(
        inputSize,
            (y) => List.generate(
          inputSize,
              (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  Future<Map<String, dynamic>> classifyImage(String imagePath) async {
    if (_interpreter == null || _labels == null) {
      await loadModel();
    }

    try {
      final input = await _preprocessImage(File(imagePath));

      var output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

      _interpreter!.run(input, output);

      final probabilities = output[0] as List<double>;

      double maxConfidence = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxConfidence) {
          maxConfidence = probabilities[i];
          maxIndex = i;
        }
      }

      final wasteType = _labels![maxIndex].trim();

      // ✅ IMPROVED: Better error handling if class not in wasteInfo
      final wasteData = wasteInfo[wasteType];

      if (wasteData == null) {
        print('⚠️ Warning: Unknown waste type "$wasteType" detected');
        // Fallback to non-recyclable if unknown class
        return {
          'waste_type': wasteType,
          'confidence_score': maxConfidence,
          'is_recyclable': false,
          'category': 'non-recyclable',
          'icon': '❓',
          'all_predictions': _getAllPredictions(probabilities),
        };
      }

      return {
        'waste_type': wasteType,
        'confidence_score': maxConfidence,
        'is_recyclable': wasteData['recyclable'],
        'category': wasteData['category'],
        'icon': wasteData['icon'],
        'all_predictions': _getAllPredictions(probabilities),
      };
    } catch (e) {
      print('❌ Error during classification: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _getAllPredictions(List<double> probabilities) {
    List<Map<String, dynamic>> predictions = [];

    for (int i = 0; i < probabilities.length && i < _labels!.length; i++) {
      predictions.add({
        'label': _labels![i].trim(),
        'confidence': probabilities[i],
      });
    }

    predictions.sort((a, b) => b['confidence'].compareTo(a['confidence']));

    return predictions;
  }

  void dispose() {
    _interpreter?.close();
  }
}

extension Reshape on List<double> {
  List<List<double>> reshape(List<int> shape) {
    if (shape.length != 2) throw ArgumentError('Only 2D reshape supported');

    final rows = shape[0];
    final cols = shape[1];

    if (length != rows * cols) {
      throw ArgumentError('Shape mismatch');
    }

    return List.generate(
      rows,
          (i) => sublist(i * cols, (i + 1) * cols),
    );
  }
}

