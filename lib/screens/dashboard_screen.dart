import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:recylink/screens/edit_profile_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'my_item_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFFAEE55B);
  static const Color surfaceColor = Color(0xFFF5F9F6);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = 'User';
  String _email = '';
  String _phoneNumber = '';
  int _totalPoints = 0;
  int _claimedRewards = 0;
  int _completedChallenges = 0;
  int _totalItems = 0;
  int _approvedItems = 0;
  int _rejectedItems = 0;
  int _pendingItems = 0;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data();

          // Get claimed rewards count
          final rewardClaims = await _firestore
              .collection('rewardClaims')
              .where('user_id', isEqualTo: user.uid)
              .where('status', isEqualTo: 'fulfilled')
              .get();

          // Get completed challenges count
          final completedChallenges = await _firestore
              .collection('userChallenges')
              .where('user_id', isEqualTo: user.uid)
              .where('status', isEqualTo: 'completed')
              .get();

          // Get marketplace items statistics
          final allItems = await _firestore
              .collection('items')
              .where('user_id', isEqualTo: user.uid)
              .get();

          int approved = 0;
          int rejected = 0;
          int pending = 0;

          for (var doc in allItems.docs) {
            final status = doc.data()['approval_status'] ?? 'pending';
            switch (status) {
              case 'approved':
                approved++;
                break;
              case 'rejected':
                rejected++;
                break;
              case 'pending':
                pending++;
                break;
            }
          }

          setState(() {
            _username = data?['username'] ?? user.displayName ?? 'User';
            _email = data?['email'] ?? user.email ?? '';
            _phoneNumber = data?['phone_number'] ?? '';
            _totalPoints = data?['points_balance'] ?? 0;
            _profileImageUrl = data?['profile_picture'];
            _claimedRewards = rewardClaims.docs.length;
            _completedChallenges = completedChallenges.docs.length;
            _totalItems = allItems.docs.length;
            _approvedItems = approved;
            _rejectedItems = rejected;
            _pendingItems = pending;
            _isLoading = false;
          });
        } else {
          setState(() {
            _username = user.displayName ?? 'User';
            _email = user.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon Bubble
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            // Value and Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemStatsCard() {
    return GestureDetector(
      onTap: () {
        // Navigate to My Items screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyItemsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_outlined, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Shop',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tap to manage items',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$_totalItems Total',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Status Pills
            Row(
              children: [
                Expanded(child: _buildStatusPill('Approved', _approvedItems, Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatusPill('Pending', _pendingItems, Colors.orange)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatusPill('Rejected', _rejectedItems, Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showCompletedChallengesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Completed Challenges',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite, // Makes dialog wider
          height: 500, // Fixed height
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('userChallenges')
                .where('user_id', isEqualTo: _auth.currentUser?.uid)
                .where('status', isEqualTo: 'completed')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final completedChallenges = snapshot.data?.docs ?? [];

              if (completedChallenges.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No completed challenges yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start completing challenges to earn points!',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: completedChallenges.length,
                itemBuilder: (context, index) {
                  final doc = completedChallenges[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final challengeId = data['challenge_id'];
                  final completionDate = data['completion_date'] as Timestamp?;
                  final currentProgress = data['current_progress'] ?? 0;
                  final targetCount = data['target_count'] ?? 1;

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('challenges').doc(challengeId).get(),
                    builder: (context, challengeSnapshot) {
                      if (!challengeSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final challengeData = challengeSnapshot.data?.data() as Map<String, dynamic>?;
                      final title = challengeData?['title'] ?? 'Challenge';
                      final pointsReward = challengeData?['points_reward'] ?? 0;
                      final description = challengeData?['description'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            // Show detailed info dialog
                            _showChallengeDetailsDialog(
                              ctx,
                              title,
                              description,
                              currentProgress,
                              targetCount,
                              pointsReward,
                              completionDate,
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: primaryGreen,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Completed: $currentProgress/$targetCount items',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (completionDate != null)
                                        Text(
                                          'Date: ${completionDate.toDate().day}/${completionDate.toDate().month}/${completionDate.toDate().year}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+$pointsReward',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

// Add this new function to show detailed challenge info
  void _showChallengeDetailsDialog(
      BuildContext dialogContext,
      String title,
      String description,
      int currentProgress,
      int targetCount,
      int pointsReward,
      Timestamp? completionDate,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(description.isNotEmpty ? description : 'No description'),
              const SizedBox(height: 12),
              const Text(
                'Progress:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('$currentProgress out of $targetCount items submitted'),
              const SizedBox(height: 12),
              const Text(
                'Points Earned:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '+$pointsReward points',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (completionDate != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Completion Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${completionDate.toDate().day}/${completionDate.toDate().month}/${completionDate.toDate().year} at ${completionDate.toDate().hour}:${completionDate.toDate().minute.toString().padLeft(2, '0')}',
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  void _showClaimedRewardsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Claimed Rewards',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('rewardClaims')
                .where('user_id', isEqualTo: _auth.currentUser?.uid)
                .where('status', whereIn: ['pending', 'fulfilled'])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final claimedRewards = snapshot.data?.docs ?? [];

              if (claimedRewards.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No claimed rewards yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start earning points and claim rewards!',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: claimedRewards.length,
                itemBuilder: (context, index) {
                  final doc = claimedRewards[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final rewardTitle = data['reward_title'] ?? 'Reward';
                  final rewardDescription = data['reward_description'] ?? '';
                  final pointsCost = data['points_cost'] ?? 0;
                  final quantity = data['quantity'] ?? 1;
                  final totalCost = data['total_cost'] ?? pointsCost;
                  final status = data['status'] ?? 'pending';
                  final claimDate = data['claim_date'] as Timestamp?;
                  final fulfilledDate = data['fulfilled_at'] as Timestamp?;

                  // Determine status color and icon
                  Color statusColor;
                  IconData statusIcon;
                  String statusLabel;

                  if (status == 'fulfilled') {
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusLabel = 'Fulfilled';
                  } else if (status == 'pending') {
                    statusColor = Colors.orange;
                    statusIcon = Icons.pending;
                    statusLabel = 'Pending';
                  } else {
                    statusColor = Colors.grey;
                    statusIcon = Icons.info;
                    statusLabel = status;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        final expiryDate = data['expiry_date'] as Timestamp?;
                        _showRewardDetailsDialog(
                          ctx,
                          rewardTitle,
                          rewardDescription,
                          pointsCost,
                          quantity,
                          totalCost,
                          status,
                          claimDate,
                          fulfilledDate,
                          doc.id, // ✅ Pass claim ID
                          expiryDate, // ✅ Pass expiry date
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rewardTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity: $quantity',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (claimDate != null)
                                    Text(
                                      'Claimed: ${claimDate.toDate().day}/${claimDate.toDate().month}/${claimDate.toDate().year}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$totalCost',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRewardDetailsDialog(
      BuildContext dialogContext,
      String title,
      String description,
      int pointsCost,
      int quantity,
      int totalCost,
      String status,
      Timestamp? claimDate,
      Timestamp? fulfilledDate,
      String claimId, // ✅ ADD THIS PARAMETER
      Timestamp? expiryDate, // ✅ ADD THIS PARAMETER
      ) {
    // Determine status display
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (status == 'fulfilled') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusLabel = 'Fulfilled';
    } else if (status == 'pending') {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusLabel = 'Pending Admin Approval';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info;
      statusLabel = status;
    }

    // ✅ Check if expired
    bool isExpired = false;
    if (expiryDate != null && status == 'fulfilled') {
      isExpired = DateTime.now().isAfter(expiryDate.toDate());
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isExpired ? Icons.event_busy : statusIcon,
                    color: isExpired ? Colors.red : statusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isExpired ? 'EXPIRED' : statusLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.red : statusColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ✅ BARCODE SECTION (only for fulfilled & not expired)
              if (status == 'fulfilled' && !isExpired) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryGreen, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Scan this code to redeem',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      QrImageView(
                        data: 'RECYLINK-REWARD:$claimId',
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Code: ${claimId.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(description.isNotEmpty ? description : 'No description'),
              const SizedBox(height: 12),
              const Text(
                'Quantity Claimed:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('$quantity item${quantity > 1 ? 's' : ''}'),
              const SizedBox(height: 12),
              const Text(
                'Points Cost:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$pointsCost points each × $quantity = $totalCost points total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (claimDate != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Claim Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${claimDate.toDate().day}/${claimDate.toDate().month}/${claimDate.toDate().year} at ${claimDate.toDate().hour}:${claimDate.toDate().minute.toString().padLeft(2, '0')}',
                ),
              ],
              if (fulfilledDate != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Fulfillment Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fulfilledDate.toDate().day}/${fulfilledDate.toDate().month}/${fulfilledDate.toDate().year} at ${fulfilledDate.toDate().hour}:${fulfilledDate.toDate().minute.toString().padLeft(2, '0')}',
                ),
              ],
              // ✅ EXPIRY DATE SECTION
              if (expiryDate != null && status == 'fulfilled') ...[
                const SizedBox(height: 12),
                const Text(
                  'Expiry Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isExpired ? Icons.event_busy : Icons.event_available,
                      size: 18,
                      color: isExpired ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${expiryDate.toDate().day}/${expiryDate.toDate().month}/${expiryDate.toDate().year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isExpired ? Colors.red : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isExpired) ...[
                      Text(
                        '(${expiryDate.toDate().difference(DateTime.now()).inDays} days left)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (status == 'pending') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Points will be deducted once admin approves your claim',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // ✅ EXPIRED INFO
              if (isExpired) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This reward has expired and can no longer be redeemed',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPointsHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: primaryGreen),
            const SizedBox(width: 8),
            const Text('Points History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('userChallenges')
                .where('user_id', isEqualTo: _auth.currentUser?.uid)
                .where('status', isEqualTo: 'completed')
                .orderBy('completion_date', descending: true)
                .snapshots(),
            builder: (context, challengesSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('rewardClaims')
                    .where('user_id', isEqualTo: _auth.currentUser?.uid)
                    .where('status', isEqualTo: 'fulfilled')
                    .orderBy('fulfilled_at', descending: true)
                    .snapshots(),
                builder: (context, rewardsSnapshot) {
                  // ✅ Wait for BOTH streams to complete
                  if (challengesSnapshot.connectionState == ConnectionState.waiting ||
                      rewardsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryGreen));
                  }

                  if (challengesSnapshot.hasError || rewardsSnapshot.hasError) {
                    return const Center(
                      child: Text('Error loading history', style: TextStyle(color: Colors.red)),
                    );
                  }

                  // ✅ Build list of futures to fetch challenge details
                  List<Future<Map<String, dynamic>?>> transactionFutures = [];

                  // Add challenge completions (fetch challenge details)
                  if (challengesSnapshot.hasData) {
                    for (var doc in challengesSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final challengeId = data['challenge_id'];
                      final completionDate = data['completion_date'] as Timestamp?;

                      // Create a future that fetches challenge details
                      transactionFutures.add(
                        _firestore.collection('challenges').doc(challengeId).get().then((challengeDoc) {
                          if (challengeDoc.exists) {
                            final challengeData = challengeDoc.data()!;
                            return {
                              'type': 'earned',
                              'title': challengeData['title'] ?? 'Challenge',
                              'points': challengeData['points_reward'] ?? 0,
                              'date': completionDate,
                            };
                          }
                          return null;
                        }).catchError((_) => null),
                      );
                    }
                  }

                  // Add reward redemptions (no additional fetch needed)
                  if (rewardsSnapshot.hasData) {
                    for (var doc in rewardsSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      transactionFutures.add(
                        Future.value({
                          'type': 'spent',
                          'title': data['reward_title'] ?? 'Reward',
                          'points': -(data['total_cost'] ?? 0),
                          'date': data['fulfilled_at'] as Timestamp?,
                        }),
                      );
                    }
                  }

                  // ✅ Wait for all futures to complete, then build UI
                  return FutureBuilder<List<Map<String, dynamic>?>>(
                    future: Future.wait(transactionFutures),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: primaryGreen));
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading transactions', style: TextStyle(color: Colors.red)),
                        );
                      }

                      // Filter out null values and cast to non-nullable list
                      final transactions = snapshot.data
                          ?.where((t) => t != null)
                          .cast<Map<String, dynamic>>()
                          .toList() ?? [];

                      // Sort by date (most recent first)
                      transactions.sort((a, b) {
                        final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
                        final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
                        return bDate.compareTo(aDate);
                      });

                      if (transactions.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No transactions yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              SizedBox(height: 8),
                              Text(
                                'Complete challenges or claim rewards\nto see your points history',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final isEarned = transaction['type'] == 'earned';
                          final points = transaction['points'] as int;
                          final title = transaction['title'] as String;
                          final date = transaction['date'] as Timestamp?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isEarned ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isEarned ? Icons.add_circle : Icons.remove_circle,
                                  color: isEarned ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                date != null
                                    ? DateFormat('MMM d, yyyy • h:mm a').format(date.toDate())
                                    : 'Unknown date',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '${isEarned ? '+' : ''}$points',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isEarned ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor, // Light mint background
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryGreen)))
          : RefreshIndicator(
        onRefresh: _loadUserData,
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. MODERN PROFILE CARD
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('lib/assets/profilr.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                        if (result == true) _loadUserData();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),

              const SizedBox(height: 15),

              // 2. STATS GRID (Replaces the vertical stack)
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1, // Controls height of cards
                children: [
                  _buildStatCard(
                    title: 'Total Points',
                    value: _totalPoints.toString(),
                    icon: Icons.star_rounded,
                    iconBgColor: Colors.amber[100]!,
                    iconColor: Colors.amber[800]!,
                    onTap: _showPointsHistory,
                  ),
                  _buildStatCard(
                    title: 'Rewards Claimed',
                    value: _claimedRewards.toString(),
                    icon: Icons.card_giftcard,
                    iconBgColor: Colors.pink[50]!,
                    iconColor: Colors.pink[400]!,
                    onTap: _showClaimedRewardsDialog,
                  ),
                  _buildStatCard(
                    title: 'Challenges Done',
                    value: _completedChallenges.toString(),
                    icon: Icons.emoji_events_outlined,
                    iconBgColor: Colors.green[50]!,
                    iconColor: primaryGreen,
                    onTap: _showCompletedChallengesDialog,
                  ),
                  // You can add a 4th item here if needed, or leave it 3
                ],
              ),

              const SizedBox(height: 24),

              // 3. MARKETPLACE STATS
              _buildItemStatsCard(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}