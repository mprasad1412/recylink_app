// lib/services/maintenance_check_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MaintenanceCheckHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if AI Detection is in maintenance mode
  static Future<bool> isMaintenanceMode() async {
    try {
      final doc = await _firestore
          .collection('settings')
          .doc('ai_detection')
          .get();

      return doc.data()?['maintenance_mode'] ?? false;
    } catch (e) {
      return false; // Default to allowing access if check fails
    }
  }

  /// Show maintenance dialog (FIXED - No overflow)
  static void showMaintenanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.construction, color: Colors.orange.shade700, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Under Maintenance',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView( // ✅ FIXED: Added scrollable content
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.build_circle, size: 70, color: Colors.orange.shade300), // ✅ Reduced size
              const SizedBox(height: 12), // ✅ Reduced spacing
              const Text(
                'AI Detection is currently under maintenance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // ✅ Reduced font size
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10), // ✅ Reduced spacing
              Text(
                'We\'re updating our AI model to improve accuracy. Please try again later.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]), // ✅ Reduced font size
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for your patience! 🙏',
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic), // ✅ Reduced font size
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  /// Stream to listen for maintenance mode changes in real-time
  static Stream<bool> maintenanceModeStream() {
    return _firestore
        .collection('settings')
        .doc('ai_detection')
        .snapshots()
        .map((doc) => doc.data()?['maintenance_mode'] ?? false);
  }
}