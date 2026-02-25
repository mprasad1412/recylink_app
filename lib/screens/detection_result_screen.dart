import 'package:flutter/material.dart';
import 'package:recylink/screens/recycling_guide_details_screen.dart';
import 'package:recylink/screens/location_screen.dart';
import 'package:recylink/screens/feedback_screen.dart';
import 'dart:io';

class DetectionResultScreen extends StatelessWidget {
  final String? imagePath;
  final Map<String, dynamic>? detectionResult;
  final String? detectionId;

  const DetectionResultScreen({
    super.key,
    this.imagePath,
    this.detectionResult,
    this.detectionId,
  });

  // ✅ NEW THEME COLORS
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _surfaceColor = Color(0xFFF5F9F6);

  @override
  Widget build(BuildContext context) {
    final wasteType = detectionResult?['waste_type'] ?? 'Unknown';
    final confidence = detectionResult?['confidence_score'] ?? 0.0;
    final category = detectionResult?['category'] ?? 'non-recyclable';
    final icon = detectionResult?['icon'] ?? '🗑️';

    String recyclabilityMessage;
    Color statusColor;
    String? specificTip;

    // Logic for your 9 Classes
    switch (category) {
      case 'recyclable':
        recyclabilityMessage = "Recyclable";
        statusColor = _primaryGreen;
        if (wasteType == 'Textiles') {
          specificTip = "Ensure clothes or shoes or any type of textiles are clean. Use specialized textile bins.";
        } else if (wasteType == 'Glass') {
          specificTip = "Rinse before recycling. Do not break if possible.";
        }
        break;
      case 'organic':
        recyclabilityMessage = "Compostable";
        statusColor = Colors.brown;
        break;
      case 'hazardous': // E-waste
        recyclabilityMessage = "Hazardous";
        statusColor = Colors.redAccent;
        specificTip = "Do not trash! Find an E-waste collection center.";
        break;
      default:
        recyclabilityMessage = "Non-Recyclable";
        statusColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: _surfaceColor, // Mint background
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analysis Result',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. RESULT CARD (Floating Card with Image & Status)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Image Preview (Top half of card)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: imagePath != null && File(imagePath!).existsSync()
                          ? Image.file(File(imagePath!), fit: BoxFit.cover)
                          : Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Result Details (Bottom half of card)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Icon Bubble
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 40)),
                        ),
                        const SizedBox(height: 16),

                        // Waste Type Title
                        Text(
                          wasteType,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Recyclability Status Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            recyclabilityMessage.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Confidence Text
                        Text(
                          'AI Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. SPECIFIC TIPS (Blue Info Box)
            if (specificTip != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        specificTip!,
                        style: TextStyle(color: Colors.blue[800], fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. WARNING BOX (Orange - Low Confidence)
            if (confidence < 0.65)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        wasteType == 'Plastic'
                            ? "Plastic can look like Glass. Please check the texture."
                            : "The AI isn't 100% sure. Try taking a closer photo.",
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Recycle Guide',
                    icon: Icons.menu_book_rounded,
                    color: _primaryGreen,
                    isOutlined: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecyclingGuideDetailsScreen(material: wasteType),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Find Centers',
                    icon: Icons.map_rounded,
                    color: _primaryGreen,
                    isOutlined: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationScreen(autoFilterMaterial: wasteType),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 5. REPORT ISSUE FOOTER
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedbackScreen(
                        imagePath: imagePath,
                        predictedType: wasteType,
                        confidenceScore: confidence,
                        detectionId: detectionId,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.flag_outlined, color: Colors.grey[500], size: 18),
                label: Text(
                  "Report incorrect result",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper for consistent button styling
  Widget _buildActionButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required bool isOutlined,
        required VoidCallback onTap,
      }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.white : color,
        foregroundColor: isOutlined ? color : Colors.white,
        elevation: isOutlined ? 0 : 5,
        shadowColor: isOutlined ? null : color.withOpacity(0.4),
        side: isOutlined ? BorderSide(color: color, width: 2) : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}
