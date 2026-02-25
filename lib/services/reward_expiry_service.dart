import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recylink/services/notification_service.dart';

class RewardExpiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Check for rewards expiring soon (within 3 days) and create notifications
  Future<void> checkExpiringRewards(String userId) async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));

      final expiringRewards = await _firestore
          .collection('rewardClaims')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'fulfilled')
          .get();

      for (var doc in expiringRewards.docs) {
        final data = doc.data();
        final expiryDate = (data['expiry_date'] as Timestamp?)?.toDate();
        final notifiedExpiring = data['notified_expiring'] ?? false;

        if (expiryDate != null && !notifiedExpiring) {
          // Check if expiring within 3 days
          if (expiryDate.isAfter(now) && expiryDate.isBefore(threeDaysFromNow)) {
            final daysLeft = expiryDate.difference(now).inDays;
            final rewardTitle = data['reward_title'] ?? 'Your reward';

            await _notificationService.createNotification(
              userId: userId,
              type: 'reward_expiring_soon',
              title: 'Reward Expiring Soon! ⏰',
              message: '$rewardTitle will expire in $daysLeft day${daysLeft > 1 ? 's' : ''}. Redeem it soon!',
              relatedId: doc.id,
              additionalData: {
                'reward_title': rewardTitle,
                'days_left': daysLeft,
                'expiry_date': expiryDate.toIso8601String(),
              },
            );

            // Mark as notified
            await _firestore.collection('rewardClaims').doc(doc.id).update({
              'notified_expiring': true,
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error checking expiring rewards: $e');
    }
  }

  /// Check for expired rewards and create notifications
  Future<void> checkExpiredRewards(String userId) async {
    try {
      final now = DateTime.now();

      final expiredRewards = await _firestore
          .collection('rewardClaims')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'fulfilled')
          .get();

      for (var doc in expiredRewards.docs) {
        final data = doc.data();
        final expiryDate = (data['expiry_date'] as Timestamp?)?.toDate();
        final notifiedExpired = data['notified_expired'] ?? false;

        if (expiryDate != null && !notifiedExpired) {
          // Check if expired
          if (expiryDate.isBefore(now)) {
            final rewardTitle = data['reward_title'] ?? 'Your reward';

            await _notificationService.createNotification(
              userId: userId,
              type: 'reward_expired',
              title: 'Reward Expired',
              message: 'Your $rewardTitle has expired and can no longer be redeemed.',
              relatedId: doc.id,
              additionalData: {
                'reward_title': rewardTitle,
                'expiry_date': expiryDate.toIso8601String(),
              },
            );

            // Mark as expired
            await _firestore.collection('rewardClaims').doc(doc.id).update({
              'status': 'expired',
              'notified_expired': true,
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error checking expired rewards: $e');
    }
  }
}