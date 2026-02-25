import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedFilter = 'all';
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedIds = {};
  bool _isSelectAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Marketplace Items',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Filters & Search
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All', 'all', Colors.grey),
                      _buildFilterChip('Pending', 'pending', Colors.orange),
                      _buildFilterChip('Approved', 'approved', Colors.green),
                      _buildFilterChip('Rejected', 'rejected', Colors.red),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30), // Pill shape
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
                        hintText: 'Search items...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
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
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bulk Delete Banner
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedIds.length} item(s) selected',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red[900]),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() {
                            _selectedIds.clear();
                            _isSelectAll = false;
                          }),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),

            // Table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var allItems = snapshot.data?.docs ?? [];

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    allItems = allItems.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '')
                          .toString()
                          .toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      return title.contains(query);
                    }).toList();
                  }

                  if (allItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedFilter == 'pending'
                                ? Icons.check_circle
                                : Icons.inbox,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty ? 'No items found' :
                            _selectedFilter == 'pending'
                                ? 'No pending items!'
                                : 'No items found',
                            style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Pagination
                  final totalPages = (allItems.length / _rowsPerPage).ceil();
                  if (_currentPage >= totalPages && totalPages > 0)
                    _currentPage = totalPages - 1;
                  final startIndex = _currentPage * _rowsPerPage;
                  final endIndex = (startIndex + _rowsPerPage).clamp(
                      0, allItems.length);
                  final paginatedItems = allItems.sublist(startIndex, endIndex);

                  // REPLACE THE 'return Card(...)' BLOCK WITH:
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: DataTable(
                                      columnSpacing: 30,
                                      horizontalMargin: 24,
                                      headingRowHeight: 50,
                                      dataRowMinHeight: 70, // More breathing room for images
                                      dataRowMaxHeight: 70,
                                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F9F6)), // Mint header
                                      columns: [
                                        DataColumn(
                                          label: Checkbox(
                                            value: _isSelectAll,
                                            onChanged: (value) => _toggleSelectAll(allItems),
                                            activeColor: const Color(0xFF2E7D32),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                        ),
                                        // ... (KEEP YOUR EXISTING COLUMNS - Title, Seller, etc.)
                                        // JUST COPY THE EXISTING 'DataColumn' LINES HERE
                                        const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                                        const DataColumn(label: Text('Seller', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                                        const DataColumn(label: Text('Price (RM)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                                        const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                                        const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                                        const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                                      ],
                                      rows: paginatedItems.map((doc) {
                                        // ... (KEEP YOUR EXISTING ROW MAPPING LOGIC)
                                        // Just ensure the Checkbox uses activeColor: const Color(0xFF2E7D32)

                                        // I'm abbreviating here to save space, but you should copy
                                        // your existing 'final data = ...' logic and return DataRow(...)
                                        final data = doc.data() as Map<String, dynamic>;
                                        final itemId = doc.id;
                                        final status = data['approval_status'] ?? 'pending';

                                        return DataRow(
                                          selected: _selectedIds.contains(itemId),
                                          cells: [
                                            DataCell(
                                              Checkbox(
                                                value: _selectedIds.contains(itemId),
                                                onChanged: (value) => _toggleSelection(itemId, allItems.length),
                                                activeColor: const Color(0xFF2E7D32),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              ),
                                            ),
                                            // ... COPY YOUR EXISTING DataCells for Title, Seller, Price, Status, Date, Actions
                                            DataCell(SizedBox(
                                              width: 180,
                                              child: Tooltip(
                                                message: data['title'] ?? 'N/A',
                                                child: Text(data['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                              ),
                                            )),
                                            // Paste your existing User FutureBuilder DataCell here
                                            DataCell(
                                              FutureBuilder<DocumentSnapshot>(
                                                future: FirebaseFirestore.instance.collection('users').doc(data['user_id']).get(),
                                                builder: (context, userSnapshot) {
                                                  if (userSnapshot.connectionState == ConnectionState.waiting) return const Text('Loading...', style: TextStyle(color: Colors.grey));
                                                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const Text('Unknown', style: TextStyle(color: Colors.grey));
                                                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                                  return Text(userData?['username'] ?? 'Unknown');
                                                },
                                              ),
                                            ),
                                            DataCell(Text(_formatPrice(data['price']), style: const TextStyle(fontFamily: 'Monospace', fontSize: 13))),
                                            DataCell(_buildStatusChip(status)),
                                            DataCell(Text(_formatDate(data['post_date']), style: TextStyle(color: Colors.grey[600]))),
                                            DataCell(_buildActionButtons(context, status, itemId, data)),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // ... (KEEP YOUR PAGINATION FOOTER LOGIC, JUST REMOVE BORDER)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            // No border needed at top, looks cleaner
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${startIndex + 1}-$endIndex of ${allItems.length} items${_searchQuery.isNotEmpty ? " (filtered)" : ""}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              if (totalPages > 0)
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                      icon: const Icon(Icons.chevron_left),
                                      padding: EdgeInsets.zero,
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32).withOpacity(0.1), // Primary Green tint
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Page ${_currentPage + 1} of $totalPages',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                                      icon: const Icon(Icons.chevron_right),
                                      padding: EdgeInsets.zero,
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
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, MaterialColor color) {
    final isSelected = _selectedFilter == value;
    // Use Primary Green for 'All', otherwise use the specific color (orange/green/red)
    final Color activeColor = value == 'all' ? const Color(0xFF2E7D32) : color;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() {
        _selectedFilter = value;
        _currentPage = 0;
        _selectedIds.clear();
        _isSelectAll = false;
      }),
      backgroundColor: Colors.white,
      selectedColor: activeColor.withOpacity(0.1),
      checkmarkColor: activeColor,
      labelStyle: TextStyle(
        color: isSelected ? activeColor : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      elevation: 0,
      pressElevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? activeColor : Colors.grey.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(30), // Pill shape
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null || price == 0) {
      return 'Free';
    }
    return 'RM ${price}';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    final collection = FirebaseFirestore.instance.collection('items');
    if (_selectedFilter == 'all') {
      return collection.orderBy('post_date', descending: true).snapshots();
    } else {
      return collection
          .where('approval_status', isEqualTo: _selectedFilter)
          .orderBy('post_date', descending: true)
          .snapshots();
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'approved':
        color = const Color(0xFF2E7D32); // Primary Green
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = const Color(0xFFD32F2F); // Error Red
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        icon = Icons.access_time_filled; // Better icon
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status, String itemId,
      Map<String, dynamic> data) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Details Button (Always visible)
        IconButton(
          icon: const Icon(
              Icons.visibility, color: Color(0xFF4C44CC), size: 20),
          tooltip: 'View Details',
          onPressed: () => _showItemDetailsDialog(context, itemId, data),
        ),

        // Approve/Reject buttons only for pending items
        if (status == 'pending') ...[
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green, size: 20),
            tooltip: 'Approve',
            onPressed: () =>
                _approveItem(
                  context,
                  itemId,
                  data['user_id'],
                  data['price'] is int ? data['price'] : (data['price'] as num)
                      .toInt(),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            tooltip: 'Reject',
            onPressed: () => _rejectItem(context, itemId),
          ),
        ],
      ],
    );
  }

  //  VIEW ITEM DETAILS DIALOG
  void _showItemDetailsDialog(BuildContext context, String itemId,
      Map<String, dynamic> data) {
    final double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final double dialogWidth = screenWidth > 800 ? 800 : screenWidth * 0.95;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Modern Curve
        insetPadding: const EdgeInsets.all(16),
        child: Container(
              width: dialogWidth,
              constraints: const BoxConstraints(maxHeight: 700),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Item Details',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image with click to enlarge
                          if (data['images'] != null)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) =>
                                      Dialog(
                                        child: Stack(
                                          children: [
                                            InteractiveViewer(
                                              child: Image.network(
                                                  data['images']),
                                            ),
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.white,
                                                    size: 30),
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                style: IconButton.styleFrom(
                                                  backgroundColor: Colors
                                                      .black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                );
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      data['images'],
                                      height: 250,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        return Container(
                                          height: 250,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                                Icons.broken_image, size: 64,
                                                color: Colors.grey),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in,
                                              color: Colors.white, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            'Click to enlarge',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                    Icons.image, size: 64, color: Colors.grey),
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Title
                          _buildDetailRow('Title', data['title'] ?? 'N/A'),
                          const SizedBox(height: 12),

                          // Description
                          _buildDetailRow(
                              'Description', data['description'] ?? 'N/A'),
                          const SizedBox(height: 12),

                          // Price
                          _buildDetailRow('Price', _formatPrice(data['price'])),
                          const SizedBox(height: 12),

                          // Contact Info
                          _buildDetailRow(
                              'Contact Info', data['contact_info'] ?? 'N/A'),
                          const SizedBox(height: 12),

                          // Seller Info
                          // Seller Info
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(data['user_id'])
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return _buildDetailRow('Seller', 'Loading...');
                              }
                              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                return _buildDetailRow('Seller', 'Unknown User');
                              }
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                              final userName = userData?['username'] ?? 'Unknown';
                              final userEmail = userData?['email'] ?? '';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Seller', userName),
                                  if (userEmail.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Email: $userEmail',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Post Date
                          _buildDetailRow(
                              'Posted On', _formatDate(data['post_date'])),
                          const SizedBox(height: 12),

                          // Status Badge
                          Row(
                            children: [
                              const Text(
                                'Status: ',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              _buildStatusChip(data['approval_status'] ??
                                  'pending'),
                            ],
                          ),

                          // Rejection Reason (if rejected)
                          if (data['approval_status'] == 'rejected' &&
                              data['rejection_reason'] != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 20,
                                      color: Colors.red[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          'Rejection Reason:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[900],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['rejection_reason'],
                                          style: TextStyle(fontSize: 13,
                                              color: Colors.red[800]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ],
    );
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> items) {
    setState(() {
      if (_isSelectAll) {
        _selectedIds.clear();
        _isSelectAll = false;
      } else {
        _selectedIds = items.map((doc) => doc.id).toSet();
        _isSelectAll = true;
      }
    });
  }

  void _toggleSelection(String id, int totalItems) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _isSelectAll = false;
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == totalItems) _isSelectAll = true;
      }
    });
  }

  Future<void> _approveItem(BuildContext context, String itemId, String userId,
      int points) async {
    try {
      await FirestoreService().approveItem(itemId, userId, points);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectItem(BuildContext context, String itemId) async {
    String? selectedReason;
    final customReasonController = TextEditingController();

    final List<String> predefinedReasons = [
      'Image quality is too low or unclear',
      'Inappropriate or irrelevant content',
      'Item does not qualify as upcycled',
      'Missing or incomplete information',
      'Other (please specify)',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reject Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure you want to reject this item?'),
                const SizedBox(height: 16),
                const Text(
                  'Reason for rejection:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select a reason'),
                      value: selectedReason,
                      items: predefinedReasons.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(reason, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedReason = value;
                        });
                      },
                    ),
                  ),
                ),
                if (selectedReason == 'Other (please specify)') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      labelText: 'Specify reason',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedReason != null) {
      try {
        final finalReason = selectedReason == 'Other (please specify)'
            ? customReasonController.text.trim()
            : selectedReason!;

        if (finalReason.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please provide a rejection reason'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        await FirestoreService().rejectItem(itemId, finalReason);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item rejected'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        customReasonController.dispose();
      }
    } else {
      customReasonController.dispose();
    }
  }
}
