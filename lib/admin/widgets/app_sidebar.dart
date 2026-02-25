import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onToggle;
  final bool isCollapsed;
  final bool isMobile;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onToggle,
    this.isCollapsed = false,
    this.isMobile = false,
  });

  // THEME CONSTANTS
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFFAEE55B);

  @override
  Widget build(BuildContext context) {
    // Determine width
    final double width = isMobile ? 250 : (isCollapsed ? 80 : 260);
    // Dynamic padding: Use less padding when collapsed to avoid scrollbar overflow
    final double horizontalPadding = (isCollapsed && !isMobile) ? 8 : 12;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header / Logo Area
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: (isCollapsed && !isMobile)
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (!isCollapsed || isMobile) const SizedBox(width: 24),

                // Logo Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.recycling, color: primaryGreen, size: 28),
                ),

                // App Name (Hidden if collapsed)
                if (!isCollapsed || isMobile) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'RecyLink',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],

                // Collapse Button (Desktop Only)
                if (!isMobile && !isCollapsed)
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: Colors.grey[400]),
                    onPressed: onToggle,
                  ),
              ],
            ),
          ),

          // Collapse Trigger for Collapsed State
          if (isCollapsed && !isMobile)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IconButton(
                icon: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onPressed: onToggle,
              ),
            ),

          // Navigation Items
          Expanded(
            child: ListView(
              // FIXED: Reduced horizontal padding to prevent overflow
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              children: [
                _buildNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, title: 'Dashboard', index: 0),
                _buildNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, title: 'Marketplace', index: 1),
                _buildNavItem(icon: Icons.card_giftcard_outlined, activeIcon: Icons.card_giftcard, title: 'Rewards', index: 2),
                _buildNavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, title: 'Challenges', index: 3),
                _buildNavItem(icon: Icons.map_outlined, activeIcon: Icons.map, title: 'Locations', index: 4),
                _buildNavItem(icon: Icons.qr_code_scanner, activeIcon: Icons.qr_code_scanner, title: 'AI Detection', index: 5),
                _buildNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, title: 'Feedback', index: 6),
              ],
            ),
          ),

          // Sign Out
          Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: _buildNavItem(
              icon: Icons.logout,
              activeIcon: Icons.logout,
              title: 'Sign Out',
              index: 99,
              isLogOut: true,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
    bool isLogOut = false,
  }) {
    final isSelected = selectedIndex == index;
    final bool isCompact = (isCollapsed && !isMobile);

    // Logic for "Active" State
    final Color backgroundColor = isSelected ? primaryGreen : Colors.transparent;
    final Color foregroundColor = isSelected ? Colors.white : Colors.grey[600]!;
    final IconData displayIcon = isSelected ? activeIcon : icon;
    final FontWeight fontWeight = isSelected ? FontWeight.w600 : FontWeight.normal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLogOut
              ? () async { await AdminAuthService().signOut(); }
              : () => onItemSelected(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            // FIXED: Tighter padding in compact mode to ensure icon fits
            padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: isCompact ? 8 : 12
            ),
            decoration: BoxDecoration(
              color: isLogOut ? Colors.red[50] : backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: isCompact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  displayIcon,
                  color: isLogOut ? Colors.red : foregroundColor,
                  size: 24,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isLogOut ? Colors.red : foregroundColor,
                        fontWeight: fontWeight,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}