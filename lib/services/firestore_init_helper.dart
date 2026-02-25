// lib/services/firestore_init_helper.dart
// Helper file to initialize Firestore with sample data
// Place this file in: lib/services/firestore_init_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreInitHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize sample data in Firestore (run once)
  static Future<void> initializeSampleData() async {
    try {
      print('🚀 Starting Firestore initialization...');

      await _createDisposalRecommendations();
      await _createSampleRewards();
      await _createSampleChallenges();
      await _createSampleLocations();

      print('✅ Firestore initialization complete!');
    } catch (e) {
      print('❌ Error initializing Firestore: $e');
    }
  }

  /// Create disposal recommendations (static data)
  static Future<void> _createDisposalRecommendations() async {
    final recommendations = [
      {
        'waste_type': 'plastic',
        'recommendation_text':
        'Rinse plastic containers before recycling. Remove labels if possible.',
        'tips': [
          'Clean and dry plastic items',
          'Check recycling symbols (1-7)',
          'Avoid contaminated plastics',
          'Flatten bottles to save space'
        ]
      },
      {
        'waste_type': 'paper',
        'recommendation_text':
        'Keep paper dry and clean. Cardboard should be flattened.',
        'tips': [
          'Remove plastic windows from envelopes',
          'Flatten cardboard boxes',
          'No greasy or wet paper',
          'Newspaper and magazines are recyclable'
        ]
      },
      {
        'waste_type': 'glass',
        'recommendation_text':
        'Rinse glass bottles and jars. Remove metal lids.',
        'tips': [
          'Rinse before recycling',
          'Remove metal caps and lids',
          'No broken glass in recycling',
          'Separate by color if required'
        ]
      },
      {
        'waste_type': 'metal',
        'recommendation_text':
        'Aluminum cans and metal containers are highly recyclable.',
        'tips': [
          'Rinse food cans',
          'Crush cans to save space',
          'Remove paper labels',
          'Aluminum is infinitely recyclable'
        ]
      },
      {
        'waste_type': 'organic',
        'recommendation_text':
        'Compost organic waste or dispose in designated bins.',
        'tips': [
          'Start a compost bin',
          'Avoid meat and dairy in compost',
          'Use for garden fertilizer',
          'Separate from other waste'
        ]
      },
    ];

    for (var rec in recommendations) {
      await _firestore.collection('disposalRecommendations').add(rec);
    }
    print('✅ Disposal recommendations created');
  }

  /// Create sample rewards
  static Future<void> _createSampleRewards() async {
    final rewards = [
      {
        'title': 'RM5 E-Wallet Voucher',
        'description': 'Redeem RM5 credit for your e-wallet',
        'points_required': 100,
        'status': 'active',
        'quantity_available': 50,
        'added_by': 'system',
      },
      {
        'title': 'RM10 Shopping Voucher',
        'description': 'Use at participating stores',
        'points_required': 200,
        'status': 'active',
        'quantity_available': 30,
        'added_by': 'system',
      },
      {
        'title': 'Eco-Friendly Tote Bag',
        'description': 'Reusable shopping bag',
        'points_required': 150,
        'status': 'active',
        'quantity_available': 20,
        'added_by': 'system',
      },
      {
        'title': 'RecyLink T-Shirt',
        'description': 'Official RecyLink merchandise',
        'points_required': 300,
        'status': 'active',
        'quantity_available': 15,
        'added_by': 'system',
      },
    ];

    for (var reward in rewards) {
      await _firestore.collection('rewards').add(reward);
    }
    print('✅ Sample rewards created');
  }

  /// Create sample challenges
  static Future<void> _createSampleChallenges() async {
    final now = Timestamp.now();
    final thirtyDaysLater = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)));

    final challenges = [
      {
        'title': 'Recycle 10 Items',
        'description':
        'Submit 10 recyclable items for verification this month',
        'points_reward': 100,
        'start_date': now,
        'end_date': thirtyDaysLater,
        'added_by': 'system',
        'status': 'active',
        'participants_count': 0,
      },
      {
        'title': 'Weekly Recycler',
        'description': 'Recycle at least once every week for a month',
        'points_reward': 150,
        'start_date': now,
        'end_date': thirtyDaysLater,
        'added_by': 'system',
        'status': 'active',
        'participants_count': 0,
      },
      {
        'title': 'Plastic Free Week',
        'description': 'Submit only non-plastic recyclables for 7 days',
        'points_reward': 200,
        'start_date': now,
        'end_date': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7))),
        'added_by': 'system',
        'status': 'active',
        'participants_count': 0,
      },
    ];

    for (var challenge in challenges) {
      await _firestore.collection('challenges').add(challenge);
    }
    print('✅ Sample challenges created');
  }

  /// Create sample recycling locations
  static Future<void> _createSampleLocations() async {
    final locations = [
      {
        'location_name': 'PJ Recycling Center',
        'address': '123 Jalan SS2, Petaling Jaya, Selangor',
        'operating_hours': 'Mon-Fri: 9AM-6PM, Sat: 9AM-1PM',
        'contact_num': 60312345678,
        'description': 'Full-service recycling center accepting all materials',
        'approval_status': 'approved',
        'added_by': 'system',
        'latitude': 3.1148,
        'longitude': 101.6280,
      },
      {
        'location_name': 'Sunway Pyramid Drop-Off Point',
        'address': '3 Jalan PJS 11/15, Bandar Sunway, Petaling Jaya',
        'operating_hours': 'Daily: 10AM-10PM',
        'contact_num': 60387654321,
        'description': 'Convenient drop-off point at the mall',
        'approval_status': 'approved',
        'added_by': 'system',
        'latitude': 3.0729,
        'longitude': 101.6068,
      },
      {
        'location_name': 'SS2 Community Recycling Bin',
        'address': 'SS2 Park, Petaling Jaya',
        'operating_hours': '24/7',
        'contact_num': 60300000000,
        'description': 'Community recycling bins for paper, plastic, and cans',
        'approval_status': 'approved',
        'added_by': 'system',
        'latitude': 3.1190,
        'longitude': 101.6262,
      },
    ];

    for (var location in locations) {
      await _firestore.collection('locations').add(location);
    }
    print('✅ Sample locations created');
  }

  /// Check if database is already initialized
  static Future<bool> isDatabaseInitialized() async {
    try {
      final snapshot = await _firestore
          .collection('disposalRecommendations')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Create user profile in Firestore (called after signup/login)
  static Future<void> createUserProfile({
    required String uid,
    required String email,
    String? username,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final exists = (await userDoc.get()).exists;

      if (!exists) {
        await userDoc.set({
          'username': username ?? email.split('@')[0],
          'email': email,
          'phone_number': phoneNumber ?? '',
          'points_balance': 0,
          'join_date': FieldValue.serverTimestamp(),
          'role': 'user',
          'profile_picture': profilePicture ?? '',
        });
        print('✅ User profile created for $email');
      }
    } catch (e) {
      print('❌ Error creating user profile: $e');
    }
  }

  /// Add points to user
  static Future<void> addPointsToUser(String userId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points_balance': FieldValue.increment(points),
      });
      print('✅ Added $points points to user $userId');
    } catch (e) {
      print('❌ Error adding points: $e');
    }
  }

  /// Deduct points from user
  static Future<void> deductPointsFromUser(String userId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points_balance': FieldValue.increment(-points),
      });
      print('✅ Deducted $points points from user $userId');
    } catch (e) {
      print('❌ Error deducting points: $e');
    }
  }

  /// Get user's current points
  static Future<int> getUserPoints(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['points_balance'] ?? 0;
    } catch (e) {
      print('❌ Error getting user points: $e');
      return 0;
    }
  }
}