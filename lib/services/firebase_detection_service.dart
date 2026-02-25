import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload image to Firebase Storage
  Future<String> uploadImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final String fileName = 'waste_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String userId = _auth.currentUser?.uid ?? 'anonymous';

      // Upload to Storage
      final Reference ref = _storage.ref().child('waste_detections/$userId/$fileName');
      final UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // Save detection result to Firestore
  Future<String> saveDetection({
    required String wasteType,
    required double confidenceScore,
    required String imageUrl,
    required bool isRecyclable,
    required String category,
  }) async {
    try {
      final String userId = _auth.currentUser?.uid ?? 'anonymous';

      final docRef = await _firestore.collection('wasteDetections').add({
        'user_id': userId,
        'waste_type': wasteType,
        'confidence_score': confidenceScore,
        'image_url': imageUrl,
        'is_recyclable': isRecyclable,
        'category': category, // 'recyclable', 'non-recyclable', 'organic', 'hazardous'
        'upload_date': FieldValue.serverTimestamp(),
        'status': 'detected', // Can be updated to 'disposed' later
      });

      return docRef.id;
    } catch (e) {
      print('Error saving detection: $e');
      rethrow;
    }
  }

  // Get disposal recommendations for a waste type
  Future<Map<String, dynamic>?> getDisposalRecommendations(String wasteType) async {
    try {
      final docSnapshot = await _firestore
          .collection('disposalRecommendations')
          .doc(wasteType)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }

      return null;
    } catch (e) {
      print('Error getting recommendations: $e');
      return null;
    }
  }

  // Get user's detection history
  Future<List<Map<String, dynamic>>> getUserDetections({int limit = 20}) async {
    try {
      final String userId = _auth.currentUser?.uid ?? 'anonymous';

      final querySnapshot = await _firestore
          .collection('wasteDetections')
          .where('user_id', isEqualTo: userId)
          .orderBy('upload_date', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting user detections: $e');
      return [];
    }
  }

  // Update detection status (e.g., when user disposes the waste)
  Future<void> updateDetectionStatus(String detectionId, String status) async {
    try {
      await _firestore.collection('wasteDetections').doc(detectionId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating detection status: $e');
      rethrow;
    }
  }

  // Get statistics (for admin or user dashboard)
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final String userId = _auth.currentUser?.uid ?? 'anonymous';

      final querySnapshot = await _firestore
          .collection('wasteDetections')
          .where('user_id', isEqualTo: userId)
          .get();

      Map<String, int> stats = {
        'total': querySnapshot.docs.length,
        'recyclable': 0,
        'non_recyclable': 0,
        'organic': 0,
        'hazardous': 0,
      };

      for (var doc in querySnapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && stats.containsKey(category)) {
          stats[category] = (stats[category] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting statistics: $e');
      return {'total': 0, 'recyclable': 0, 'non_recyclable': 0, 'organic': 0, 'hazardous': 0};
    }
  }
}