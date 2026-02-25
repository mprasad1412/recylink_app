import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  Set<String> _selectedIds = {};
  bool _isSelectAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filterAndSortLocations(List<QueryDocumentSnapshot> locations) {
    var filtered = locations.where((doc) {
      if (_searchQuery.isEmpty) return true;
      final data = doc.data() as Map<String, dynamic>;
      final locationName = (data['location_name'] ?? '').toString().toLowerCase();
      final address = (data['address'] ?? '').toString().toLowerCase();
      final contact = (data['contact_num'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return locationName.contains(query) || address.contains(query) || contact.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      dynamic aValue, bValue;

      switch (_sortColumnIndex) {
        case 0: aValue = aData['location_name'] ?? ''; bValue = bData['location_name'] ?? ''; break;
        case 1: aValue = aData['address'] ?? ''; bValue = bData['address'] ?? ''; break;
        case 2: aValue = aData['contact_num'] ?? ''; bValue = bData['contact_num'] ?? ''; break;
        case 3: aValue = aData['operating_hours'] ?? ''; bValue = bData['operating_hours'] ?? ''; break;
        default: return 0;
      }
      final comparison = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase());
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> locations) {
    setState(() {
      if (_isSelectAll) {
        _selectedIds.clear();
        _isSelectAll = false;
      } else {
        _selectedIds = locations.map((doc) => doc.id).toSet();
        _isSelectAll = true;
      }
    });
  }

  void _toggleSelection(String id, int totalLocations) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _isSelectAll = false;
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == totalLocations) _isSelectAll = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6), // Mint Surface
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recycling Locations',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddLocationDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Location'),
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

            // Search Bar
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
                  hintText: 'Search locations...',
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
                onChanged: (val) => setState(() {
                  _searchQuery = val;
                  _currentPage = 0;
                }),
              ),
            ),
            const SizedBox(height: 16),

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
                      '${_selectedIds.length} location(s) selected',
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
                      onPressed: () => _bulkDeleteLocations(context),
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

            // Table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService().getAllLocations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allLocations = snapshot.data?.docs ?? [];
                  final locations = _filterAndSortLocations(allLocations);

                  if (locations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No locations yet' : 'No locations found',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Pagination
                  final totalPages = (locations.length / _rowsPerPage).ceil();
                  if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
                  final startIndex = _currentPage * _rowsPerPage;
                  final endIndex = (startIndex + _rowsPerPage).clamp(0, locations.length);
                  final paginated = locations.sublist(startIndex, endIndex);

                  // REPLACE THE ENTIRE 'return Container(...)' BLOCK WITH THIS:
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          // 1. ADD LayoutBuilder to get the available width
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  // 2. ADD ConstrainedBox to force minimum width
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: DataTable(
                                      columnSpacing: 40,
                                      headingRowHeight: 50,
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 60,
                                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F9F6)),
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _sortAscending,
                                      columns: [
                                        DataColumn(
                                          label: Checkbox(
                                            value: _isSelectAll,
                                            onChanged: (value) => _toggleSelectAll(locations),
                                            activeColor: const Color(0xFF2E7D32),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                        ),
                                        DataColumn(
                                          label: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) {
                                            setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; });
                                          },
                                        ),
                                        DataColumn(
                                          label: const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) {
                                            setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; });
                                          },
                                        ),
                                        DataColumn(
                                          label: const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) {
                                            setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; });
                                          },
                                        ),
                                        DataColumn(
                                          label: const Text('Hours', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) {
                                            setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; });
                                          },
                                        ),
                                        const DataColumn(
                                          label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                      rows: paginated.map((doc) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        final locationId = doc.id;

                                        return DataRow(
                                          selected: _selectedIds.contains(locationId),
                                          cells: [
                                            DataCell(
                                              Checkbox(
                                                value: _selectedIds.contains(locationId),
                                                onChanged: (value) => _toggleSelection(locationId, locations.length),
                                                activeColor: const Color(0xFF2E7D32),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              ),
                                            ),
                                            // 3. REMOVED ConstrainedBox from cells to let them flex naturally
                                            //    or keep them if you specifically want to truncate text.
                                            //    Here I kept them but ensured the table itself is full width.
                                            DataCell(SizedBox(
                                                width: 150,
                                                child: Text(data['location_name'] ?? 'N/A', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))
                                            )),
                                            DataCell(SizedBox(
                                                width: 200,
                                                child: Text(data['address'] ?? 'N/A', overflow: TextOverflow.ellipsis)
                                            )),
                                            DataCell(Text(data['contact_num']?.toString() ?? '-')),
                                            DataCell(Text(data['operating_hours'] ?? 'N/A')),
                                            DataCell(Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF2E7D32), size: 20),
                                                  tooltip: 'Edit',
                                                  onPressed: () => _showEditLocationDialog(context, locationId, data),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 20),
                                                  tooltip: 'Delete',
                                                  onPressed: () => _deleteLocation(context, locationId),
                                                ),
                                              ],
                                            )),
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
                        // ... (Keep Pagination Container Code same as before)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${startIndex + 1}-$endIndex of ${locations.length} locations${_searchQuery.isNotEmpty ? " (filtered)" : ""}',
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
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final contactController = TextEditingController();
    final hoursController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add New Location'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, 'Location Name'),
                _buildTextField(addressController, 'Address', maxLines: 2),
                _buildTextField(
                  contactController,
                  'Contact Number (optional)',
                  hintText: 'e.g., 03-898989 or 0123456789',
                ),
                _buildTextField(
                  hoursController,
                  'Operating Hours',
                  hintText: 'e.g., Mon-Fri 9AM-5PM',
                ),
                _buildTextField(descController, 'Description', maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () async {
              try {
                String? contactNum;
                if (contactController.text.trim().isNotEmpty) {
                  contactNum = contactController.text.trim();
                }

                await FirestoreService().addLocation({
                  'location_name': nameController.text,
                  'address': addressController.text,
                  'contact_num': contactNum,
                  'operating_hours': hoursController.text,
                  'description': descController.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location added'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, String locationId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['location_name']);
    final addressController = TextEditingController(text: data['address']);
    final contactController = TextEditingController(
      text: (data['contact_num'] != null && data['contact_num'] != 0 && data['contact_num'].toString().isNotEmpty)
          ? data['contact_num'].toString()
          : '',
    );
    final hoursController = TextEditingController(text: data['operating_hours']);
    final descController = TextEditingController(text: data['description']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Location'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, 'Location Name'),
                _buildTextField(addressController, 'Address', maxLines: 2),
                _buildTextField(
                  contactController,
                  'Contact Number (optional)',
                  hintText: 'e.g., 03-898989 or 0123456789',
                ),
                _buildTextField(
                  hoursController,
                  'Operating Hours',
                  hintText: 'e.g., Mon-Fri 9AM-5PM',
                ),
                _buildTextField(descController, 'Description', maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () async {
              try {
                String? contactNum;
                if (contactController.text.trim().isNotEmpty) {
                  contactNum = contactController.text.trim();
                }

                await FirestoreService().updateLocation(locationId, {
                  'location_name': nameController.text,
                  'address': addressController.text,
                  'contact_num': contactNum,
                  'operating_hours': hoursController.text,
                  'description': descController.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location updated'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(BuildContext context, String locationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: const Text('Are you sure you want to delete this location?'),
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
        await FirestoreService().deleteLocation(locationId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _bulkDeleteLocations(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Multiple Locations'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} location(s)? This action cannot be undone.'),
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
          await FirestoreService().deleteLocation(id);
        }
        setState(() {
          _selectedIds.clear();
          _isSelectAll = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Locations deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, String? hintText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // Increased spacing
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2), // Green Focus
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}