import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclingGuideDetailsScreen extends StatefulWidget {
  final String material; // e.g., 'Plastic'

  const RecyclingGuideDetailsScreen({super.key, required this.material});

  @override
  State<RecyclingGuideDetailsScreen> createState() => _RecyclingGuideDetailsScreenState();
}

class _RecyclingGuideDetailsScreenState extends State<RecyclingGuideDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _guideData;
  String? _error;

  // Define colors
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _surfaceColor = const Color(0xFFF5F9F6);
  final Color _redAccent = const Color(0xFFD32F2F);

  String _getIconPath(String material) {
    switch (material.toLowerCase()) {
      case 'plastic': return 'lib/assets/plasticicon.png';
      case 'paper': return 'lib/assets/papericon.png';
      case 'glass': return 'lib/assets/glassicon.png';
      case 'metal': return 'lib/assets/metalicon.png';
      case 'e-waste': return 'lib/assets/e-wasteicon.png';
      case 'textiles':
      case 'clothes': return 'lib/assets/textilesicon.png';
      case 'organic': return 'lib/assets/organicon.png';
      default: return 'lib/assets/guide.png'; // Fallback
    }
  }

  // Fallback data (in case Firebase fails)
  final Map<String, Map<String, List<String>>> _fallbackContent = {
    'Plastic': {
      'dos': [
        'Rinse plastics to remove food and liquid residue.',
        'Check recycling symbols (1-7) to confirm recyclability.',
        'Separate by type if required by local guidelines.',
        'Follow local rules for what is accepted in recycling bins.',
        'Remove caps unless marked as recyclable together.',
      ],
      'donts': [
        "Don't recycle dirty or food-soiled plastics.",
        "Don't include plastic bags unless specified by your local center.",
        "Don't mix non-recyclables like Styrofoam or PVC with recyclables.",
        "Don't assume all plastics are recyclable—check labels.",
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGuideData();
  }

  Future<void> _loadGuideData() async {
    try {
      // Fetch from Firebase
      final docSnapshot = await _firestore
          .collection('disposalRecommendations')
          .doc(widget.material)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _guideData = docSnapshot.data();
          _isLoading = false;
        });
      } else {
        // Use fallback data
        setState(() {
          _guideData = {
            'dos': _fallbackContent[widget.material]?['dos'] ?? [],
            'donts': _fallbackContent[widget.material]?['donts'] ?? [],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading guide data: $e');
      setState(() {
        _error = 'Failed to load guide data';
        _guideData = {
          'dos': _fallbackContent[widget.material]?['dos'] ?? [],
          'donts': _fallbackContent[widget.material]?['donts'] ?? [],
        };
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine active color based on tab index
    Color activeColor = _tabController.index == 0 ? _primaryGreen : _redAccent;

    return Scaffold(
      backgroundColor: _surfaceColor, // Consistent mint background
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
        title: Text(
          'Recycling Guide',
          style: TextStyle(color: Colors.black.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryGreen))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // 1. DYNAMIC HEADER ICON
          Container(
            height: 100,
            width: 100,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Image.asset(
              _getIconPath(widget.material),
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Icon(Icons.recycling, size: 50, color: _primaryGreen),
            ),
          ),

          const SizedBox(height: 16),

          // 2. MATERIAL TITLE
          Text(
            widget.material,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),

          // Category Badge (if available)
          if (_guideData?['category'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _getCategoryColor(_guideData!['category']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getCategoryColor(_guideData!['category']).withOpacity(0.3)),
              ),
              child: Text(
                _guideData!['category'].toString().toUpperCase(),
                style: TextStyle(
                  color: _getCategoryColor(_guideData!['category']),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 3. MODERN TAB BAR
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: activeColor, // Changes from Green to Red
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              onTap: (index) => setState(() {}), // Trigger rebuild to update colors
              tabs: const [
                Tab(text: "Do's"),
                Tab(text: "Don'ts"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. CONTENT LIST
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModernGuideList(
                  _guideData?['dos'] ?? [],
                  Icons.check_circle_rounded,
                  _primaryGreen,
                  Colors.green[50]!,
                ),
                _buildModernGuideList(
                  _guideData?['donts'] ?? [],
                  Icons.cancel_rounded,
                  _redAccent,
                  Colors.red[50]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernGuideList(dynamic items, IconData iconData, Color color, Color bgColor) {
    List<String> itemList = [];
    if (items is List) {
      itemList = items.map((item) => item.toString()).toList();
    }

    if (itemList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('No information available', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: itemList.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  itemList[index],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return _primaryGreen;
      case 'hazardous':
        return Colors.red;
      case 'organic':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}