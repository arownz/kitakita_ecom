import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

import '../utils/responsive_utils.dart';
import '../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.title,
    this.actions,
    this.showAppBar = true,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _isSidebarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            // Top header for desktop
            if (widget.showAppBar) _buildDesktopHeader(context),
            // Main content area with sidebar
            Expanded(
              child: Row(
                children: [
                  _buildDesktopSidebar(context),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF8F9FA),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: widget.showAppBar ? _buildMobileAppBar(context) : null,
        body: Container(color: const Color(0xFFF8F9FA), child: widget.child),
        bottomNavigationBar: _buildMobileBottomNav(context),
      );
    }
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Logo and title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/ecomlogo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'KitaKita',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 32),

            // Page title
            if (widget.title != null) ...[
              Container(height: 32, width: 1, color: const Color(0xFFE9ECEF)),
              const SizedBox(width: 16),
              Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],

            const Spacer(),

            // Header actions
            Row(
              children: [
                // Notifications
                _buildHeaderButton(
                  icon: Icons.notifications_outlined,
                  onTap: () => context.go(AppRoutes.notifications),
                  showBadge: true,
                ),

                const SizedBox(width: 8),

                // Settings
                _buildHeaderButton(
                  icon: Icons.settings_outlined,
                  onTap: () => context.go(AppRoutes.settings),
                ),

                const SizedBox(width: 16),

                // User avatar
                if (currentUser != null) ...[
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          currentUser.email?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Custom actions
                if (widget.actions != null) ...[
                  const SizedBox(width: 16),
                  ...widget.actions!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Center(
                child: Icon(icon, color: const Color(0xFF495057), size: 20),
              ),
              if (showBadge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 280 : 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: const Color(0xFFE9ECEF))),
      ),
      child: Column(
        children: [
          // Sidebar toggle
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_isSidebarExpanded) ...[
                  const Expanded(
                    child: Text(
                      'Navigation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF495057),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 40), // Fixed width instead of Expanded
                ],
                IconButton(
                  icon: Icon(
                    _isSidebarExpanded ? Icons.chevron_left : Icons.menu,
                    color: const Color(0xFF495057),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSidebarExpanded = !_isSidebarExpanded;
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE9ECEF)),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  isSelected: widget.currentIndex == 0,
                  onTap: () => context.go(AppRoutes.home),
                ),
                _buildSidebarItem(
                  icon: Icons.add_box_outlined,
                  selectedIcon: Icons.add_box,
                  label: 'Sell Product',
                  isSelected: widget.currentIndex == 1,
                  onTap: () => context.go(AppRoutes.addProduct),
                ),
                _buildSidebarItem(
                  icon: Icons.chat_bubble_outline,
                  selectedIcon: Icons.chat_bubble,
                  label: 'Messages',
                  isSelected: widget.currentIndex == 2,
                  onTap: () => context.go(AppRoutes.chatList),
                ),
                _buildSidebarItem(
                  icon: Icons.favorite_outline,
                  selectedIcon: Icons.favorite,
                  label: 'Favorites',
                  isSelected: widget.currentIndex == 3,
                  onTap: () => context.go(AppRoutes.favorites),
                ),
                _buildSidebarItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                  isSelected: widget.currentIndex == 4,
                  onTap: () => context.go(AppRoutes.profile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : const Color(0xFF6C757D),
                  size: 20,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryBlue
                            : const Color(0xFF495057),
                      ),
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

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
      title: widget.title != null
          ? Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/images/ecomlogo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'KitaKita',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      actions: [
        // Notifications
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 24),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => context.go(AppRoutes.notifications),
        ),

        // User avatar or login
        if (currentUser != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.profile),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    currentUser.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Custom actions
        if (widget.actions != null) ...widget.actions!,

        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: const Color(0xFF6C757D),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 24,
          currentIndex: widget.currentIndex,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Sell',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.addProduct);
        break;
      case 2:
        context.go(AppRoutes.chatList);
        break;
      case 3:
        context.go(AppRoutes.favorites);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }
}
