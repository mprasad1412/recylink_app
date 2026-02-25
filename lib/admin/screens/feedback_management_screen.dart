// lib/admin/screens/feedback_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:recylink/services/notification_service.dart';
import 'dart:html' as html;

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  String _selectedFilter = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _notificationService = NotificationService();

  int _currentPage = 0;
  final int _itemsPerPage = 8;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Stream<QuerySnapshot> _getFeedbackStream() {
    var query = FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('submitted_at', descending: true);

    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter) as Query<Map<String, dynamic>>;
    }

    return query.snapshots();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6), // Mint Surface
      body: Column(
        children: [
          // Header Container
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Detection Feedback',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review user feedback to improve model accuracy',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Filters & Search Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive Layout Logic
                    final isSmallScreen = constraints.maxWidth < 900;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSmallScreen) ...[
                          _buildFilterRow(),
                          const SizedBox(height: 16),
                          _buildSearchBar(fullWidth: true),
                        ] else
                          Row(
                            children: [
                              Expanded(child: _buildFilterRow()),
                              const SizedBox(width: 20),
                              _buildSearchBar(width: 350),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Feedback List with Pagination
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFeedbackStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading feedback', style: TextStyle(color: Colors.red)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feedback_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No feedback found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                var allDocs = snapshot.data!.docs;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  allDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final predicted = (data['predicted_class'] ?? '').toString().toLowerCase();
                    final correct = (data['correct_class'] ?? '').toString().toLowerCase();
                    final email = (data['user_email'] ?? '').toString().toLowerCase();
                    return predicted.contains(_searchQuery) ||
                        correct.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();
                }

                // Pagination Logic
                final totalPages = (allDocs.length / _itemsPerPage).ceil();
                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }
                final startIndex = _currentPage * _itemsPerPage;
                final endIndex = (startIndex + _itemsPerPage).clamp(0, allDocs.length);
                final paginatedDocs = allDocs.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: paginatedDocs.length,
                        itemBuilder: (context, index) {
                          final doc = paginatedDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _FeedbackCard(
                            feedbackId: doc.id,
                            data: data,
                            onStatusChanged: () => setState(() {}),
                            getPriorityColor: _getPriorityColor,
                            getStatusColor: _getStatusColor,
                            notificationService: _notificationService,
                          );
                        },
                      ),
                    ),

                    // Pagination Footer
                    if (totalPages > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        color: Colors.white, // Footer background
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${startIndex + 1}-$endIndex of ${allDocs.length} feedback${_searchQuery.isNotEmpty ? " (filtered)" : ""}',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32).withOpacity(0.1), // Green Tint
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Page ${_currentPage + 1} of $totalPages',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32), // Green Text
                                      fontSize: 12,
                                    ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Filter Row
  Widget _buildFilterRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'All',
          isSelected: _selectedFilter == 'all',
          onTap: () => setState(() { _selectedFilter = 'all'; _currentPage = 0; }),
          color: const Color(0xFF2E7D32), // Primary Green
        ),
        _FilterChip(
          label: 'Pending',
          isSelected: _selectedFilter == 'pending',
          onTap: () => setState(() { _selectedFilter = 'pending'; _currentPage = 0; }),
          color: Colors.orange,
        ),
        _FilterChip(
          label: 'Under Review',
          isSelected: _selectedFilter == 'under_review',
          onTap: () => setState(() { _selectedFilter = 'under_review'; _currentPage = 0; }),
          color: Colors.blue,
        ),
        _FilterChip(
          label: 'Resolved',
          isSelected: _selectedFilter == 'resolved',
          onTap: () => setState(() { _selectedFilter = 'resolved'; _currentPage = 0; }),
          color: Colors.green,
        ),
      ],
    );
  }

  // Helper Widget for Floating Search Bar
  Widget _buildSearchBar({double? width, bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : width,
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
            hintText: 'Search by class or user...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[400]),
              onPressed: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
                _currentPage = 0;
              }),
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          onChanged: (value) => setState(() {
            _searchQuery = value.toLowerCase();
            _currentPage = 0;
          }),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF2E7D32);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String feedbackId;
  final Map<String, dynamic> data;
  final VoidCallback onStatusChanged;
  final Color Function(String) getPriorityColor;
  final Color Function(String) getStatusColor;
  final NotificationService notificationService;

  const _FeedbackCard({
    required this.feedbackId,
    required this.data,
    required this.onStatusChanged,
    required this.getPriorityColor,
    required this.getStatusColor,
    required this.notificationService,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  void _showFeedbackDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          _FeedbackDetailsDialog(
            feedbackId: feedbackId,
            data: data,
            onStatusChanged: onStatusChanged,
            notificationService: notificationService,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final priority = data['priority'] ?? 'low';
    final predictedClass = data['predicted_class'] ?? 'Unknown';
    final correctClass = data['correct_class'] ?? 'Unknown';
    final confidence = (data['confidence_score'] ?? 0.0) * 100;
    final userEmail = data['user_email'] ?? 'Anonymous';
    final submittedAt = data['submitted_at'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFeedbackDetails(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Badges & Date)
                Row(
                  children: [
                    // Priority Badge (Pill)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: getPriorityColor(priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, size: 12, color: getPriorityColor(priority)),
                          const SizedBox(width: 4),
                          Text(
                            priority.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: getPriorityColor(priority)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge (Pill)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: getStatusColor(status)),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(submittedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Prediction Info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Predicted', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.close, size: 18, color: Colors.red[700]),
                              const SizedBox(width: 6),
                              Expanded(child: Text(predictedClass, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          Text('${confidence.toStringAsFixed(1)}% confidence', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.grey[200]), // Divider
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Should Be', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.check, size: 18, color: Colors.green[700]),
                              const SizedBox(width: 6),
                              Expanded(child: Text(correctClass, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // User Info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Expanded(child: Text(userEmail, style: TextStyle(fontSize: 13, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                  ],
                ),

                // Footer Link
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))), // Green Link
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2E7D32)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  class _FeedbackDetailsDialog extends StatefulWidget {
  final String feedbackId;
  final Map<String, dynamic> data;
  final VoidCallback onStatusChanged;
  final NotificationService notificationService;

  const _FeedbackDetailsDialog({
    required this.feedbackId,
    required this.data,
    required this.onStatusChanged,
    required this.notificationService,
  });

  @override
  State<_FeedbackDetailsDialog> createState() => _FeedbackDetailsDialogState();
}

class _FeedbackDetailsDialogState extends State<_FeedbackDetailsDialog> {
  final _adminNotesController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _adminNotesController.text = widget.data['admin_notes'] ?? '';
  }

  @override
  void dispose() {
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      final userId = widget.data['user_id'];

      await FirebaseFirestore.instance.collection('feedback').doc(widget.feedbackId).update({
        'status': newStatus,
        'admin_id': adminId,
        'admin_notes': _adminNotesController.text.trim(),
        'reviewed_at': FieldValue.serverTimestamp(),
      });

      // SEND NOTIFICATION TO USER
      String notificationTitle;
      String notificationMessage;
      String notificationType;

      if (newStatus == 'under_review') {
        notificationType = 'feedback_under_review';
        notificationTitle = 'Feedback Under Review 👀';
        notificationMessage = 'Your feedback is being reviewed by our team. Thank you for your patience!';
      } else if (newStatus == 'resolved') {
        notificationType = 'feedback_resolved';
        notificationTitle = 'Feedback Resolved! ✅';
        notificationMessage = 'Thank you for your feedback! Your report has been reviewed and will help improve our AI model.';
      } else {
        notificationType = 'feedback_updated';
        notificationTitle = 'Feedback Updated';
        notificationMessage = 'Your feedback status has been updated.';
      }

      await widget.notificationService.createNotification(
        userId: userId,
        type: notificationType,
        title: notificationTitle,
        message: notificationMessage,
        relatedId: widget.feedbackId,
        additionalData: {
          'new_status': newStatus,
          'predicted_class': widget.data['predicted_class'],
          'correct_class': widget.data['correct_class'],
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Feedback marked as $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusChanged();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  // DOWNLOAD IMAGE FUNCTION (Option A - Browser Download)
  void _downloadImage(String imageUrl) {
    try {
      final anchor = html.AnchorElement(href: imageUrl)
        ..setAttribute('download', 'feedback_${widget.feedbackId}.jpg')
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Download started'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFeedback() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('feedback').doc(widget.feedbackId).delete();
        if (mounted) {
          widget.onStatusChanged();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Feedback deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.data['image_url'];
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 700 ? 700.0 : screenWidth * 0.95;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Modern Shape
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32), // Primary Green Header
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.feedback, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Feedback Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    if (imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 250,
                                width: double.infinity,
                                color: Colors.grey[100],
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: FloatingActionButton.small(
                                backgroundColor: Colors.white,
                                child: const Icon(Icons.download, color: Colors.black87),
                                onPressed: () => _downloadImage(imageUrl),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Info Grid
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(label: 'Predicted', value: widget.data['predicted_class'] ?? 'N/A', icon: Icons.close, color: Colors.red),
                          const Divider(height: 24),
                          _InfoRow(label: 'Correct', value: widget.data['correct_class'] ?? 'N/A', icon: Icons.check, color: Colors.green),
                          const Divider(height: 24),
                          _InfoRow(label: 'Confidence', value: '${((widget.data['confidence_score'] ?? 0.0) * 100).toStringAsFixed(1)}%', icon: Icons.analytics, color: Colors.blue),
                          const Divider(height: 24),
                          _InfoRow(label: 'User', value: widget.data['user_email'] ?? 'Anonymous', icon: Icons.person, color: Colors.purple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Admin Notes
                    const Text('Admin Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _adminNotesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add internal notes...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUpdating ? null : () => _updateStatus('under_review'),
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            label: const Text('Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUpdating ? null : () => _updateStatus('resolved'),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Resolve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32), // Green
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _isUpdating ? null : _deleteFeedback,
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Color _getPriorityColorForInfo(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}