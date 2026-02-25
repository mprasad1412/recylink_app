import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:recylink/screens/home_screen.dart';
import 'package:recylink/screens/location_screen.dart';
import 'package:recylink/screens/camera_screen.dart';
import 'package:recylink/screens/challenges_screen.dart';
import 'package:recylink/screens/marketplace_home_screen.dart';

// ✅ GLOBAL KEY for external navigation
final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  MainScreen({required this.cameras}) : super(key: mainScreenKey);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  // Matching your Home Screen colors
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _accentGreen = const Color(0xFFAEE55B);

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      const HomeScreen(),
      const LocationScreen(),
      CameraScreen(cameras: widget.cameras),
      const ChallengesScreen(),
      const MarketplaceHomeScreen(),
    ];
  }

  // ✅ Method to switch tabs from external widgets
  void switchToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onItemTapped(int index) {
    // If the Camera button (Index 2) is tapped...
    if (index == 2) {
      // ...Push the CameraScreen as a full-screen modal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(cameras: widget.cameras),
        ),
      );
    } else {
      // For other tabs, switch as normal
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Handle back button - exit app confirmation on home tab
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // If on home tab, show exit confirmation
        if (_selectedIndex == 0) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Exit App'),
              content: const Text('Do you want to exit RecyLink?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Exit', style: TextStyle(color: _primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        } else {
          // If not on home tab, go back to home tab
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        // extendBody allows content to slide behind the navbar if you add transparency
        extendBody: true,
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            elevation: 0, // We handle elevation in the Container above
            selectedItemColor: _primaryGreen,
            unselectedItemColor: Colors.grey[400],
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: <BottomNavigationBarItem>[
              // 1. HOME
              BottomNavigationBarItem(
                icon: _buildIcon('lib/assets/homeicon.png', 0),
                label: 'Home',
              ),
              // 2. LOCATION
              BottomNavigationBarItem(
                icon: _buildIcon('lib/assets/locationicon.png', 1),
                label: 'Location',
              ),
              // 3. CAMERA (Special Center Button)
              BottomNavigationBarItem(
                icon: Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentGreen, // The bright lime green for pop
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accentGreen.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'lib/assets/camera.png',
                    height: 28,
                    width: 28,
                    color: Colors.white, // Icon inside circle is white
                  ),
                ),
                label: '', // No label for camera
              ),
              // 4. CHALLENGE
              BottomNavigationBarItem(
                icon: _buildIcon('lib/assets/challengeicon.png', 3),
                label: 'Challenge',
              ),
              // 5. SHOP
              BottomNavigationBarItem(
                icon: _buildIcon('lib/assets/marketplace.png', 4),
                label: 'Shop',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to tint icons correctly
  Widget _buildIcon(String assetPath, int index) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Image.asset(
        assetPath,
        height: 24,
        // If selected, use Primary Green. If not, use Grey.
        color: isSelected ? _primaryGreen : Colors.grey[400],
      ),
    );
  }
}