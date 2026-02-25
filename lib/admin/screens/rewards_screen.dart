import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

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
                    'Rewards Management',
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      Tab(text: 'Pending Claims'),
                      Tab(text: 'Manage Rewards'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PendingClaimsTab(),
                  _ManageRewardsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ==================== PENDING CLAIMS TAB ====================
class _PendingClaimsTab extends StatefulWidget {
  @override
  State<_PendingClaimsTab> createState() => _PendingClaimsTabState();
}

class _PendingClaimsTabState extends State<_PendingClaimsTab> {
  Set<String> _selectedIds = {};
  bool _isSelectAll = false;
  List<QueryDocumentSnapshot> _allClaims = [];

  void _toggleSelectAll() {
    setState(() {
      if (_isSelectAll) {
        _selectedIds.clear();
        _isSelectAll = false;
      } else {
        _selectedIds = _allClaims.map((doc) => doc.id).toSet();
        _isSelectAll = true;
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _isSelectAll = false;
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == _allClaims.length) _isSelectAll = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getPendingRewardClaims(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        _allClaims = snapshot.data?.docs ?? [];

        if (_allClaims.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No pending claims!', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Bulk Actions Header
              if (_selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedIds.length} claim(s) selected',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _selectedIds.clear();
                          _isSelectAll = false;
                        }),
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Selection'),
                      ),
                    ],
                  ),
                ),

              // Table
              Expanded(
                child: Container(
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
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              // Ensure table fills width
                              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                              child: DataTable(
                                columnSpacing: 30,
                                headingRowHeight: 50,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 60,
                                headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F9F6)),
                                columns: [
                                  DataColumn(
                                    label: Checkbox(
                                      value: _isSelectAll,
                                      onChanged: (value) => _toggleSelectAll(),
                                      activeColor: const Color(0xFF2E7D32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const DataColumn(label: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Reward ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _allClaims.map((doc) {
                                  // ... KEEP YOUR EXISTING DATA MAPPING LOGIC ...
                                  final data = doc.data() as Map<String, dynamic>;
                                  final claimId = doc.id;
                                  final userId = data['user_id'] ?? '';
                                  final rewardId = data['reward_id'] ?? '';
                                  final points = data['points_cost'] ?? 0;
                                  final claimDate = data['claim_date'] as Timestamp?;

                                  return DataRow(
                                    selected: _selectedIds.contains(claimId),
                                    cells: [
                                      DataCell(
                                        Checkbox(
                                          value: _selectedIds.contains(claimId),
                                          onChanged: (value) => _toggleSelection(claimId),
                                          activeColor: const Color(0xFF2E7D32),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      DataCell(Text(userId.length > 8 ? '${userId.substring(0, 8)}...' : userId)),
                                      DataCell(Text(rewardId.length > 8 ? '${rewardId.substring(0, 8)}...' : rewardId)),
                                      DataCell(Text('$points', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(
                                        claimDate != null ? '${claimDate.toDate().day}/${claimDate.toDate().month}/${claimDate.toDate().year}' : 'N/A',
                                      )),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 22),
                                              tooltip: 'Approve',
                                              onPressed: () => _fulfillClaim(context, claimId),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.highlight_off, color: Color(0xFFD32F2F), size: 22),
                                              tooltip: 'Reject',
                                              onPressed: () => _rejectClaim(context, claimId, points is int ? points : (points as num).toInt(), userId),
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fulfillClaim(BuildContext context, String claimId) async {
    try {
      await FirestoreService().fulfillRewardClaim(claimId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim fulfilled'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectClaim(BuildContext context, String claimId, int points, String userId) async {
    try {
      await FirestoreService().rejectRewardClaim(claimId, points, userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim rejected'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ==================== MANAGE REWARDS TAB ====================
class _ManageRewardsTab extends StatefulWidget {
  @override
  State<_ManageRewardsTab> createState() => _ManageRewardsTabState();
}

class _ManageRewardsTabState extends State<_ManageRewardsTab> {
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

  List<QueryDocumentSnapshot> _filterRewards(List<QueryDocumentSnapshot> rewards) {
    if (_searchQuery.isEmpty) return rewards;
    return rewards.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> rewards) {
    setState(() {
      if (_isSelectAll) {
        _selectedIds.clear();
        _isSelectAll = false;
      } else {
        _selectedIds = rewards.map((doc) => doc.id).toSet();
        _isSelectAll = true;
      }
    });
  }

  void _toggleSelection(String id, int totalRewards) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _isSelectAll = false;
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == totalRewards) _isSelectAll = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Add Button
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Container(
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
                      hintText: 'Search rewards...',
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
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddRewardDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Reward'),
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
        ),

        // Bulk Delete Banner
        if (_selectedIds.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
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
                  '${_selectedIds.length} reward(s) selected',
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
                  onPressed: () => _bulkDeleteRewards(context),
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
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getAllRewards(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allRewards = snapshot.data?.docs ?? [];
              final rewards = _filterRewards(allRewards);

              if (rewards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No rewards yet' : 'No rewards found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Pagination
              final totalPages = (rewards.length / _rowsPerPage).ceil();
              if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
              final startIndex = _currentPage * _rowsPerPage;
              final endIndex = (startIndex + _rowsPerPage).clamp(0, rewards.length);
              final paginatedRewards = rewards.sublist(startIndex, endIndex);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              // Exact same constraint as Pending Claims tab for consistency
                              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 96),
                              child: DataTable(
                                columnSpacing: 30,
                                headingRowHeight: 50,
                                dataRowMinHeight: 70, // Taller rows for Manage Rewards
                                dataRowMaxHeight: 70,
                                headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F9F6)),
                                columns: [
                                  DataColumn(
                                    label: Checkbox(
                                      value: _isSelectAll,
                                      onChanged: (value) => _toggleSelectAll(rewards),
                                      activeColor: const Color(0xFF2E7D32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  // ... KEEP YOUR COLUMNS ...
                                  const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: paginatedRewards.map((doc) {
                                  // ... KEEP YOUR EXISTING ROW MAPPING ...
                                  final data = doc.data() as Map<String, dynamic>;
                                  final rewardId = doc.id;

                                  return DataRow(
                                    selected: _selectedIds.contains(rewardId),
                                    cells: [
                                      DataCell(
                                        Checkbox(
                                          value: _selectedIds.contains(rewardId),
                                          onChanged: (value) => _toggleSelection(rewardId, rewards.length),
                                          activeColor: const Color(0xFF2E7D32),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      DataCell(Text(data['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(SizedBox(
                                        width: 180,
                                        child: Text(data['description'] ?? 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      )),
                                      DataCell(Text('${data['points_required'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text('${data['quantity_available'] ?? 0}')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: (data['status'] == 'active') ? Colors.green[50] : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(20), // Pill Shape
                                            border: Border.all(
                                                color: (data['status'] == 'active') ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.5)
                                            ),
                                          ),
                                          child: Text(
                                            (data['status'] ?? 'active').toString().toUpperCase(),
                                            style: TextStyle(
                                              color: (data['status'] == 'active') ? Colors.green[800] : Colors.grey[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2E7D32)),
                                              tooltip: 'Edit',
                                              onPressed: () => _showEditRewardDialog(context, rewardId, data),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFD32F2F)),
                                              tooltip: 'Delete',
                                              onPressed: () => _deleteReward(context, rewardId),
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
                      ),
                      // KEEP PAGINATION CONTAINER, BUT UPDATE COLOR TO GREEN
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${startIndex + 1}-$endIndex of ${rewards.length} rewards${_searchQuery.isNotEmpty ? " (filtered)" : ""}',
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
                                      color: const Color(0xFF2E7D32).withOpacity(0.1), // Green tint
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddRewardDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final pointsController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add New Reward'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'Title'),
                _buildTextField(descController, 'Description', maxLines: 2),
                _buildTextField(pointsController, 'Points Required', isNumber: true),
                _buildTextField(quantityController, 'Quantity', isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirestoreService().addReward({
                  'title': titleController.text,
                  'description': descController.text,
                  'points_required': int.parse(pointsController.text),
                  'quantity_available': int.parse(quantityController.text),
                  'status': 'active',
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reward added'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C44CC),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditRewardDialog(BuildContext context, String rewardId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final descController = TextEditingController(text: data['description']);
    final pointsController = TextEditingController(text: '${data['points_required']}');
    final quantityController = TextEditingController(text: '${data['quantity_available']}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Reward'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'Title'),
                _buildTextField(descController, 'Description', maxLines: 2),
                _buildTextField(pointsController, 'Points Required', isNumber: true),
                _buildTextField(quantityController, 'Quantity', isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirestoreService().updateReward(rewardId, {
                  'title': titleController.text,
                  'description': descController.text,
                  'points_required': int.parse(pointsController.text),
                  'quantity_available': int.parse(quantityController.text),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reward updated'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C44CC),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReward(BuildContext context, String rewardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reward'),
        content: const Text('Are you sure you want to delete this reward?'),
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
        await FirestoreService().deleteReward(rewardId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reward deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
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
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }



  Future<void> _bulkDeleteRewards(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Multiple Rewards'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} reward(s)? This action cannot be undone.'),
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
          await FirestoreService().deleteReward(id);
        }
        setState(() {
          _selectedIds.clear();
          _isSelectAll = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rewards deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}