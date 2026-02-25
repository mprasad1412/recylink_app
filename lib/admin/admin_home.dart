import 'package:flutter/material.dart';
import 'widgets/app_sidebar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/ai_detection_screen.dart';
import 'screens/feedback_management_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const DashboardScreen(),      // 0
    const MarketplaceScreen(),    // 1
    const RewardsScreen(),        // 2
    const ChallengeScreen(),      // 3
    const LocationsScreen(),      // 4
    const AIDetectionScreen(),    // 5
    const FeedbackManagementScreen(), // 6
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Define breakpoint for mobile/tablet
        final bool isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          key: _scaffoldKey,
          // Mobile: Add AppBar with Hamburger Menu
          appBar: isDesktop
              ? null
              : AppBar(
            // Theme handles colors, but we specify here for clarity
            title: Row(
              children: [
                Icon(Icons.recycling, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'RecyLink Admin',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: Icon(Icons.menu, color: theme.primaryColor),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          // Mobile: Use Drawer
          drawer: isDesktop
              ? null
              : Drawer(
            width: 250,
            backgroundColor: Colors.white, // Ensure drawer is white
            child: AppSidebar(
              selectedIndex: _selectedIndex,
              isCollapsed: false,
              isMobile: true,
              onToggle: () {},
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              },
            ),
          ),
          body: Row(
            children: [
              // Desktop: Permanent Sidebar
              if (isDesktop)
                AppSidebar(
                  selectedIndex: _selectedIndex,
                  isCollapsed: _isSidebarCollapsed,
                  isMobile: false,
                  onItemSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  onToggle: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                ),

              // Main Content
              Expanded(
                child: Container(
                  // Use the Mint-ish surface color from theme
                  color: theme.scaffoldBackgroundColor,
                  // Add padding to separate content from sidebar
                  child: _screens[_selectedIndex],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}