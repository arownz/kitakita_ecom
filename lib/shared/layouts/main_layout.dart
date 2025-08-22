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

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final currentUser = ref.watch(currentUserProvider);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopNavRail(context),
            Expanded(child: widget.child),
          ],
        ),
        floatingActionButton: currentUser != null
            ? FloatingActionButton(
                onPressed: () => context.go(AppRoutes.addProduct),
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.black,
                child: const Icon(Icons.add),
              )
            : null,
      );
    } else {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: _buildMobileBottomNav(context),
        floatingActionButton: currentUser != null
            ? FloatingActionButton(
                onPressed: () => context.go(AppRoutes.addProduct),
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.black,
                child: const Icon(Icons.add),
              )
            : null,
      );
    }
  }

  Widget _buildDesktopNavRail(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 280 : 80,
      child: NavigationRail(
        selectedIndex: widget.currentIndex,
        backgroundColor: AppColors.white,
        extended: _isSidebarExpanded,
        leading: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                if (_isSidebarExpanded) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/ecomlogo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'KitaKita',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isSidebarExpanded
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: AppColors.primaryYellow,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSidebarExpanded = !_isSidebarExpanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: _isSidebarExpanded ? 240 : 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: MaterialButton(
                onPressed: () => context.go(AppRoutes.notifications),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                elevation: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    if (_isSidebarExpanded) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.home, color: AppColors.primaryBlue, size: 20),
            selectedIcon: Icon(Icons.home, color: AppColors.white, size: 20),
            label: Text('Home'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.add_box, color: AppColors.primaryBlue, size: 20),
            selectedIcon: Icon(Icons.add_box, color: AppColors.white, size: 20),
            label: Text('Sell'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.chat, color: AppColors.primaryBlue, size: 20),
            selectedIcon: Icon(Icons.chat, color: AppColors.white, size: 20),
            label: Text('Chat'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.favorite, color: AppColors.primaryBlue, size: 20),
            selectedIcon: Icon(
              Icons.favorite,
              color: AppColors.white,
              size: 20,
            ),
            label: Text('Favorites'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person, color: AppColors.primaryBlue, size: 20),
            selectedIcon: Icon(Icons.person, color: AppColors.white, size: 20),
            label: Text('Profile'),
          ),
        ],
        onDestinationSelected: _onNavItemTapped,
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
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
          unselectedItemColor: AppColors.textGray,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 24,
          currentIndex: widget.currentIndex,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Sell'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
