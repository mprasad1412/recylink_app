import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  final String? autoFilterMaterial;
  const LocationScreen({super.key, this.autoFilterMaterial});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {

  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _accentGreen = const Color(0xFFAEE55B);
  final Color _surfaceColor = const Color(0xFFF5F9F6);
  final Color _darkGreenNav = const Color(0xFF4D8000);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter variables
  String? _selectedState;
  String _sortOrder = 'none'; // 'none', 'a-z', 'z-a'
  Set<String> _selectedMaterials = {};

  // Malaysian states
  final List<String> _malaysianStates = [
    'Selangor',
    'Kuala Lumpur',
    'Putrajaya',
    'Johor',
    'Penang',
    'Perak',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Kelantan',
    'Terengganu',
    'Kedah',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Labuan',
  ];

  // Common material types
  final List<String> _materialTypes = [
    'Plastic',
    'Paper',
    'Glass',
    'Metal',
    'Cardboard',
    'Aluminium',
    'Battery',
    'Electronic',
    'E-waste',
    'Food',
    'Cloth',
    'Fabric',
  ];

  @override
  void initState() {
    super.initState();

    // Auto-apply material filter if passed from detection screen
    if (widget.autoFilterMaterial != null) {
      final mappedFilters = _mapWasteTypeToFilters(widget.autoFilterMaterial!);
      _selectedMaterials = Set.from(mappedFilters);
    }
  }

  // Map detected waste types to location filter materials
  List<String> _mapWasteTypeToFilters(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'plastic':
        return ['Plastic'];
      case 'paper':
        return ['Paper', 'Cardboard'];
      case 'glass':
        return ['Glass'];
      case 'metal':
        return ['Metal', 'Aluminium'];
      case 'e-waste':
        return ['E-waste', 'Electronic', 'Battery'];
      case 'organic':
        return ['Food'];
      case 'textiles':
        return ['Cloth', 'Fabric'];
      default:
        return []; // No filter for unknown types
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor, // Mint background
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80, // Taller header for better spacing
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // Softer corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search centers...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: _primaryGreen),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: _hasActiveFilters() ? _primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: _hasActiveFilters() ? Colors.white : Colors.grey[700],
                ),
                onPressed: () {
                  _showFilterDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Text
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Recycling Centers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Active Filters Row
            if (_hasActiveFilters()) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildActiveFiltersChips()),
                  TextButton(
                    onPressed: _clearAllFilters,
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Stream from Firebase
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('locations')
                    .where('approval_status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _primaryGreen));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading data', style: TextStyle(color: Colors.grey[600])));
                  }

                  final allLocations = snapshot.data?.docs ?? [];
                  List<QueryDocumentSnapshot> filteredLocations = _applyFilters(allLocations);

                  if (filteredLocations.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredLocations.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = filteredLocations[index];
                      final data = doc.data() as Map<String, dynamic>;
                      // Use a modern card builder (defined in Step 3)
                      return _buildModernLocationCard(data, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLocationCard(Map<String, dynamic> data, int index) {
    final name = data['location_name'] ?? 'Unknown Location';
    final address = data['address'] ?? 'No address provided';
    final operatingHours = data['operating_hours'] ?? 'Hours not specified';

    return GestureDetector(
      onTap: () => _showLocationDetails(context, data),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Box
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.recycling_rounded, color: _primaryGreen, size: 28),
            ),
            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          operatingHours,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isEmpty && !_hasActiveFilters()
                  ? Icons.location_off_rounded
                  : Icons.search_off_rounded,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && !_hasActiveFilters()
                ? 'No centers nearby'
                : 'No results found',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Check if any filters are active
  bool _hasActiveFilters() {
    return _selectedState != null ||
        _sortOrder != 'none' ||
        _selectedMaterials.isNotEmpty;
  }

  // Clear all filters
  void _clearAllFilters() {
    setState(() {
      _selectedState = null;
      _sortOrder = 'none';
      _selectedMaterials.clear();
    });
  }

  // Build active filters chips
  Widget _buildActiveFiltersChips() {
    List<Widget> chips = [];

    if (_selectedState != null) {
      chips.add(
        Chip(
          label: Text(_selectedState!),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            setState(() {
              _selectedState = null;
            });
          },
        ),
      );
    }

    if (_sortOrder != 'none') {
      chips.add(
        Chip(
          label: Text(_sortOrder == 'a-z' ? 'A-Z' : 'Z-A'),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            setState(() {
              _sortOrder = 'none';
            });
          },
        ),
      );
    }

    for (var material in _selectedMaterials) {
      chips.add(
        Chip(
          label: Text(material),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            setState(() {
              _selectedMaterials.remove(material);
            });
          },
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  // Apply all filters to locations
  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> locations) {
    List<QueryDocumentSnapshot> filtered = locations;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['location_name'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();

        return name.contains(_searchQuery) ||
            address.contains(_searchQuery) ||
            description.contains(_searchQuery);
      }).toList();
    }

    // State filter
    if (_selectedState != null) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final address = (data['address'] ?? '').toString();
        return address.contains(_selectedState!);
      }).toList();
    }

    // Material filter
    if (_selectedMaterials.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final description = (data['description'] ?? '').toString().toLowerCase();

        // Check if description contains any of the selected materials
        return _selectedMaterials.any((material) =>
            description.contains(material.toLowerCase()));
      }).toList();
    }

    // Sort alphabetically
    if (_sortOrder == 'a-z') {
      filtered.sort((a, b) {
        final nameA = ((a.data() as Map<String, dynamic>)['location_name'] ?? '')
            .toString()
            .toLowerCase();
        final nameB = ((b.data() as Map<String, dynamic>)['location_name'] ?? '')
            .toString()
            .toLowerCase();
        return nameA.compareTo(nameB);
      });
    } else if (_sortOrder == 'z-a') {
      filtered.sort((a, b) {
        final nameA = ((a.data() as Map<String, dynamic>)['location_name'] ?? '')
            .toString()
            .toLowerCase();
        final nameB = ((b.data() as Map<String, dynamic>)['location_name'] ?? '')
            .toString()
            .toLowerCase();
        return nameB.compareTo(nameA);
      });
    }

    return filtered;
  }

  // Show filter dialog
  void _showFilterDialog(BuildContext context) {
    const Color primaryGreen = Color(0xFFAEE55B);

    // Create temporary variables for dialog state
    String? tempSelectedState = _selectedState;
    String tempSortOrder = _sortOrder;
    Set<String> tempSelectedMaterials = Set.from(_selectedMaterials);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Locations'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // State Filter
                const Text(
                  'Filter by State',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tempSelectedState,
                  decoration: InputDecoration(
                    hintText: 'Select a state',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All States'),
                    ),
                    ..._malaysianStates.map((state) => DropdownMenuItem(
                      value: state,
                      child: Text(state),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempSelectedState = value;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Sort Order
                const Text(
                  'Sort by Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...['none', 'a-z', 'z-a'].map((sort) {
                  String label = sort == 'none'
                      ? 'Default'
                      : sort == 'a-z'
                      ? 'A to Z'
                      : 'Z to A';
                  return RadioListTile<String>(
                    title: Text(label),
                    value: sort,
                    groupValue: tempSortOrder,
                    activeColor: primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setDialogState(() {
                        tempSortOrder = value!;
                      });
                    },
                  );
                }),
                const SizedBox(height: 20),

                // Material Filter
                const Text(
                  'Filter by Material Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _materialTypes.map((material) {
                    final isSelected = tempSelectedMaterials.contains(material);
                    return FilterChip(
                      label: Text(material),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            tempSelectedMaterials.add(material);
                          } else {
                            tempSelectedMaterials.remove(material);
                          }
                        });
                      },
                      selectedColor: primaryGreen.withOpacity(0.3),
                      checkmarkColor: Colors.green[800],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Reset filters
                setDialogState(() {
                  tempSelectedState = null;
                  tempSortOrder = 'none';
                  tempSelectedMaterials.clear();
                });
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Apply filters
                setState(() {
                  _selectedState = tempSelectedState;
                  _sortOrder = tempSortOrder;
                  _selectedMaterials = tempSelectedMaterials;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ NEW: Open Google Maps with the address
  Future<void> _openMaps(String address) async {
    // Encode the address for URL
    final encodedAddress = Uri.encodeComponent(address);

    // Google Maps URL
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    try {
      // Just try to launch directly without canLaunchUrl check
      // This works better on Android 11+
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication, // Opens in external maps app
      );
    } catch (e) {
      // If it fails, show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps. Please install Google Maps.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✨ UPDATED: Show detailed location info dialog with "Show Directions" button
  void _showLocationDetails(BuildContext context, Map<String, dynamic> data) {
    final address = data['address'] ?? 'No address';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['location_name'] ?? 'Location Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Address:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Operating Hours:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                data['operating_hours'] ?? 'Not specified',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                data['contact_num']?.toString() ?? 'No contact info',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                data['description'] ?? 'No description available',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          // ✨ NEW: Show Directions button
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog first
              _openMaps(address); // Then open maps
            },
            icon: const Icon(Icons.directions, color: Color(0xFF2E7D32)),
            label: const Text(
              'Show Directions',
              style: TextStyle(color: Color(0xFF2E7D32)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}