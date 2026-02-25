import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'submit_challenge_screen.dart';
import 'package:recylink/services/notification_service.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final String challengeId;
  final String userChallengeId;
  final Map<String, dynamic> challengeData;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
    required this.userChallengeId,
    required this.challengeData,
  });

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color surfaceColor = Color(0xFFF5F9F6);

  @override
  Widget build(BuildContext context) {
    final title = challengeData['title'] ?? 'Challenge';
    final description = challengeData['description'] ?? '';
    final pointsReward = challengeData['points_reward'] ?? 0;
    final targetCount = challengeData['target_count'] ?? 1;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('userChallenges')
            .doc(userChallengeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Challenge not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final currentProgress = data['current_progress'] ?? 0;
          final status = data['status'] ?? 'joined';
          final submissions = List<Map<String, dynamic>>.from(data['submissions'] ?? []);

          // Get previous progress from previous snapshot to detect changes
          final previousData = snapshot.data!.metadata.hasPendingWrites
              ? (snapshot.data!.metadata.isFromCache ? null : snapshot.data!)
              : null;

          final previousProgress = previousData != null
              ? (previousData.data() as Map<String, dynamic>)['current_progress'] ?? 0
              : currentProgress;

          // Check if progress just increased and we're one away from completion
          if (currentProgress > previousProgress &&
              currentProgress == targetCount - 1 &&
              status != 'completed') {

          }

          final progressPercentage = (currentProgress / targetCount * 100).clamp(0, 100).toInt();
          final canSubmitMore = currentProgress < targetCount && status != 'pending_review' && status != 'completed';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events, color: primaryGreen, size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Points Reward',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 20),
                                      const SizedBox(width: 5),
                                      Text(
                                        '$pointsReward',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Target',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '$targetCount items',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
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

                  const SizedBox(height: 20),

                  // Progress Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$currentProgress / $targetCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '$progressPercentage%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: progressPercentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                            minHeight: 10,
                          ),
                          const SizedBox(height: 10),
                          _buildStatusChip(status),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submissions Section
                  const Text(
                    'Submissions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (submissions.isEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                'No submissions yet',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Start by submitting your first item!',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...submissions.map((submission) {
                      return _buildSubmissionCard(submission);
                    }).toList(),

                  const SizedBox(height: 80), // Space for floating button
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('userChallenges')
            .doc(userChallengeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final currentProgress = data['current_progress'] ?? 0;
          final status = data['status'] ?? 'joined';
          final canSubmitMore = currentProgress < targetCount &&
              status != 'pending_review' &&
              status != 'completed';

          if (!canSubmitMore) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubmitChallengeScreen(
                    challengeId: challengeId,
                    userChallengeId: userChallengeId,
                    challengeTitle: challengeData['title'] ?? 'Challenge',
                  ),
                ),
              );
            },
            backgroundColor: primaryGreen,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text(
              'Submit Item',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  // Future<void> _sendAlmostThereNotification() async {
  //   try {
  //     final userId = FirebaseAuth.instance.currentUser?.uid;
  //     if (userId == null) return;
  //
  //     await NotificationService().createNotification(
  //       userId: userId,
  //       type: 'challenge_progress',
  //       title: 'Almost There! 🎯',
  //       message: 'Only 1 more item needed to complete this challenge!',
  //       relatedId: userChallengeId,
  //       additionalData: {
  //         'challenge_title': challengeData['title'] ?? 'Challenge',
  //         'items_remaining': 1,
  //       },
  //     );
  //   } catch (e) {
  //     print('Error sending notification: $e');
  //     // Fail silently - notification is not critical functionality
  //   }
  // }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'joined':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue;
        label = 'Started';
        break;
      case 'in_progress':
        backgroundColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        label = 'In Progress';
        break;
      case 'pending_review':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange;
        label = 'Pending Review';
        break;
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green;
        label = 'Completed ✓';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final photoUrl = submission['photo_url'] ?? '';
    final submittedAt = submission['submitted_at'] as Timestamp?;
    final submissionStatus = submission['status'] ?? 'pending';
    final adminNotes = submission['admin_notes'] ?? '';

    IconData statusIcon;
    Color statusColor;
    String statusLabel;

    switch (submissionStatus) {
      case 'approved':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        break;
      default:
        statusIcon = Icons.pending;
        statusColor = Colors.orange;
        statusLabel = 'Pending Review';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                if (submittedAt != null)
                  Text(
                    _formatDate(submittedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                photoUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    ),
                  );
                },
              )
                  : Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
            ),
            if (adminNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin: $adminNotes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[700],
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
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}