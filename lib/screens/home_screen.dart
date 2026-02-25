import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recylink/services/notification_service.dart';
import 'package:recylink/screens/unified_notifications_screen.dart';
import 'package:recylink/services/reward_expiry_service.dart';

import 'challenges_screen.dart';
import 'dashboard_screen.dart';
import 'main_screen.dart';
import 'marketplace_home_screen.dart';
import 'auth_screen.dart';
import 'material_awareness_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Color Palette - Modern Eco Theme
  final Color _primaryGreen = const Color(0xFF2E7D32); // Darker, professional green
  final Color _accentGreen = const Color(0xFFAEE55B); // Your original lime for highlights
  final Color _surfaceColor = const Color(0xFFF5F9F6); // Very light mint/grey
  final Color _cardColor = Colors.white;

  String _userName = 'User';
  int _userPoints = 0;
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
          setState(() {
            _userName = data?['username'] ?? user.displayName ?? 'User';
            _userPoints = data?['points_balance'] ?? 0;
            _profileImageUrl = data?['profile_picture'];
            _isLoading = false;
          });

          // Check rewards
          final expiryService = RewardExpiryService();
          await expiryService.checkExpiringRewards(user.uid);
          await expiryService.checkExpiredRewards(user.uid);
        } else {
          setState(() {
            _userName = user.displayName ?? 'User';
            _userPoints = 0;
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

  // RECYCLED GUIDE DATA
  final List<Map<String, String>> recyclingGuideData = [
    {'icon': 'lib/assets/plasticicon.png', 'material': 'Plastic'},
    {'icon': 'lib/assets/papericon.png', 'material': 'Paper'},
    {'icon': 'lib/assets/glassicon.png', 'material': 'Glass'},
    {'icon': 'lib/assets/metalicon.png', 'material': 'Metal'},
    {'icon': 'lib/assets/e-wasteicon.png', 'material': 'E-waste'},
    {'icon': 'lib/assets/textilesicon.png', 'material': 'Textiles'},
    {'icon': 'lib/assets/organicon.png', 'material': 'Organic'},
  ];

  @override
  Widget build(BuildContext context) {
    // Set status bar to dark icons for white background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _surfaceColor,
      // Custom Modern AppBar
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Assuming your logo has a transparent background
            Image.asset('lib/assets/logo.png', height: 70),
            const SizedBox(width: 8),
            Text(
              'RECYLINK',
              style: TextStyle(
                color: _primaryGreen,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          _buildNotificationIcon(),
          const SizedBox(width: 10),
          _buildProfileDropdown(),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen)))
          : RefreshIndicator(
        onRefresh: _loadUserData,
        color: _primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section (Greetings + Points)
              _buildModernHeader(),

              const SizedBox(height: 50),

              // 2. Section Title
              Text(
                'Recycling Guide',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 15),

              // 3. Modern Horizontal List (Replaces PageView)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: recyclingGuideData.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _buildCategoryChip(
                      recyclingGuideData[index]['icon']!,
                      recyclingGuideData[index]['material']!,
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // 4. Community/Impact Card
              _buildImpactCard(),

              const SizedBox(height: 30),

              // 5. Action Cards
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 25),

              // Vertical layout for cards is often cleaner than horizontal for major actions
              // Or keep horizontal if you prefer scrolling
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildModernActionCard(
                      color: const Color(0xFFC8E6C9), // Light Green
                      title: 'Recycle Today',
                      subtitle: 'EARN 100 PTS',
                      imagePath: 'lib/assets/holdingbottle.png',
                      btnText: 'Earn Now',
                      onTap: () => mainScreenKey.currentState?.switchToTab(3),
                    ),
                    const SizedBox(width: 16),
                    _buildModernActionCard(
                      color: const Color(0xFFFFF9C4), // Light Yellow
                      title: 'Sell Your Upcycled Items',
                      subtitle: 'GET CASH PACK',
                      imagePath: 'lib/assets/markethome.png',
                      btnText: 'Marketplace',
                      onTap: () => mainScreenKey.currentState?.switchToTab(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 90), // Bottom padding for scrolling
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Gradient for a premium feel
        gradient: LinearGradient(
          colors: [_primaryGreen, _primaryGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Points Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Image.asset('lib/assets/star.png', height: 20), // Ensure this asset is white or bright
                    const SizedBox(width: 8),
                    Text(
                      '$_userPoints Pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Let's make the world cleaner, one step at a time.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String iconPath, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialAwarenessScreen(material: label),
          ),
        );
      },
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 45,
              width: 45,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Image.asset(iconPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Impact'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'See what we are achieving together.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {}, // Handle impact tap
                  child: Row(
                    children: [
                      Text(
                        'Explore the app',
                        style: TextStyle(
                          color: _primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      // Icon(Icons.arrow_forward_rounded, size: 16, color: _primaryGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'lib/assets/globe.png',
            height: 80,
            width: 80,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard({
    required Color color,
    required String title,
    required String subtitle,
    required String imagePath,
    required String btnText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -20,
            bottom: -20,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(btnText),
                ),
              ],
            ),
          ),

          // Image positioned
          Positioned(
            right: 10,
            bottom: 30, // Moved up slightly to not overlap button area
            child: Image.asset(
              imagePath,
              height: 150,
              width: 150,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<int>(
      stream: _auth.currentUser != null
          ? _notificationService.getUnreadCount(_auth.currentUser!.uid)
          : Stream.value(0),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UnifiedNotificationsScreen(),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileDropdown() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45), // Moves the menu down slightly
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(2), // Border width
        decoration: BoxDecoration(
          color: _primaryGreen,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey[200],
          backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
              ? NetworkImage(_profileImageUrl!)
              : const AssetImage('lib/assets/profilr.png') as ImageProvider,
        ),
      ),
      onSelected: (String result) async {
        if (result == 'dashboard') {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
          _loadUserData();
        } else if (result == 'logout') {
          await _auth.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'dashboard',
          child: Row(children: [Icon(Icons.person, color: Colors.black54), SizedBox(width: 8), Text('Dashboard')]),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Log Out')]),
        ),
      ],
    );
  }
}