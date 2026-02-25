import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class AIDetectionScreen extends StatelessWidget {
  const AIDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9F6), // Mint Surface
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Detection Management',
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    labelColor: Color(0xFF2E7D32),
                    // Primary Green
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF2E7D32),
                    // Primary Green
                    indicatorWeight: 3,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: [
                      Tab(text: 'User Detections'),
                      Tab(text: 'Disposal Recommendations'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _UserDetectionsTab(),
                  _DisposalRecommendationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ==================== USER DETECTIONS TAB ====================
class _UserDetectionsTab extends StatefulWidget {
  @override
  State<_UserDetectionsTab> createState() => _UserDetectionsTabState();
}

class _UserDetectionsTabState extends State<_UserDetectionsTab> {
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedIds = {};
  bool _isSelectAll = false;

  // Sorting
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filterAndSortDetections(
      List<QueryDocumentSnapshot> detections) {
    // Filter by search query
    var filtered = detections.where((doc) {
      if (_searchQuery.isEmpty) return true;

      final data = doc.data() as Map<String, dynamic>;
      final wasteType = (data['waste_type'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      final userId = (data['user_id'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return wasteType.contains(query) ||
          category.contains(query) ||
          userId.contains(query);
    }).toList();

    // Sort by selected column
    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      dynamic aValue, bValue;

      switch (_sortColumnIndex) {
        case 0: // User ID
          aValue = aData['user_id'] ?? '';
          bValue = bData['user_id'] ?? '';
          break;
        case 1: // Waste Type
          aValue = aData['waste_type'] ?? '';
          bValue = bData['waste_type'] ?? '';
          break;
        case 2: // Category
          aValue = aData['category'] ?? '';
          bValue = bData['category'] ?? '';
          break;
        case 3: // Confidence
          aValue = aData['confidence_score'] ?? 0.0;
          bValue = bData['confidence_score'] ?? 0.0;
          break;
        case 4: // Recyclable
          aValue = aData['is_recyclable'] ?? false;
          bValue = bData['is_recyclable'] ?? false;
          break;
        case 5: // Date
          aValue = aData['upload_date'];
          bValue = bData['upload_date'];
          break;
        case 6: // Status
          aValue = aData['status'] ?? '';
          bValue = bData['status'] ?? '';
          break;
        default:
          return 0;
      }

      final comparison = aValue.toString().toLowerCase().compareTo(
          bValue.toString().toLowerCase());
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> detections) {
    setState(() {
      if (_isSelectAll) {
        _selectedIds.clear();
        _isSelectAll = false;
      } else {
        _selectedIds = detections.map((doc) => doc.id).toSet();
        _isSelectAll = true;
      }
    });
  }

  void _toggleSelection(String id, int totalDetections) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _isSelectAll = false;
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == totalDetections) _isSelectAll = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), // Pill Shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by waste type, category, or user ID...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _currentPage = 0;
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Bulk Delete Banner (Keep your existing logic, it's fine)
          if (_selectedIds.isNotEmpty)
          // ... (Keep existing container, just ensure it doesn't break the layout) ...
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedIds.length} detection(s) selected',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900]),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedIds.clear();
                      _isSelectAll = false;
                    }),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _bulkDeleteDetections(context),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete Selected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          // Table with pagination
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().getAllDetections(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDetections = snapshot.data?.docs ?? [];
                final detections = _filterAndSortDetections(allDetections);

                if (detections.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.eco : Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No detections yet'
                              : 'No detections found matching "$_searchQuery"',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate pagination
                final totalPages = (detections.length / _rowsPerPage).ceil();
                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }
                final startIndex = _currentPage * _rowsPerPage;
                final endIndex = (startIndex + _rowsPerPage).clamp(0, detections.length);
                final paginatedDetections = detections.sublist(startIndex, endIndex);

                // REPLACED Card WITH Container
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20), // Eco-Modern Radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Table
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columnSpacing: 40,
                              headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F9F6)), // Mint Header
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              columns: [
                                DataColumn(
                                  label: Checkbox(
                                    value: _isSelectAll,
                                    onChanged: (value) => _toggleSelectAll(detections),
                                    activeColor: const Color(0xFF2E7D32), // Green Checkbox
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                // ... KEEP YOUR COLUMNS (Just copy from previous file) ...
                                DataColumn(label: const Text('User ID', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (col, asc) => setState(() { _sortColumnIndex = col; _sortAscending = asc; })),
                                DataColumn(label: const Text('Waste Type', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (col, asc) => setState(() { _sortColumnIndex = col; _sortAscending = asc; })),
                                DataColumn(label: const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (col, asc) => setState(() { _sortColumnIndex = col; _sortAscending = asc; })),
                                DataColumn(label: const Text('Confidence', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (col, asc) => setState(() { _sortColumnIndex = col; _sortAscending = asc; })),
                                DataColumn(label: const Text('Recyclable', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (col, asc) => setState(() { _sortColumnIndex = col; _sortAscending = asc; })),
                                DataColumn(label: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (col, asc) => setState(() { _sortColumnIndex = col; _sortAscending = asc; })),
                                DataColumn(label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (col, asc) => setState(() { _sortColumnIndex = col; _sortAscending = asc; })),
                                const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: paginatedDetections.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final detectionId = doc.id;
                                // ... (Keep your variable extractions) ...
                                final userId = data['user_id'] ?? 'N/A';
                                final wasteType = data['waste_type'] ?? 'Unknown';
                                final category = data['category'] ?? 'N/A';
                                final confidence = data['confidence_score'] ?? 0.0;
                                final isRecyclable = data['is_recyclable'] ?? false;
                                final uploadDate = data['upload_date'] as Timestamp?;
                                final status = data['status'] ?? 'detected';
                                final imageUrl = data['image_url'];

                                return DataRow(
                                  selected: _selectedIds.contains(detectionId),
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: _selectedIds.contains(detectionId),
                                        onChanged: (value) => _toggleSelection(detectionId, detections.length),
                                        activeColor: const Color(0xFF2E7D32),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                    // ... KEEP CELLS ...
                                    DataCell(SizedBox(width: 120, child: Tooltip(message: userId, child: Text(userId.length > 8 ? '${userId.substring(0, 8)}...' : userId)))),
                                    DataCell(SizedBox(width: 150, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _getCategoryColor(category).withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text(wasteType, style: TextStyle(fontWeight: FontWeight.bold, color: _getCategoryColor(category), fontSize: 12), overflow: TextOverflow.ellipsis)))),
                                    DataCell(SizedBox(width: 120, child: Text(category))),
                                    DataCell(SizedBox(width: 100, child: Text('${(confidence * 100).toStringAsFixed(1)}%', style: TextStyle(color: confidence > 0.8 ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)))),
                                    DataCell(SizedBox(width: 80, child: Icon(isRecyclable ? Icons.check_circle : Icons.cancel, color: isRecyclable ? Colors.green : Colors.red, size: 20))),
                                    DataCell(SizedBox(width: 100, child: Text(uploadDate != null ? '${uploadDate.toDate().day}/${uploadDate.toDate().month}/${uploadDate.toDate().year}' : 'N/A', style: const TextStyle(fontSize: 12)))),
                                    DataCell(SizedBox(width: 100, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: status == 'detected' ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(fontSize: 12, color: status == 'detected' ? Colors.blue : Colors.grey))))),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (imageUrl != null)
                                            IconButton(
                                              icon: const Icon(Icons.image_outlined, size: 20, color: Color(0xFF2E7D32)), // Green Icon
                                              tooltip: 'View Image',
                                              onPressed: () => _showImageDialog(context, imageUrl, data),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFD32F2F)), // Red Icon
                                            tooltip: 'Delete',
                                            onPressed: () => _deleteDetection(context, detectionId),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      // Pagination controls
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${startIndex + 1}-$endIndex of ${detections.length} detections${_searchQuery.isNotEmpty ? " (filtered)" : ""}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            if (totalPages > 0)
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                    icon: const Icon(Icons.chevron_left),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Page ${_currentPage + 1} of $totalPages',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return Colors.green;
      case 'hazardous':
        return Colors.red;
      case 'organic':
        return Colors.brown;
      case 'non-recyclable':
        return const Color(0xFF546E7A);
      default:
        return Colors.grey;
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl,
      Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) =>
          Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detection Details',
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 64),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Details
                  _buildDetailRow('Waste Type:', data['waste_type'] ?? 'N/A'),
                  _buildDetailRow('Category:', data['category'] ?? 'N/A'),
                  _buildDetailRow('Confidence:',
                      '${(data['confidence_score'] ?? 0.0) * 100}%'),
                  _buildDetailRow('Recyclable:',
                      data['is_recyclable'] == true ? 'Yes' : 'No'),
                  _buildDetailRow('Status:', data['status'] ?? 'detected'),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _bulkDeleteDetections(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text('Delete Multiple Detections'),
            content: Text(
              'Are you sure you want to delete ${_selectedIds
                  .length} detection(s)? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        for (final id in _selectedIds) {
          await FirestoreService().deleteDetection(id);
        }
        setState(() {
          _selectedIds.clear();
          _isSelectAll = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Detections deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }


  Future<void> _deleteDetection(BuildContext context,
      String detectionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text('Delete Detection'),
            content: const Text(
                'Are you sure you want to delete this detection?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirestoreService().deleteDetection(detectionId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Detection deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
// ==================== DISPOSAL RECOMMENDATIONS TAB ====================
class _DisposalRecommendationsTab extends StatefulWidget {
  @override
  State<_DisposalRecommendationsTab> createState() => _DisposalRecommendationsTabState();
}

class _DisposalRecommendationsTabState extends State<_DisposalRecommendationsTab> {
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  // Sorting
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  List<QueryDocumentSnapshot> _sortRecommendations(List<QueryDocumentSnapshot> recommendations) {
    // Sort by selected column
    recommendations.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      dynamic aValue, bValue;

      switch (_sortColumnIndex) {
        case 0: // Waste Type
          aValue = a.id;
          bValue = b.id;
          break;
        case 1: // Category
          aValue = aData['category'] ?? '';
          bValue = bData['category'] ?? '';
          break;
        case 2: // Recyclable
          aValue = aData['is_recyclable'] ?? false;
          bValue = bData['is_recyclable'] ?? false;
          break;
        case 3: // Description
          aValue = aData['description'] ?? '';
          bValue = bData['description'] ?? '';
          break;
        default:
          return 0;
      }

      final comparison = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase());
      return _sortAscending ? comparison : -comparison;
    });

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Disposal Recommendations',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddRecommendationDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Recommendation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), // Primary Green
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(), // Pill Shape
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Table
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().getAllDisposalRecommendations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final recommendations = snapshot.data?.docs ?? [];

                if (recommendations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.recycling, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No disposal recommendations yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // REPLACED Card WITH Container
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20), // Eco-Modern Radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 40,
                        headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F9F6)), // Mint Header
                        columns: const [
                          DataColumn(label: Text('Waste Type', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Recyclable', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Dos', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Don'ts", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: recommendations.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final wasteType = doc.id;
                          final dos = List<String>.from(data['dos'] ?? []);
                          final donts = List<String>.from(data['donts'] ?? []);

                          return DataRow(cells: [
                            DataCell(SizedBox(width: 150, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _getCategoryColor(data['category'] ?? '').withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text(wasteType, style: TextStyle(fontWeight: FontWeight.bold, color: _getCategoryColor(data['category'] ?? '')), overflow: TextOverflow.ellipsis)))),
                            DataCell(SizedBox(width: 120, child: Text(data['category'] ?? 'N/A'))),
                            DataCell(SizedBox(width: 80, child: Icon(data['is_recyclable'] == true ? Icons.check_circle : Icons.cancel, color: data['is_recyclable'] == true ? Colors.green : Colors.red, size: 20))),
                            DataCell(SizedBox(width: 200, child: Tooltip(message: data['description'] ?? 'N/A', child: Text(data['description'] ?? 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis)))),
                            DataCell(SizedBox(width: 80, child: Text('${dos.length} items'))),
                            DataCell(SizedBox(width: 80, child: Text('${donts.length} items'))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blue),
                                    tooltip: 'View Details',
                                    onPressed: () => _showDetailsDialog(context, wasteType, data),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2E7D32)), // Green Edit
                                    tooltip: 'Edit',
                                    onPressed: () => _showEditRecommendationDialog(context, wasteType, data),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFD32F2F)), // Red Delete
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteRecommendation(context, wasteType),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return Colors.green;
      case 'hazardous':
        return Colors.red;
      case 'organic':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  void _showDetailsDialog(BuildContext context, String wasteType, Map<String, dynamic> data) {
    final dos = List<String>.from(data['dos'] ?? []);
    final donts = List<String>.from(data['donts'] ?? []);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        // Rounded shape for the dialog
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          // Keep the max height, but now content will scroll inside it
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. FIXED HEADER (Stays at the top)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    wasteType,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),

              // 2. SCROLLABLE CONTENT (Wraps everything else)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text('Description: ${data['description'] ?? 'N/A'}', style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 16),

                      // Dos Section
                      const Text('Dos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      ...dos.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      )),

                      const SizedBox(height: 20),

                      // Don'ts Section
                      const Text("Don'ts:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                      ...donts.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.close, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRecommendationDialog(BuildContext context) {
    // ... (Keep existing controllers) ...
    final wasteTypeController = TextEditingController();
    final descController = TextEditingController();
    final dosController = TextEditingController();
    final dontsController = TextEditingController();
    String selectedCategory = 'recyclable';
    bool isRecyclable = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Modern Shape
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1), // Green Tint
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.recycling, color: Color(0xFF2E7D32)), // Green Icon
              ),
              const SizedBox(width: 12),
              const Text('Add Disposal Recommendation', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 550,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... (Info Banner - Keep as is) ...

                  // Waste Type
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: wasteTypeController,
                      decoration: InputDecoration(
                        labelText: 'Waste Type *',
                        hintText: 'e.g., Plastic, Glass, Metal',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  // Category Dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: const Icon(Icons.label),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'recyclable', child: Text('Recyclable')),
                        DropdownMenuItem(value: 'non-recyclable', child: Text('Non-Recyclable')),
                        DropdownMenuItem(value: 'organic', child: Text('Organic')),
                        DropdownMenuItem(value: 'hazardous', child: Text('Hazardous')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                          isRecyclable = value == 'recyclable';
                        });
                      },
                    ),
                  ),

                  // Recyclable Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isRecyclable ? Icons.check_circle : Icons.cancel,
                          color: isRecyclable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        const Text('Is Recyclable', style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Switch(
                          value: isRecyclable,
                          onChanged: (value) => setState(() => isRecyclable = value),
                          activeColor: const Color(0xFF2E7D32), // Green Switch
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ... (Description, Dos, Donts - Apply same radius 12 to borders) ...
                  // Example for Description:
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Brief description of the waste type',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Dos & Donts (Keep logic, just update radius to 12 in InputDecorator)
                  // ...
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // ... (Keep existing Add Logic) ...
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Recommendation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // Primary Green
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Pill Shape
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRecommendationDialog(BuildContext context, String wasteType, Map<String, dynamic> data) {
    final descController = TextEditingController(text: data['description']);
    final dosController = TextEditingController(
      text: (data['dos'] as List?)?.join('\n') ?? '',
    );
    final dontsController = TextEditingController(
      text: (data['donts'] as List?)?.join('\n') ?? '',
    );
    String selectedCategory = data['category'] ?? 'recyclable';
    bool isRecyclable = data['is_recyclable'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.recycling, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 12),
              const Text('Add Disposal Recommendation', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 550,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'recyclable', child: Text('Recyclable')),
                      DropdownMenuItem(value: 'non-recyclable', child: Text('Non-Recyclable')),
                      DropdownMenuItem(value: 'organic', child: Text('Organic')),
                      DropdownMenuItem(value: 'hazardous', child: Text('Hazardous')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                        isRecyclable = value == 'recyclable';
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Recyclable Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isRecyclable ? Icons.check_circle : Icons.cancel,
                          color: isRecyclable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Is Recyclable',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Switch(
                          value: isRecyclable,
                          onChanged: (value) => setState(() => isRecyclable = value),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Dos Section
                  Text(
                    'Do\'s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dosController,
                    decoration: InputDecoration(
                      hintText: 'One instruction per line',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 80),
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),

                  // Don'ts Section
                  Text(
                    'Don\'ts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dontsController,
                    decoration: InputDecoration(
                      hintText: 'One instruction per line',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 80),
                        child: Icon(Icons.cancel, color: Colors.red),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final dos = dosController.text
                      .split('\n')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  final donts = dontsController.text
                      .split('\n')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

                  await FirestoreService().updateDisposalRecommendation(wasteType, {
                    'category': selectedCategory,
                    'is_recyclable': isRecyclable,
                    'description': descController.text.trim(),
                    'dos': dos,
                    'donts': donts,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Recommendation updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // <--- Change to Green
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // <--- Add Pill Shape
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecommendation(BuildContext context, String wasteType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recommendation'),
        content: Text('Are you sure you want to delete the recommendation for $wasteType?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirestoreService().deleteDisposalRecommendation(wasteType);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recommendation deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}