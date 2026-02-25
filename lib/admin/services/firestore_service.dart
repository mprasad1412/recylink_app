import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recylink/services/notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  String get _adminId => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  // ==================== USER MANAGEMENT ====================

  /// Delete multiple users
  Future<void> deleteUsers(List<String> userIds) async {
    try {
      final batch = _db.batch();

      for (final userId in userIds) {
        batch.delete(_db.collection('users').doc(userId));
      }

      await batch.commit();
      print('✅ ${userIds.length} users deleted successfully');
    } catch (e) {
      print('❌ Error deleting users: $e');
      rethrow;
    }
  }

  /// Delete a single user
  Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
      print('✅ User deleted successfully');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // ==================== MARKETPLACE ITEMS ====================

  Stream<QuerySnapshot> getPendingItems() {
    return _db.collection('items')
        .where('approval_status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> approveItem(String itemId, String userId, int points) async {
    try {
      final itemDoc = await _db.collection('items').doc(itemId).get();
      final itemTitle = itemDoc.data()?['title'] ?? 'Your item';

      final batch = _db.batch();

      // Update item status
      batch.update(_db.collection('items').doc(itemId), {
        'approval_status': 'approved',
        'approved_by': _adminId,
        'approved_at': FieldValue.serverTimestamp(),
      });

      // Add points to user
      batch.update(_db.collection('users').doc(userId), {
        'points_balance': FieldValue.increment(points),
      });

      await batch.commit();

      //  CREATE NOTIFICATION
      await _notificationService.createNotification(
        userId: userId,
        type: 'item_approved',
        title: 'Item Approved! ✅',
        message: 'Your item "$itemTitle" has been approved and is now visible in the marketplace!',
        relatedId: itemId,
        additionalData: {
          'item_title': itemTitle,
          'points_earned': points,
        },
      );

      print('✅ Item approved and notification sent');
    } catch (e) {
      print('❌ Error approving item: $e');
    }
  }

  Future<void> rejectItem(String itemId, String reason) async {
    try {
      final itemDoc = await _db.collection('items').doc(itemId).get();
      final itemData = itemDoc.data();
      final itemTitle = itemData?['title'] ?? 'Your item';
      final userId = itemData?['user_id'];

      await _db.collection('items').doc(itemId).update({
        'approval_status': 'rejected',
        'approved_by': _adminId,
        'rejected_at': FieldValue.serverTimestamp(),
        'rejection_reason': reason, //  NEW FIELD
      });

      if (userId != null) {
        //  CREATE NOTIFICATION WITH REASON
        await _notificationService.createNotification(
          userId: userId,
          type: 'item_rejected',
          title: 'Item Rejected',
          message: 'Your item "$itemTitle" was rejected. Reason: $reason',
          relatedId: itemId,
          additionalData: {
            'item_title': itemTitle,
            'rejection_reason': reason,
          },
        );
      }

      print('✅ Item rejected with reason and notification sent');
    } catch (e) {
      print('❌ Error rejecting item: $e');
      rethrow;
    }
  }

  /// Delete a marketplace item (user can delete their own items)
  Future<void> deleteItem(String itemId) async {
    try {
      await _db.collection('items').doc(itemId).delete();
      print('✅ Item deleted successfully');
    } catch (e) {
      print('❌ Error deleting item: $e');
      rethrow;
    }
  }

  // ==================== REWARDS ====================

  Stream<QuerySnapshot> getAllRewards() {
    return _db.collection('rewards').snapshots();
  }

  Stream<QuerySnapshot> getPendingRewardClaims() {
    return _db.collection('rewardClaims')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> addReward(Map<String, dynamic> data) async {
    await _db.collection('rewards').add({
      ...data,
      'added_by': _adminId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateReward(String rewardId, Map<String, dynamic> data) async {
    await _db.collection('rewards').doc(rewardId).update(data);
  }

  Future<void> deleteReward(String rewardId) async {
    await _db.collection('rewards').doc(rewardId).delete();
  }

  Future<void> fulfillRewardClaim(String claimId) async {
    try {
      // Get claim data first
      final claimDoc = await _db.collection('rewardClaims').doc(claimId).get();

      if (!claimDoc.exists) {
        print('❌ Claim document not found');
        return;
      }

      final claimData = claimDoc.data() as Map<String, dynamic>;

      final userId = claimData['user_id'];
      final totalCost = claimData['total_cost'] ?? claimData['points_cost'];
      final rewardTitle = claimData['reward_title'] ?? 'Reward';
      final quantity = claimData['quantity'] ?? 1;

      final batch = _db.batch();

      // Calculate expiry date (30 days from now)
      final expiryDate = DateTime.now().add(const Duration(days: 30));

      // Update claim status
      batch.update(_db.collection('rewardClaims').doc(claimId), {
        'status': 'fulfilled',
        'fulfilled_by': _adminId,
        'fulfilled_at': FieldValue.serverTimestamp(),
        'expiry_date': Timestamp.fromDate(expiryDate), //  Add expiry
      });

      // Deduct points when admin approves
      batch.update(_db.collection('users').doc(userId), {
        'points_balance': FieldValue.increment(-totalCost),
      });

      await batch.commit();

      //  CREATE NOTIFICATION
      await _notificationService.createNotification(
        userId: userId,
        type: 'reward_approved',
        title: 'Reward Approved! 🎉',
        message: 'Your claim for $quantity x $rewardTitle has been approved! Valid for 30 days.',
        relatedId: claimId,
        additionalData: {
          'reward_title': rewardTitle,
          'quantity': quantity,
          'points_cost': totalCost,
          'expiry_date': expiryDate.toIso8601String(),
        },
      );

      print('✅ Reward claim fulfilled, notification sent, expiry set');
    } catch (e) {
      print('❌ Error fulfilling reward claim: $e');
    }
  }

  Future<void> rejectRewardClaim(String claimId, int pointsToReturn, String userId) async {
    try {
      final claimDoc = await _db.collection('rewardClaims').doc(claimId).get();

      if (!claimDoc.exists) {
        print('❌ Claim document not found');
        return;
      }

      final claimData = claimDoc.data() as Map<String, dynamic>;
      final rewardTitle = claimData['reward_title'] ?? 'Reward';

      // Just update status - no points to return since we didn't deduct yet
      await _db.collection('rewardClaims').doc(claimId).update({
        'status': 'rejected',
        'rejected_by': _adminId,
        'rejected_at': FieldValue.serverTimestamp(),
      });

      //  CREATE NOTIFICATION
      await _notificationService.createNotification(
        userId: userId,
        type: 'reward_rejected',
        title: 'Reward Claim Rejected',
        message: 'Your claim for $rewardTitle was rejected. Please review our guidelines and try again.',
        relatedId: claimId,
        additionalData: {
          'reward_title': rewardTitle,
        },
      );

      print('✅ Reward claim rejected and notification sent');
    } catch (e) {
      print('❌ Error rejecting reward claim: $e');
    }
  }

  // ==================== CHALLENGES ====================

  Stream<QuerySnapshot> getAllChallenges() {
    return _db.collection('challenges').snapshots();
  }

  Future<void> addChallenge(Map<String, dynamic> data) async {
    await _db.collection('challenges').add({
      ...data,
      'added_by': _adminId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChallenge(String challengeId, Map<String, dynamic> data) async {
    await _db.collection('challenges').doc(challengeId).update(data);
  }

  Future<void> deleteChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).delete();
  }

  // ==================== USER CHALLENGES & SUBMISSIONS ====================

  /// Get all user challenge submissions for a specific challenge
  Stream<QuerySnapshot> getChallengeSubmissions(String challengeId) {
    return _db.collection('userChallenges')
        .where('challenge_id', isEqualTo: challengeId)
        .snapshots();
  }

  /// Get a specific user's challenge progress
  Stream<DocumentSnapshot> getUserChallenge(String userId, String challengeId) {
    return _db.collection('userChallenges')
        .where('user_id', isEqualTo: userId)
        .where('challenge_id', isEqualTo: challengeId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.first);
  }

  /// Start a challenge (user joins)
  Future<String> startChallenge(String userId, String challengeId, int targetCount) async {
    final docRef = await _db.collection('userChallenges').add({
      'user_id': userId,
      'challenge_id': challengeId,
      'status': 'joined',
      'current_progress': 0,
      'target_count': targetCount,
      'submissions': [],
      'joined_date': FieldValue.serverTimestamp(),
    });

    // Increment participants count
    await _db.collection('challenges').doc(challengeId).update({
      'participants_count': FieldValue.increment(1),
    });

    return docRef.id;
  }

  /// Submit a photo for challenge progress
  Future<void> submitChallengePhoto(
      String userChallengeId,
      String photoUrl,
      String submissionId,
      ) async {
    final docRef = _db.collection('userChallenges').doc(userChallengeId);
    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>;

    final currentProgress = (data['current_progress'] ?? 0) + 1;
    final targetCount = data['target_count'] ?? 1;
    final submissions = List<Map<String, dynamic>>.from(data['submissions'] ?? []);

    // Add new submission (FIXED: Use Timestamp.now() instead of serverTimestamp in arrays)
    submissions.add({
      'submission_id': submissionId,
      'photo_url': photoUrl,
      'submitted_at': Timestamp.now(), // ← FIXED HERE
      'status': 'pending',
    });

    // Determine new status
    String newStatus;
    if (currentProgress >= targetCount) {
      newStatus = 'pending_review'; // All submissions done, waiting for admin
    } else {
      newStatus = 'in_progress';
    }

    await docRef.update({
      'current_progress': currentProgress,
      'submissions': submissions,
      'status': newStatus,
    });
  }

  /// Admin approves a submission
  Future<void> approveSubmission(
      String userChallengeId,
      String submissionId,
      String challengeId,
      ) async {
    try {
      final docRef = _db.collection('userChallenges').doc(userChallengeId);
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>;

      final submissions = List<Map<String, dynamic>>.from(data['submissions'] ?? []);
      final userId = data['user_id'];
      final targetCount = data['target_count'] ?? 1;

      // 1. Update the specific submission status to approved
      for (var submission in submissions) {
        if (submission['submission_id'] == submissionId) {
          submission['status'] = 'approved';
          submission['admin_id'] = _adminId;
          submission['reviewed_at'] = Timestamp.now();
          break;
        }
      }

      // 2. FIX: Count how many VALID approved submissions exist
      // We do not use .every() because we want to ignore rejected items in the history
      final approvedCount = submissions.where((s) => s['status'] == 'approved').length;

      // 3. Check if approved count meets the target
      if (approvedCount >= targetCount) {
        // All done! Award points
        final challengeDoc = await _db.collection('challenges').doc(challengeId).get();
        final pointsReward = challengeDoc.get('points_reward') ?? 0;
        final challengeTitle = challengeDoc.get('title') ?? 'Challenge';

        final batch = _db.batch();

        // Update user challenge to completed
        batch.update(docRef, {
          'submissions': submissions,
          'status': 'completed',
          'completion_date': FieldValue.serverTimestamp(),
          // Optional: Force current_progress to match approved count to be clean
          'current_progress': approvedCount,
        });

        // Award points to user
        batch.update(_db.collection('users').doc(userId), {
          'points_balance': FieldValue.increment(pointsReward),
        });

        await batch.commit();

        //  CREATE NOTIFICATION
        await _notificationService.createNotification(
          userId: userId,
          type: 'challenge_completed',
          title: 'Challenge Completed! 🏆',
          message: 'Congratulations! You completed "$challengeTitle" and earned $pointsReward points!',
          relatedId: userChallengeId,
          additionalData: {
            'challenge_title': challengeTitle,
            'points_earned': pointsReward,
          },
        );

        print('✅ Challenge completed, points awarded, notification sent');
      } else {
        // Not enough approved items yet (or simply updating one of many)
        // Just update the submission status
        await docRef.update({
          'submissions': submissions,
        });
        print('✅ Submission approved, waiting for more approved submissions');
      }
    } catch (e) {
      print('❌ Error approving submission: $e');
      rethrow; // Good practice to rethrow so UI knows it failed
    }
  }

  /// Admin rejects a submission
  Future<void> rejectSubmission(
      String userChallengeId,
      String submissionId,
      String notes,
      ) async {
    try {
      final docRef = _db.collection('userChallenges').doc(userChallengeId);
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>;

      final submissions = List<Map<String, dynamic>>.from(data['submissions'] ?? []);
      final userId = data['user_id'];

      // Update submission status
      for (var submission in submissions) {
        if (submission['submission_id'] == submissionId) {
          submission['status'] = 'rejected';
          submission['admin_id'] = _adminId;
          submission['admin_notes'] = notes;
          submission['reviewed_at'] = Timestamp.now();
          break;
        }
      }

      // User can resubmit, so status goes back to in_progress
      await docRef.update({
        'submissions': submissions,
        'status': 'in_progress',
        'current_progress': FieldValue.increment(-1),
      });

      //  CREATE NOTIFICATION
      await _notificationService.createNotification(
        userId: userId,
        type: 'challenge_rejected',
        title: 'Submission Rejected',
        message: 'One of your challenge submissions was rejected. Reason: $notes',
        relatedId: userChallengeId,
        additionalData: {
          'rejection_reason': notes,
        },
      );

      print('✅ Submission rejected and notification sent');
    } catch (e) {
      print('❌ Error rejecting submission: $e');
    }
  }

  // ==================== LOCATIONS ====================

  Stream<QuerySnapshot> getAllLocations() {
    return _db.collection('locations').snapshots();
  }

  Future<void> addLocation(Map<String, dynamic> data) async {
    await _db.collection('locations').add({
      ...data,
      'added_by': _adminId,
      'created_at': FieldValue.serverTimestamp(),
      'approval_status': 'approved',
    });
  }

  Future<void> updateLocation(String locationId, Map<String, dynamic> data) async {
    await _db.collection('locations').doc(locationId).update(data);
  }

  Future<void> deleteLocation(String locationId) async {
    await _db.collection('locations').doc(locationId).delete();
  }

  // ==================== DASHBOARD STATS ====================

  Future<Map<String, int>> getDashboardStats() async {
    try {
      final pendingItems = await _db.collection('items')
          .where('approval_status', isEqualTo: 'pending')
          .get();

      final pendingClaims = await _db.collection('rewardClaims')
          .where('status', isEqualTo: 'pending')
          .get();

      final users = await _db.collection('users').get();

      final locations = await _db.collection('locations').get();

      final totalDetections = await _db.collection('wasteDetections').get();

      //  ADD THIS LINE - Count pending feedback
      final pendingFeedback = await _db.collection('feedback')
          .where('status', isEqualTo: 'pending')
          .get();

      return {
        'pending_items': pendingItems.docs.length,
        'pending_claims': pendingClaims.docs.length,
        'total_users': users.docs.length,
        'total_locations': locations.docs.length,
        'total_detections': totalDetections.docs.length,
        'pending_feedback': pendingFeedback.docs.length,
      };
    } catch (e) {
      return {
        'pending_items': 0,
        'pending_claims': 0,
        'total_users': 0,
        'total_locations': 0,
        'total_detections': 0,
        'pending_feedback': 0,
      };
    }
  }

  // ==================== WASTE DETECTIONS (Admin) ====================

  /// Get all waste detections (for admin to review)
  Stream<QuerySnapshot> getAllDetections() {
    return _db.collection('wasteDetections')
        .orderBy('upload_date', descending: true)
        .snapshots();
  }

  /// Get detections by status
  Stream<QuerySnapshot> getDetectionsByStatus(String status) {
    return _db.collection('wasteDetections')
        .where('status', isEqualTo: status)
        .orderBy('upload_date', descending: true)
        .snapshots();
  }

  /// Delete a detection (if needed)
  Future<void> deleteDetection(String detectionId) async {
    try {
      await _db.collection('wasteDetections').doc(detectionId).delete();
    } catch (e) {
      print('Error deleting detection: $e');
      rethrow;
    }
  }

  // ==================== DISPOSAL RECOMMENDATIONS (Admin CRUD) ====================

  /// Get all disposal recommendations
  Stream<QuerySnapshot> getAllDisposalRecommendations() {
    return _db.collection('disposalRecommendations').snapshots();
  }

  /// Add new disposal recommendation
  Future<void> addDisposalRecommendation(Map<String, dynamic> data) async {
    try {
      final wasteType = data['waste_type'];
      await _db.collection('disposalRecommendations').doc(wasteType).set({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding disposal recommendation: $e');
      rethrow;
    }
  }

  /// Update disposal recommendation
  Future<void> updateDisposalRecommendation(String wasteType, Map<String, dynamic> data) async {
    try {
      await _db.collection('disposalRecommendations').doc(wasteType).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating disposal recommendation: $e');
      rethrow;
    }
  }

  /// Delete disposal recommendation
  Future<void> deleteDisposalRecommendation(String wasteType) async {
    try {
      await _db.collection('disposalRecommendations').doc(wasteType).delete();
    } catch (e) {
      print('Error deleting disposal recommendation: $e');
      rethrow;
    }
  }
}