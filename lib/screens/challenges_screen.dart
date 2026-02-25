import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'challenge_detail_screen.dart'; // NEW IMPORT

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Define common colors (consistent with other screens)
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _surfaceColor = const Color(0xFFF5F9F6);
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to show the "COMPLETED !!" pop-up
  void _showCompletedPopup(BuildContext context, int pointsEarned, {bool isRewardClaimed = false}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 5), () {
          if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        });

        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(30), //  Increased padding
                margin: const EdgeInsets.symmetric(horizontal: 30),
                constraints: const BoxConstraints(maxWidth: 400), //  Max width constraint
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25), //  More rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 28),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),

                    // Animated badge with better size
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'lib/assets/badge.png',
                              height: 120, //  Larger badge
                              width: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Congratulations text with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, opacity, child) {
                        return Opacity(
                          opacity: opacity,
                          child: Column(
                            children: [
                              Text(
                                isRewardClaimed ? 'REWARD CLAIMED!' : 'COMPLETED!',
                                style: const TextStyle(
                                  fontSize: 28, //  Larger title
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                isRewardClaimed
                                    ? 'Congrats! Your reward claim\nhas been submitted successfully!'
                                    : 'Congratulations!\nYou have received',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Points display (only for challenges)
                    if (!isRewardClaimed)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryGreen.withOpacity(0.8),
                                    _primaryGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryGreen.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 32, //  Larger star
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '+$pointsEarned',
                                    style: const TextStyle(
                                      fontSize: 32, //  Larger points text
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'points',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 25),

                    // Success icon at bottom
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor, // Mint background
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Rewards & Challenges',
          style: TextStyle(
            color: _primaryGreen,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. MODERN HEADER BANNER
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGreen, _primaryGreen.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Earn Exciting Rewards!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete challenges to unlock exclusive eco-friendly gifts.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Using your existing asset, but ensuring it fits
                Image.asset('lib/assets/personpoint.png', height: 90),
              ],
            ),
          ),

          // 2. STYLED TAB BAR
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Rewards', height: 40),
                Tab(text: 'Challenges', height: 40),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  color: _primaryGreen,
                  onRefresh: () async { setState(() {}); await Future.delayed(const Duration(milliseconds: 500)); },
                  child: _buildRewardsList(),
                ),
                RefreshIndicator(
                  color: _primaryGreen,
                  onRefresh: () async { setState(() {}); await Future.delayed(const Duration(milliseconds: 500)); },
                  child: _buildChallengesList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ✅ Build Challenges list with REAL progress tracking
  Widget _buildChallengesList() {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view challenges'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('challenges')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final challenges = snapshot.data?.docs ?? [];

        if (challenges.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No challenges available yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final doc = challenges[index];
            final data = doc.data() as Map<String, dynamic>;

            final challengeId = doc.id;
            final title = data['title'] ?? 'Challenge';
            final description = data['description'] ?? '';
            final pointsReward = data['points_reward'] ?? 0;
            final targetCount = data['target_count'] ?? 1;

            // Stream to get user's progress for this challenge
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('userChallenges')
                  .where('user_id', isEqualTo: userId)
                  .where('challenge_id', isEqualTo: challengeId)
                  .limit(1)
                  .snapshots(),
              builder: (context, userChallengeSnapshot) {
                bool hasStarted = false;
                int currentProgress = 0;
                String status = 'not_started';
                String? userChallengeId;

                if (userChallengeSnapshot.hasData && userChallengeSnapshot.data!.docs.isNotEmpty) {
                  hasStarted = true;
                  final userChallengeDoc = userChallengeSnapshot.data!.docs.first;
                  userChallengeId = userChallengeDoc.id;
                  final userChallengeData = userChallengeDoc.data() as Map<String, dynamic>;
                  currentProgress = userChallengeData['current_progress'] ?? 0;
                  status = userChallengeData['status'] ?? 'joined';
                }

                // ✅ HIDE completed challenges
                if (status == 'completed') {
                  return const SizedBox.shrink();
                }

                final progressPercentage = (currentProgress / targetCount * 100).clamp(0, 100).toInt();

                // ✅ NEW MODERN CARD DESIGN
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: hasStarted
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChallengeDetailScreen(
                              challengeId: challengeId,
                              userChallengeId: userChallengeId!,
                              challengeData: data,
                            ),
                          ),
                        );
                      }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon Bubble
                                // Icon Bubble
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events_rounded, // Trophy icon fits challenges perfectly
                                    size: 32,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (hasStarted)
                                        Text(
                                          'Progress: $currentProgress / $targetCount',
                                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                        )
                                      else
                                        Row(
                                          children: [
                                            Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$pointsReward Pts',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                // Progress Bar
                                if (hasStarted) ...[
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        minHeight: 10, // Thicker bar
                                        value: progressPercentage / 100,
                                        backgroundColor: Colors.grey[100],
                                        valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$progressPercentage%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                ] else
                                  const Spacer(),

                                const SizedBox(width: 10),
                                // Button (Keep your existing logic, just styled via the helper)
                                _buildChallengeButton(
                                  context,
                                  status,
                                  hasStarted,
                                  challengeId,
                                  userChallengeId,
                                  targetCount,
                                  pointsReward,
                                  data,
                                ),
                              ],
                            ),
                          ],
                        ),
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
  }

  Widget _buildChallengeButton(
      BuildContext context,
      String status,
      bool hasStarted,
      String challengeId,
      String? userChallengeId,
      int targetCount,
      int pointsReward,
      Map<String, dynamic> challengeData,
      ) {
    if (!hasStarted) {
      // User hasn't started the challenge yet
      return ElevatedButton(
        onPressed: () => _startChallenge(challengeId, targetCount),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        ),
        child: const Text(
          'Start',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }

    switch (status) {
      case 'joined':
      case 'in_progress':
      // User can submit items - navigate to detail screen
        return ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChallengeDetailScreen(
                  challengeId: challengeId,
                  userChallengeId: userChallengeId!,
                  challengeData: challengeData,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          ),
          child: const Text(
            'Submit Item',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        );

      case 'pending_review':
      // Waiting for admin approval
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Under Review',
            style: TextStyle(color: Colors.orange, fontSize: 14),
          ),
        );

      case 'completed':
      // Challenge completed and points awarded
        return ElevatedButton(
          onPressed: () {
            _showCompletedPopup(context, pointsReward);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          ),
          child: const Text(
            'Claimed',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _startChallenge(String challengeId, int targetCount) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Create userChallenge document
      await _firestore.collection('userChallenges').add({
        'user_id': userId,
        'challenge_id': challengeId,
        'status': 'joined',
        'current_progress': 0,
        'target_count': targetCount,
        'submissions': [],
        'joined_date': FieldValue.serverTimestamp(),
      });

      // Increment participants count
      // await _firestore.collection('challenges').doc(challengeId).update({
      //   'participants_count': FieldValue.increment(1),
      // });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge started! Start submitting items.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting challenge: $e')),
        );
      }
    }
  }

  // ✅ Build Rewards list from Firebase
  Widget _buildRewardsList() {
    final userId = _auth.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: userId != null
          ? _firestore.collection('users').doc(userId).snapshots()
          : null,
      builder: (context, userSnapshot) {
        final userPoints = userSnapshot.data?.get('points_balance') ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('rewards')
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final rewards = snapshot.data?.docs ?? [];

            if (rewards.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No rewards available yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final doc = rewards[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = data['title'] ?? 'Reward';
                final description = data['description'] ?? '';
                final pointsRequired = data['points_required'] ?? 0;
                final quantityAvailable = data['quantity_available'] ?? 0;

                // Check if user has any pending/fulfilled claims for this reward
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('rewardClaims')
                      .where('user_id', isEqualTo: userId)
                      .where('reward_id', isEqualTo: doc.id)
                      .where('status', whereIn: ['pending', 'fulfilled'])
                      .snapshots(),
                  builder: (context, claimsSnapshot) {
                    // Calculate total pending/fulfilled quantity
                    int claimedQuantity = 0;
                    if (claimsSnapshot.hasData) {
                      for (var claimDoc in claimsSnapshot.data!.docs) {
                        final claimData = claimDoc.data() as Map<String, dynamic>;
                        claimedQuantity += (claimData['quantity'] ?? 1) as int;
                      }
                    }

                    // If user has claimed all available quantity, hide this reward
                    if (claimedQuantity >= quantityAvailable) {
                      return const SizedBox.shrink();
                    }

                    final remainingQuantity = quantityAvailable - claimedQuantity;
                    final canClaim = userPoints >= pointsRequired && remainingQuantity > 0;

                    // ... inside the builder ...
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reward Image / Icon
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: _primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.card_giftcard, size: 32, color: _primaryGreen),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$remainingQuantity left',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Cost Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber[100]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded, size: 16, color: Colors.amber[800]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$pointsRequired Pts',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Claim Button
                            if (canClaim)
                              ElevatedButton(
                                onPressed: () => _showQuantitySelector(
                                  context, doc.id, title, description,
                                  pointsRequired, remainingQuantity, userPoints, userId!,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                child: const Text(
                                  'Claim',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                            // Lock Icon if can't claim
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lock_outline, color: Colors.grey[400]),
                              ),
                          ],
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
    );
  }

  // NEW: Quantity selector dialog
  Future<void> _showQuantitySelector(
      BuildContext context,
      String rewardId,
      String title,
      String description,
      int pointsRequired,
      int maxQuantity,
      int userPoints,
      String userId,
      ) async {
    // Calculate max quantity user can afford
    final maxAffordable = (userPoints / pointsRequired).floor();
    final maxClaimable = maxAffordable < maxQuantity ? maxAffordable : maxQuantity;

    if (maxClaimable <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points')),
      );
      return;
    }

    int selectedQuantity = 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final totalCost = pointsRequired * selectedQuantity;

          return AlertDialog(
            title: Text('Claim $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                const SizedBox(height: 20),
                const Text(
                  'Select Quantity:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: selectedQuantity > 1
                          ? () => setState(() => selectedQuantity--)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$selectedQuantity',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: selectedQuantity < maxClaimable
                          ? () => setState(() => selectedQuantity++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Available: $maxQuantity | Max affordable: $maxAffordable',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Cost:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            '$totalCost points',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                ),
                child: const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    // Process the claim
    try {
      final totalCost = pointsRequired * selectedQuantity;

      // ✅ Changed to 'rewardClaims' (camelCase)
      await _firestore.collection('rewardClaims').add({
        'user_id': userId,
        'reward_id': rewardId,
        'reward_title': title,
        'reward_description': description,
        'points_cost': pointsRequired,
        'quantity': selectedQuantity, // ✅ Store quantity
        'total_cost': totalCost, // ✅ Store total cost
        'status': 'pending', // ✅ Wait for admin approval (Option B)
        'claim_date': FieldValue.serverTimestamp(),
      });

      // ✅ DO NOT deduct points yet - wait for admin approval (Option B)
      // Points will be deducted when admin approves via fulfillRewardClaim()

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reward claim submitted! ($selectedQuantity x $title)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Error claiming reward: $e');
    }
  }
}