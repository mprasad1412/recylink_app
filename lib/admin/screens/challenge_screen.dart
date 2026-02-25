import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedIds = {};
  bool _isSelectAll = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filterAndSortChallenges(List<QueryDocumentSnapshot> challenges) {
    // Filter by search
    var filtered = challenges.where((doc) {
      if (_searchQuery.isEmpty) return true;
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();

    // Sort
    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      dynamic aValue, bValue;

      switch (_sortColumnIndex) {
        case 0: aValue = aData['title'] ?? ''; bValue = bData['title'] ?? ''; break;
        case 1: aValue = aData['target_count'] ?? 0; bValue = bData['target_count'] ?? 0; break;
        case 2: aValue = aData['points_reward'] ?? 0; bValue = bData['points_reward'] ?? 0; break;
        case 3: aValue = aData['status'] ?? ''; bValue = bData['status'] ?? ''; break;
        case 4: aValue = aData['start_date']; bValue = bData['start_date']; break;
        case 5: aValue = aData['participants_count'] ?? 0; bValue = bData['participants_count'] ?? 0; break;
        default: return 0;
      }
      final comparison = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase());
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> challenges) {
    setState(() {
      if (_isSelectAll) {
        _selectedIds.clear();
        _isSelectAll = false;
      } else {
        _selectedIds = challenges.map((doc) => doc.id).toSet();
        _isSelectAll = true;
      }
    });
  }

  void _toggleSelection(String id, int totalChallenges) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _isSelectAll = false;
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == totalChallenges) _isSelectAll = true;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Challenges Management',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddChallengeDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Challenge'),
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
                  hintText: 'Search challenges...',
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
                      '${_selectedIds.length} challenge(s) selected',
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
                      onPressed: () => _bulkDeleteChallenges(context),
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

            // Table with Pagination
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService().getAllChallenges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allChallenges = snapshot.data?.docs ?? [];
                  final challenges = _filterAndSortChallenges(allChallenges);

                  if (challenges.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.emoji_events : Icons.search_off,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No challenges yet' : 'No challenges found',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Pagination
                  final totalPages = (challenges.length / _rowsPerPage).ceil();
                  if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
                  final startIndex = _currentPage * _rowsPerPage;
                  final endIndex = (startIndex + _rowsPerPage).clamp(0, challenges.length);
                  final paginatedChallenges = challenges.sublist(startIndex, endIndex);

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
                                      headingRowHeight: 50,
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 60,
                                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F9F6)), // Mint Header
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _sortAscending,
                                      columns: [
                                        DataColumn(
                                          label: Checkbox(
                                            value: _isSelectAll,
                                            onChanged: (value) => _toggleSelectAll(challenges),
                                            activeColor: const Color(0xFF2E7D32), // Green Checkbox
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                        ),
                                        // ... KEEP YOUR EXISTING COLUMNS Logic ...
                                        DataColumn(
                                          label: const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) => setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; }),
                                        ),
                                        DataColumn(
                                          label: const Text('Target', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) => setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; }),
                                        ),
                                        DataColumn(
                                          label: const Text('Reward', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) => setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; }),
                                        ),
                                        DataColumn(
                                          label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) => setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; }),
                                        ),
                                        DataColumn(
                                          label: const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) => setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; }),
                                        ),
                                        DataColumn(
                                          label: const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onSort: (columnIndex, ascending) => setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; }),
                                        ),
                                        const DataColumn(
                                          label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                      rows: paginatedChallenges.map((doc) {
                                        // ... KEEP YOUR EXISTING ROW MAPPING ...
                                        final data = doc.data() as Map<String, dynamic>;
                                        final challengeId = doc.id;
                                        final startDate = data['start_date'] as Timestamp?;

                                        return DataRow(
                                          selected: _selectedIds.contains(challengeId),
                                          cells: [
                                            DataCell(
                                              Checkbox(
                                                value: _selectedIds.contains(challengeId),
                                                onChanged: (value) => _toggleSelection(challengeId, challenges.length),
                                                activeColor: const Color(0xFF2E7D32),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              ),
                                            ),
                                            DataCell(SizedBox(
                                              width: 180,
                                              child: Tooltip(
                                                message: data['title'] ?? 'N/A',
                                                child: Text(data['title'] ?? 'N/A', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                                              ),
                                            )),
                                            DataCell(Text('${data['target_count'] ?? 1}')),
                                            DataCell(Text('${data['points_reward'] ?? 0} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: (data['status'] == 'active') ? Colors.green[50] : Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(20), // Pill Shape
                                                  border: Border.all(color: (data['status'] == 'active') ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.5)),
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
                                            DataCell(Text(startDate != null ? '${startDate.toDate().day}/${startDate.toDate().month}/${startDate.toDate().year}' : 'N/A')),
                                            DataCell(Text('${data['participants_count'] ?? 0}')),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.photo_library_outlined, size: 20, color: Colors.blue),
                                                    tooltip: 'View Submissions',
                                                    onPressed: () => _showSubmissionsDialog(context, challengeId, data['title'] ?? 'Challenge'),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2E7D32)),
                                                    tooltip: 'Edit',
                                                    onPressed: () => _showEditChallengeDialog(context, challengeId, data),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFD32F2F)),
                                                    tooltip: 'Delete',
                                                    onPressed: () => _deleteChallenge(context, challengeId),
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
                              );
                            },
                          ),
                        ),
                        // Pagination Controls (Modernized)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${startIndex + 1}-$endIndex of ${challenges.length} challenges',
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


  void _showAddChallengeDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final pointsController = TextEditingController();
    final targetCountController = TextEditingController(text: '1');
    final daysController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Modern Shape
        title: const Text('Add New Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'Title'),
                _buildTextField(descController, 'Description', maxLines: 3),
                _buildTextField(targetCountController, 'Target Count', isNumber: true, hint: 'e.g. 5'),
                _buildTextField(pointsController, 'Points Reward', isNumber: true),
                _buildTextField(daysController, 'Duration (days)', isNumber: true),
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
            onPressed: () async {
              try {
                final endDate = DateTime.now().add(
                  Duration(days: int.parse(daysController.text)),
                );

                await FirestoreService().addChallenge({
                  'title': titleController.text,
                  'description': descController.text,
                  'target_count': int.parse(targetCountController.text),
                  'points_reward': int.parse(pointsController.text),
                  'start_date': Timestamp.now(),
                  'end_date': Timestamp.fromDate(endDate),
                  'status': 'active',
                  'participants_count': 0,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Challenge added')),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), // Primary Green
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditChallengeDialog(BuildContext context, String challengeId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final descController = TextEditingController(text: data['description']);
    final targetCountController = TextEditingController(text: '${data['target_count'] ?? 1}');
    final pointsController = TextEditingController(text: '${data['points_reward']}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Challenge'),
    content: SingleChildScrollView(
    child: SizedBox(
    width: 400,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    _buildTextField(titleController, 'Title'),
    _buildTextField(descController, 'Description', maxLines: 3),
    _buildTextField(targetCountController, 'Target Count', isNumber: true),
    _buildTextField(pointsController, 'Points Reward', isNumber: true),
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
                await FirestoreService().updateChallenge(challengeId, {
                  'title': titleController.text,
                  'description': descController.text,
                  'target_count': int.parse(targetCountController.text),
                  'points_reward': int.parse(pointsController.text),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Challenge updated')),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              // 3. FIX: Add Pill Shape
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool isNumber = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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

  //  VIEW SUBMISSIONS DIALOG
  void _showSubmissionsDialog(BuildContext context, String challengeId, String challengeTitle) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth > 900 ? 900 : screenWidth * 0.95;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: dialogWidth,
          height: 700,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Submissions: $challengeTitle',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService().getChallengeSubmissions(challengeId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userChallenges = snapshot.data?.docs ?? [];

                    if (userChallenges.isEmpty) {
                      return const Center(child: Text('No submissions yet'));
                    }

                    return ListView.builder(
                      itemCount: userChallenges.length,
                      itemBuilder: (context, index) {
                        final doc = userChallenges[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final submissions = data['submissions'] as List<dynamic>? ?? [];
                        final userId = data['user_id'];
                        final status = data['status'];
                        final progress = data['current_progress'] ?? 0;
                        final target = data['target_count'] ?? 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              // NEW CODE (Safe Check)
                              title: FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                                builder: (context, userSnapshot) {
                                  // 1. Check if waiting
                                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Text('Loading user...', style: TextStyle(color: Colors.grey, fontSize: 12));
                                  }

                                  // 2. Check if data exists
                                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                    return Text('Unknown User ($userId)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey));
                                  }

                                  // 3. Safe data access
                                  final data = userSnapshot.data!.data() as Map<String, dynamic>;
                                  final userName = data['username'] ?? 'User $userId';
                                  final userEmail = data['email'] ?? '';

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (userEmail.isNotEmpty)
                                        Text(userEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  );
                                },
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Progress: $progress/$target'),
                                  Text(
                                    'Status: ${status.toUpperCase()}',
                                    style: TextStyle(
                                      color: status == 'completed'
                                          ? Colors.green
                                          : status == 'pending_review'
                                          ? Colors.orange
                                          : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              children: submissions.isEmpty
                                  ? [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No submissions yet', style: TextStyle(color: Colors.grey)),
                                )
                              ]
                                  : submissions.map<Widget>((submission) {
                                final submissionData = submission as Map<String, dynamic>;
                                final photoUrl = submissionData['photo_url'];
                                final submittedAt = submissionData['submitted_at'] as Timestamp?;
                                final submissionStatus = submissionData['status'] ?? 'pending';
                                final submissionId = submissionData['submission_id'];
                                final adminNotes = submissionData['admin_notes'] ?? '';

                                return Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Submission ID: $submissionId',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  'Submitted: ${submittedAt?.toDate().toString() ?? "N/A"}',
                                                  style:
                                                  TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: submissionStatus == 'approved'
                                                        ? Colors.green[100]
                                                        : submissionStatus == 'rejected'
                                                        ? Colors.red[100]
                                                        : Colors.orange[100],
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    submissionStatus.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: submissionStatus == 'approved'
                                                          ? Colors.green[800]
                                                          : submissionStatus == 'rejected'
                                                          ? Colors.red[800]
                                                          : Colors.orange[800],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      if (photoUrl != null)
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => Dialog(
                                                backgroundColor: Colors.transparent,
                                                insetPadding: EdgeInsets.zero,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    InteractiveViewer(
                                                      minScale: 0.5,
                                                      maxScale: 4.0,
                                                      child: Image.network(photoUrl),
                                                    ),
                                                    Positioned(
                                                      top: 20,
                                                      right: 20,
                                                      child: IconButton(
                                                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                                        onPressed: () => Navigator.pop(ctx),
                                                        style: IconButton.styleFrom(
                                                          backgroundColor: Colors.black54,
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
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  photoUrl,
                                                  height: 200,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      height: 200,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Click to enlarge',
                                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      if (adminNotes.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline,
                                                  size: 16, color: Colors.red[700]),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Admin Notes: $adminNotes',
                                                  style: TextStyle(
                                                      fontSize: 12, color: Colors.red[700]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      if (submissionStatus == 'pending') ...[
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _rejectSubmission(context, doc.id, submissionId),
                                              icon: const Icon(Icons.close, size: 18),
                                              label: const Text('Reject'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFD32F2F),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: const StadiumBorder(),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () => _approveSubmission(
                                                  context, doc.id, submissionId, challengeId),
                                              icon: const Icon(Icons.check, size: 18),
                                              label: const Text('Approve'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2E7D32),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: const StadiumBorder(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveSubmission(
      BuildContext context,
      String userChallengeId,
      String submissionId,
      String challengeId,
      ) async {
    try {
      await FirestoreService().approveSubmission(
        userChallengeId,
        submissionId,
        challengeId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission approved!'),
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

  Future<void> _bulkDeleteChallenges(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Multiple Challenges'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} challenge(s)? This action cannot be undone.',
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
          await FirestoreService().deleteChallenge(id);
        }
        setState(() {
          _selectedIds.clear();
          _isSelectAll = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenges deleted successfully'),
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

  Future<void> _rejectSubmission(
      BuildContext context,
      String userChallengeId,
      String submissionId,
      ) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reject Submission'),
        content: SizedBox(
          width: 400, // Restrict width to prevent stretching
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to reject this submission?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3, // Allows multi-line input
                minLines: 1,
                decoration: InputDecoration(
                  labelText: 'Reason for rejection',
                  hintText: 'e.g. Photo is blurry or irrelevant',
                  alignLabelWithHint: true, // Aligns label to top for multi-line
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (notesController.text.trim().isEmpty) {
                // Optional: Prevent rejection without a reason
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().rejectSubmission(
          userChallengeId,
          submissionId,
          notesController.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submission rejected'),
              backgroundColor: Colors.orange,
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
    notesController.dispose();
  }

  Future<void> _deleteChallenge(BuildContext context, String challengeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: const Text('Are you sure you want to delete this challenge?'),
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
        await FirestoreService().deleteChallenge(challengeId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Challenge deleted')),
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