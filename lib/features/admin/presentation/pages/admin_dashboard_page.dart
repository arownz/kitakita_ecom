import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<AdminMenuItem> _menuItems = [
    AdminMenuItem(
      icon: Icons.dashboard,
      title: 'Dashboard',
      subtitle: 'Overview & Analytics',
    ),
    AdminMenuItem(
      icon: Icons.people,
      title: 'Users',
      subtitle: 'Manage Students',
    ),
    AdminMenuItem(
      icon: Icons.inventory,
      title: 'Products',
      subtitle: 'Product Management',
    ),
    AdminMenuItem(
      icon: Icons.report_problem,
      title: 'Reports',
      subtitle: 'User Reports & Safety',
    ),
    AdminMenuItem(
      icon: Icons.message,
      title: 'Messages',
      subtitle: 'Chat Monitoring',
    ),
    AdminMenuItem(
      icon: Icons.settings,
      title: 'Settings',
      subtitle: 'System Configuration',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (!ResponsiveUtils.isMobile(context)) _buildSidebar(context),

          // Main content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, currentUser),
                Expanded(child: _buildMainContent(context)),
              ],
            ),
          ),
        ],
      ),
      drawer: ResponsiveUtils.isMobile(context)
          ? _buildMobileSidebar(context)
          : null,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo section
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSizes.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KitaKita',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.lightBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.lightBlue, height: 1),

          // Menu items
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryYellow.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? AppColors.primaryYellow
                          : AppColors.lightBlue,
                    ),
                    title: Text(
                      item.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.primaryYellow
                            : AppColors.white,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.primaryYellow.withValues(alpha: 0.8)
                            : AppColors.lightBlue,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Logout button
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Sign Out',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(AppRoutes.landing);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar(BuildContext context) {
    return Drawer(child: _buildSidebar(context));
  }

  Widget _buildTopBar(BuildContext context, user) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (ResponsiveUtils.isMobile(context))
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _menuItems[_selectedIndex].title,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  _menuItems[_selectedIndex].subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),

          // Admin profile
          Row(
            children: [
              Text(
                'Admin',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSizes.spaceS),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  'A',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(context);
      case 1:
        return _buildUsersContent(context);
      case 2:
        return _buildProductsContent(context);
      case 3:
        return _buildReportsContent(context);
      case 4:
        return _buildMessagesContent(context);
      case 5:
        return _buildSettingsContent(context);
      default:
        return _buildDashboardContent(context);
    }
  }

  Widget _buildDashboardContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveUtils.isMobile(context) ? 2 : 4,
            crossAxisSpacing: AppSizes.spaceM,
            mainAxisSpacing: AppSizes.spaceM,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                title: 'Total Users',
                value: '1,234',
                icon: Icons.people,
                color: AppColors.primaryBlue,
                change: '+12%',
              ),
              _buildStatCard(
                title: 'Active Products',
                value: '856',
                icon: Icons.inventory,
                color: AppColors.success,
                change: '+8%',
              ),
              _buildStatCard(
                title: 'Reports',
                value: '23',
                icon: Icons.report_problem,
                color: AppColors.warning,
                change: '-3%',
              ),
              _buildStatCard(
                title: 'Transactions',
                value: '₱45,230',
                icon: Icons.monetization_on,
                color: AppColors.primaryYellow,
                change: '+15%',
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spaceXL),

          // Recent activity
          Text(
            'Recent Activity',
            style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
          ),

          const SizedBox(height: AppSizes.spaceM),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.person_add,
                    title: 'New user registered',
                    subtitle: 'Juan Dela Cruz joined the platform',
                    time: '2 minutes ago',
                  ),
                  const Divider(),
                  _buildActivityItem(
                    icon: Icons.report,
                    title: 'New report submitted',
                    subtitle: 'Suspicious product reported',
                    time: '15 minutes ago',
                  ),
                  const Divider(),
                  _buildActivityItem(
                    icon: Icons.shopping_cart,
                    title: 'Product listed',
                    subtitle: 'Engineering Textbook added',
                    time: '1 hour ago',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  change,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: change.startsWith('+')
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.primaryBlue, size: 20),
      ),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: Text(
        time,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
      ),
    );
  }

  Widget _buildUsersContent(BuildContext context) {
    return const Center(child: Text('Users Management - Coming Soon'));
  }

  Widget _buildProductsContent(BuildContext context) {
    return const Center(child: Text('Products Management - Coming Soon'));
  }

  Widget _buildReportsContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reports summary
          Text(
            'Safety Reports Management',
            style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildReportCard('Pending', '23', AppColors.warning),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: _buildReportCard('Resolved', '145', AppColors.success),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: _buildReportCard('Blocked', '8', AppColors.error),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spaceXL),

          // Recent reports
          Card(
            child: Column(
              children: [
                _buildReportListItem(
                  'Scam Report',
                  'John Doe vs. FakeSeller',
                  'Pending',
                ),
                const Divider(),
                _buildReportListItem(
                  'Spam Messages',
                  'Maria vs. SpamAccount',
                  'Under Review',
                ),
                const Divider(),
                _buildReportListItem(
                  'Inappropriate Content',
                  'Anna vs. BadUser',
                  'Resolved',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          children: [
            Text(
              count,
              style: AppTextStyles.h2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildReportListItem(String type, String details, String status) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.error,
        child: Icon(Icons.report, color: Colors.white),
      ),
      title: Text(type),
      subtitle: Text(details),
      trailing: Chip(
        label: Text(status),
        backgroundColor: status == 'Pending'
            ? AppColors.warning
            : status == 'Resolved'
            ? AppColors.success
            : AppColors.primaryBlue,
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report details - Feature coming soon')),
        );
      },
    );
  }

  Widget _buildMessagesContent(BuildContext context) {
    return const Center(child: Text('Messages Monitoring - Coming Soon'));
  }

  Widget _buildSettingsContent(BuildContext context) {
    return const Center(child: Text('Settings - Coming Soon'));
  }
}

class AdminMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;

  AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
