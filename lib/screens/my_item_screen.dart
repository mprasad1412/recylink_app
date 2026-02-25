import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recylink/screens/edit_item_screen.dart';
import 'package:recylink/admin/services/firestore_service.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color surfaceColor = const Color(0xFFF5F9F6);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isDeleting = false;

  /// Show delete confirmation dialog based on item status
  Future<void> _showDeleteConfirmation(
      BuildContext context,
      String itemId,
      String itemTitle,
      String approvalStatus,
      String? rejectionReason,
      ) async {
    String title;
    String message;
    String confirmText;
    Color confirmColor;

    switch (approvalStatus) {
      case 'approved':
        title = 'Delete Item?';
        message = 'Delete "$itemTitle"?\n\nThis will remove it from the marketplace permanently.';
        confirmText = 'Delete';
        confirmColor = Colors.red;
        break;
      case 'pending':
        title = 'Cancel Submission?';
        message = 'Cancel "$itemTitle"?\n\nThis will stop the review process and remove your submission.';
        confirmText = 'Cancel Submission';
        confirmColor = Colors.orange;
        break;
      case 'rejected':
        title = 'Remove Item?';
        message = rejectionReason != null
            ? 'Remove "$itemTitle"?\n\nRejection reason: $rejectionReason\n\nThis action cannot be undone.'
            : 'Remove "$itemTitle"?\n\nThis action cannot be undone.';
        confirmText = 'Remove';
        confirmColor = Colors.red;
        break;
      default:
        title = 'Delete Item?';
        message = 'Are you sure you want to delete "$itemTitle"?';
        confirmText = 'Delete';
        confirmColor = Colors.red;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              approvalStatus == 'pending' ? Icons.cancel_outlined : Icons.delete_outline,
              color: confirmColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: confirmColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep It', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteItem(itemId, itemTitle);
    }
  }

  /// Delete item from Firestore
  Future<void> _deleteItem(String itemId, String itemTitle) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _firestoreService.deleteItem(itemId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '"$itemTitle" deleted successfully',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to delete item. Please try again.',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Items',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('items')
                .where('user_id', isEqualTo: _auth.currentUser?.uid)
                .orderBy('post_date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading items',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                          Icons.storefront_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items posted yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start selling your upcycled items!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final items = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final doc = items[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final itemId = doc.id;

                  return _buildItemCard(itemId, data);
                },
              );
            },
          ),

          // Loading overlay when deleting
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deleting...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(String itemId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled';
    final imageUrl = data['images'] ?? '';
    final price = (data['price'] ?? 0).toDouble();
    final approvalStatus = data['approval_status'] ?? 'pending';
    final rejectionReason = data['rejection_reason'] as String?;

    // Determine status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;
    bool isClickable;

    switch (approvalStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        isClickable = true;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        isClickable = false;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.pending;
        isClickable = false;
        break;
    }

    return GestureDetector(
      onTap: isClickable
          ? () async {
        // Navigate to Edit Screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditItemScreen(
              itemId: itemId,
              itemData: data,
            ),
          ),
        );

        // Show success message if edited
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Item updated successfully!',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isClickable
                ? Colors.transparent
                : Colors.grey.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isClickable ? 0.08 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: isClickable ? 1.0 : 0.5,
          child: Stack(
            children: [
              Row(
                children: [
                  // Image Section
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        );
                      },
                    )
                        : Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey[100],
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    ),
                  ),

                  // Details Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Price
                          Text(
                            price > 0 ? 'RM ${price.toStringAsFixed(2)}' : 'Free',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Status Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 14, color: statusColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (isClickable)
                                Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Delete button positioned at top-right
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _isDeleting
                      ? null
                      : () => _showDeleteConfirmation(
                    context,
                    itemId,
                    title,
                    approvalStatus,
                    rejectionReason,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: approvalStatus == 'pending'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: approvalStatus == 'pending'
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      approvalStatus == 'pending' ? Icons.close : Icons.delete_outline,
                      size: 18,
                      color: approvalStatus == 'pending' ? Colors.orange[700] : Colors.red[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}