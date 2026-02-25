import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isMaintenanceMode = false;
  bool _isLoadingMaintenance = true;
  Set<String> _selectedUserIds = {};
  bool _isSelectAll = false;
  List<QueryDocumentSnapshot> _allUsers = [];

  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceStatus();
    _statsFuture = FirestoreService().getDashboardStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = FirestoreService().getDashboardStats();
    });
  }

  Future<void> _loadMaintenanceStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('ai_detection')
          .get();

      if (doc.exists) {
        if (mounted) {
          setState(() {
            _isMaintenanceMode = doc.data()?['maintenance_mode'] ?? false;
            _isLoadingMaintenance = false;
          });
        }
      } else {
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('ai_detection')
            .set({'maintenance_mode': false});
        if (mounted) {
          setState(() {
            _isMaintenanceMode = false;
            _isLoadingMaintenance = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMaintenance = false;
        });
      }
    }
  }

  Future<void> _toggleMaintenanceMode() async {
    try {
      final newValue = !_isMaintenanceMode;
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('ai_detection')
          .set({'maintenance_mode': newValue});

      setState(() {
        _isMaintenanceMode = newValue;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue
                  ? '🔧 AI Detection is now in maintenance mode'
                  : '✅ AI Detection is now active',
            ),
            backgroundColor: newValue ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isSelectAll) {
        _selectedUserIds.clear();
        _isSelectAll = false;
      } else {
        _selectedUserIds = _allUsers.map((doc) => doc.id).toSet();
        _isSelectAll = true;
      }
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
        _isSelectAll = false;
      } else {
        _selectedUserIds.add(userId);
        if (_selectedUserIds.length == _allUsers.length) {
          _isSelectAll = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMaintenanceToggle(),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      _buildMaintenanceToggle(),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 8),
            Text(
              _isMaintenanceMode
                  ? '⚠️ Users will see a maintenance message when trying to use AI detection'
                  : 'AI detection is working normally',
              style: TextStyle(
                fontSize: 14,
                color: _isMaintenanceMode ? Colors.orange.shade700 : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards Grid
            FutureBuilder<Map<String, int>>(
              future: _statsFuture, // 3. USE THE VARIABLE HERE
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {};

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 4;
                    if (constraints.maxWidth < 1200) crossAxisCount = 3;
                    if (constraints.maxWidth < 800) crossAxisCount = 2;
                    if (constraints.maxWidth < 500) crossAxisCount = 1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth < 500 ? 2.5 : 1.5,
                      children: [
                        _StatCard(title: 'Pending Items', value: '${stats['pending_items'] ?? 0}', icon: Icons.shopping_bag, color: Colors.orange),
                        _StatCard(title: 'Pending Claims', value: '${stats['pending_claims'] ?? 0}', icon: Icons.card_giftcard, color: Colors.blue),
                        _StatCard(title: 'Total Users', value: '${stats['total_users'] ?? 0}', icon: Icons.people, color: Colors.green),
                        _StatCard(title: 'Total Locations', value: '${stats['total_locations'] ?? 0}', icon: Icons.location_on, color: Colors.red),
                        _StatCard(title: 'AI Detections', value: '${stats['total_detections'] ?? 0}', icon: Icons.eco, color: Colors.teal),
                        _StatCard(title: 'Pending Feedback', value: '${stats['pending_feedback'] ?? 0}', icon: Icons.feedback, color: Colors.purple),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // User Management Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_selectedUserIds.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _deleteSelectedUsers(context),
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text('Delete ${_selectedUserIds.length} user(s)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F), // Error Red
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(), // Pill Shape
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Users Table
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(64),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                _allUsers = snapshot.data?.docs ?? [];

                if (_allUsers.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: Colors.white,
                    child: const Padding(
                      padding: EdgeInsets.all(64),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No users yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Mobile: Card-based layout
                    if (constraints.maxWidth < 600) {
                      return ListView.builder(
                        // ... (Mobile view remains the same)
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _allUsers.length,
                        itemBuilder: (context, index) {
                          final doc = _allUsers[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final joinDate = data['join_date'] as Timestamp?;
                          final userId = doc.id;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _selectedUserIds.contains(userId),
                                        onChanged: (value) => _toggleUserSelection(userId),
                                      ),
                                      Expanded(
                                        child: Text(
                                          data['username'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: data['role'] == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          data['role'] ?? 'user',
                                          style: TextStyle(
                                            color: data['role'] == 'admin' ? Colors.red.shade900 : Colors.blue.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildUserDetailRow(Icons.email, data['email'] ?? 'N/A'),
                                  _buildUserDetailRow(Icons.phone, data['phone_number'] ?? 'N/A'),
                                  _buildUserDetailRow(Icons.stars, '${data['points_balance'] ?? 0} points'),
                                  _buildUserDetailRow(
                                    Icons.calendar_today,
                                    joinDate != null
                                        ? '${joinDate.toDate().day}/${joinDate.toDate().month}/${joinDate.toDate().year}'
                                        : 'N/A',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }

                    // Desktop: Table with LayoutBuilder & ConstrainedBox (Full Width Fix)
                    // Desktop: Table with LayoutBuilder & ConstrainedBox (Full Width Fix)
                    // REPLACING THE 'Card' WIDGET HERE:
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
                      clipBehavior: Clip.antiAlias, // Ensures content respects rounded corners
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  columnSpacing: 40,
                                  headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                                  dataRowMinHeight: 60, // Give rows more breathing room
                                  dataRowMaxHeight: 60,
                                  columns: [
                                    // ... (Keep your existing columns code same as before) ...
                                    DataColumn(
                                      label: Checkbox(
                                        value: _isSelectAll,
                                        onChanged: (value) => _toggleSelectAll(),
                                        activeColor: const Color(0xFF2E7D32), // Primary Green
                                      ),
                                    ),
                                    const DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Join Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _allUsers.map((doc) {
                                    // ... (Keep your existing row mapping logic) ...
                                    // Just update the Checkbox activeColor inside the row:
                                    // activeColor: const Color(0xFF2E7D32),

                                    // For brevity, I am not repeating the whole map logic,
                                    // just wrap your existing DataTable content in this new Container
                                    final data = doc.data() as Map<String, dynamic>;
                                    final joinDate = data['join_date'] as Timestamp?;
                                    final userId = doc.id;

                                    return DataRow(
                                        selected: _selectedUserIds.contains(userId),
                                        cells: [
                                          DataCell(
                                            Checkbox(
                                              value: _selectedUserIds.contains(userId),
                                              onChanged: (value) => _toggleUserSelection(userId),
                                              activeColor: const Color(0xFF2E7D32),
                                            ),
                                          ),
                                          DataCell(Text(data['username'] ?? 'N/A')),
                                          DataCell(Text(data['email'] ?? 'N/A')),
                                          DataCell(Text('${data['points_balance'] ?? 0}')),
                                          DataCell(Text(data['phone_number'] ?? 'N/A')),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: data['role'] == 'admin' ? Colors.red.shade50 : Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(20), // Pill tags
                                              ),
                                              child: Text(
                                                data['role'] ?? 'user',
                                                style: TextStyle(
                                                  color: data['role'] == 'admin' ? Colors.red.shade900 : Colors.blue.shade900,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              joinDate != null
                                                  ? '${joinDate.toDate().day}/${joinDate.toDate().month}/${joinDate.toDate().year}'
                                                  : 'N/A',
                                            ),
                                          ),
                                        ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMaintenanceToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isMaintenanceMode ? Colors.orange.shade50 : const Color(0xFFE8F5E9), // Soft Green
        borderRadius: BorderRadius.circular(30), // Pill shape
        border: Border.all(
          color: _isMaintenanceMode ? Colors.orange.shade200 : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isMaintenanceMode ? Icons.construction : Icons.check_circle,
            color: _isMaintenanceMode ? Colors.orange : const Color(0xFF2E7D32),
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isMaintenanceMode ? "Maintenance" : "Active",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isMaintenanceMode ? Colors.orange.shade900 : const Color(0xFF2E7D32),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _isLoadingMaintenance
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : SizedBox(
            height: 24,
            child: Switch(
              value: _isMaintenanceMode,
              onChanged: (value) => _toggleMaintenanceMode(),
              activeColor: Colors.orange,
              activeTrackColor: Colors.orange.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedUsers(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Users'),
        content: Text('Are you sure you want to delete ${_selectedUserIds.length} user(s)? This action cannot be undone.'),
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
        await FirestoreService().deleteUsers(_selectedUserIds.toList());
        setState(() {
          _selectedUserIds.clear();
          _isSelectAll = false;
        });
        _refreshStats();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Users deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(20), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Icon with subtle circle background
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}