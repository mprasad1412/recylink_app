import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:recylink/screens/recycling_guide_details_screen.dart';
import 'package:recylink/screens/camera_screen.dart';
import 'package:recylink/screens/main_screen.dart';

class MaterialAwarenessScreen extends StatefulWidget {
  final String material; // 'Plastic', 'Paper', 'Glass', etc.

  const MaterialAwarenessScreen({super.key, required this.material});

  @override
  State<MaterialAwarenessScreen> createState() => _MaterialAwarenessScreenState();
}

class _MaterialAwarenessScreenState extends State<MaterialAwarenessScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  int _materialScans = 0;
  int _communityRecycling = 0;
  int _activeRecyclers = 0;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color surfaceColor = Color(0xFFF5F9F6);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Show last 3 months of community data (more impressive numbers!)
      final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);

      print('🔍 DEBUG: Loading data for ${widget.material}');
      print('📅 Start of month: $startOfMonth');
      print('📅 Three months ago: $threeMonthsAgo');

      // 1. Material-specific scans (AI detections) - Current month only
      final scansQuery = await _firestore
          .collection('wasteDetections')
          .where('waste_type', isEqualTo: widget.material)
          .where('upload_date', isGreaterThanOrEqualTo: Timestamp.fromDate(threeMonthsAgo))
          .get();

      print('✅ Scans found: ${scansQuery.docs.length}');

      // 2. Community recycling (ALL materials - verified challenges) - Last 3 months
      print('🔍 Querying userChallenges...');
      final challengesQuery = await _firestore
          .collection('userChallenges')
          .where('status', isEqualTo: 'completed')  //  Changed from 'approved'
          .where('completion_date', isGreaterThanOrEqualTo: Timestamp.fromDate(threeMonthsAgo))  // Last 3 months
          .get();

      print('📊 Total completed challenges found: ${challengesQuery.docs.length}');

      // Calculate total items recycled (sum of target_count)
      int totalRecycled = 0;
      Set<String> uniqueUsers = {};

      for (var doc in challengesQuery.docs) {
        final data = doc.data();
        print('📦 Challenge doc: ${doc.id}');
        print('   - status: ${data['status']}');
        print('   - completion_date: ${data['completion_date']}');
        print('   - target_count: ${data['target_count']}');
        print('   - user_id: ${data['user_id']}');

        totalRecycled += (data['target_count'] as int?) ?? 1;
        if (data['user_id'] != null) {
          uniqueUsers.add(data['user_id']);
        }
      }

      print('✅ Total recycled: $totalRecycled');
      print('✅ Unique users: ${uniqueUsers.length}');

      setState(() {
        _materialScans = scansQuery.docs.length;
        _communityRecycling = totalRecycled;
        _activeRecyclers = uniqueUsers.length;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialData = _getMaterialData(widget.material);

    return Scaffold(
      backgroundColor: surfaceColor, // Mint background
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.material,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HERO ICON HEADER
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    materialData['icon']!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.eco, size: 60, color: primaryGreen);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. STATS SECTION (Learning & Community combined)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Impact Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Scans • Community stats (last 3 months)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatCard(
                      value: _materialScans.toString(),
                      label: 'Scans',
                      icon: Icons.qr_code_scanner_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernStatCard(
                      value: _communityRecycling.toString(),
                      label: 'Recycled (All)',
                      icon: Icons.check_circle_outline_rounded,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. DID YOU KNOW?
              _buildDidYouKnowCard(materialData['didYouKnow']!),
              const SizedBox(height: 24),

              // 4. QUICK GUIDE
              const Text(
                'Quick Guide',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              _buildModernQuickGuide(
                materialData['dos'] as List<String>,
                materialData['donts'] as List<String>,
              ),
              const SizedBox(height: 30),

              // 5. ACTIONS
              _buildActionButtons(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildModernStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen.withOpacity(0.8), primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCommunityStatItem(
                '✅',
                _communityRecycling.toString(),
                'Items Verified',
              ),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
              _buildCommunityStatItem(
                '🏆',
                _activeRecyclers.toString(),
                'Active Recyclers',
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'All materials combined • This month',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStatItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDidYouKnowCard(String fact) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade200, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              fact,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickGuide(List<String> dos, List<String> donts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildChecklistSection("Do's", dos, Icons.check_circle_rounded, primaryGreen),
          Divider(height: 1, color: Colors.grey[200]),
          _buildChecklistSection("Don'ts", donts, Icons.cancel_rounded, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildChecklistSection(String title, List<String> items, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Full Guide Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecyclingGuideDetailsScreen(
                    material: widget.material,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.menu_book, color: Colors.white),
            label: const Text(
              'View Full Guide',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Scan Now Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              // Get available cameras
              final cameras = await availableCameras();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(cameras: cameras),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.camera_alt, color: primaryGreen),
            label: Text(
              'Scan ${widget.material} Now',
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Join Challenges Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Switch to Challenges tab (index 3)
              mainScreenKey.currentState?.switchToTab(3);
              Navigator.pop(context); // Close current screen
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.emoji_events, color: Colors.grey[700]),
            label: Text(
              'Join Active Challenges',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTooltip() {
    return Tooltip(
      message: 'Community-wide verified recycling across all materials',
      child: Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
    );
  }

  // Material-specific data
  Map<String, dynamic> _getMaterialData(String material) {
    // ✅ Updated with your actual asset paths
    final Map<String, Map<String, dynamic>> allMaterialData = {
      'Plastic': {
        'icon': 'lib/assets/plasticicon.png',
        'didYouKnow': '1 recycled plastic bottle saves enough energy to power a LED bulb for 3 hours.',
        'dos': ['Rinse containers', 'Check symbols (1-7)', 'Remove caps', 'Flatten bottles'],
        'donts': ['No dirty containers', 'No mixed types', 'No Styrofoam', 'No plastic bags'],
      },
      'Paper': {
        'icon': 'lib/assets/papericon.png',
        'didYouKnow': 'Recycling 1 ton of paper saves 17 trees and 7,000 gallons of water.',
        'dos': ['Keep dry and clean', 'Flatten boxes', 'Remove plastic windows', 'Staples are okay'],
        'donts': ['No greasy paper', 'No wet paper', 'No tissue/towels', 'No wax-coated paper'],
      },
      'Glass': {
        'icon': 'lib/assets/glassicon.png',
        'didYouKnow': 'Glass can be recycled endlessly without losing quality or purity.',
        'dos': ['Rinse bottles/jars', 'Remove metal caps', 'Separate by color', 'Check for symbols'],
        'donts': ['No broken glass', 'No window glass', 'No ceramics', 'No light bulbs'],
      },
      'Metal': {
        'icon': 'lib/assets/metalicon.png',
        'didYouKnow': 'Aluminum recycling saves 95% of the energy needed to make new aluminum.',
        'dos': ['Rinse food cans', 'Crush to save space', 'Remove labels', 'Include foil'],
        'donts': ['No aerosol residue', 'No paint cans', 'No scrap metal', 'No batteries here'],
      },
      'E-waste': {
        'icon': 'lib/assets/e-wasteicon.png',
        'didYouKnow': 'E-waste contains valuable materials like gold, yet only 17% is recycled.',
        'dos': ['Certified centers', 'Remove batteries', 'Wipe personal data', 'Check take-back programs'],
        'donts': ['Don\'t trash it', 'Don\'t dismantle', 'Don\'t mix with bins', 'Avoid water exposure'],
      },
      'Textiles': {
        'icon': 'lib/assets/textilesicon.png',
        'didYouKnow': 'Recycling textiles reduces the massive carbon footprint of the fashion industry.',
        'dos': ['Clean and dry', 'Use textile bins', 'Donate wearable items', 'Repurpose scraps'],
        'donts': ['No wet/moldy items', 'No stained items', 'No mixed materials', 'No contamination'],
      },
      'Organic': {
        'icon': 'lib/assets/organicon.png',
        'didYouKnow': 'Composting reduces methane emissions from landfills by up to 50%.',
        'dos': ['Start composting', 'Fruit/Veg scraps', 'Coffee grounds', 'Green & Brown mix'],
        'donts': ['No meat/dairy', 'No pet waste', 'No diseased plants', 'No oils/grease'],
      },
    };

    return allMaterialData[material] ?? allMaterialData['Plastic']!;
  }
}