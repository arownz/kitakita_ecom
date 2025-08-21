import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _salesNotifications = true;
  bool _messageNotifications = true;
  bool _darkMode = false;
  bool _isLoading = true;
  bool _profileVisibility = true;
  bool _allowMessages = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _salesNotifications = prefs.getBool('sales_notifications') ?? true;
        _messageNotifications = prefs.getBool('message_notifications') ?? true;
        _darkMode = prefs.getBool('dark_mode') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newController.text.trim().length < 6 ||
                  newController.text.trim() != confirmController.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match or too short'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              try {
                await SupabaseService.client.auth.updateUser(
                  UserAttributes(password: newController.text.trim()),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to change password: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSizes.paddingM,
            right: AppSizes.paddingM,
            top: AppSizes.paddingM,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppSizes.paddingM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Settings',
                style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
              ),
              const SizedBox(height: AppSizes.spaceM),
              SwitchListTile(
                title: const Text('Public Profile'),
                subtitle: const Text('Allow others to view your profile'),
                value: _profileVisibility,
                onChanged: (val) {
                  setState(() => _profileVisibility = val);
                  _saveSetting('profile_visible', val);
                },
              ),
              SwitchListTile(
                title: const Text('Allow Messages'),
                subtitle: const Text('Allow others to message you'),
                value: _allowMessages,
                onChanged: (val) {
                  setState(() => _allowMessages = val);
                  _saveSetting('allow_messages', val);
                },
              ),
              const SizedBox(height: AppSizes.spaceM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDataExportDialog() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Fetch user's products and favorites
      final products = await SupabaseService.from(
        'products',
      ).select('*').eq('seller_id', user.id);
      final favorites = await SupabaseService.from(
        'user_favorites',
      ).select('*').eq('user_id', user.id);

      final export = {
        'profile': user.userMetadata,
        'products': products,
        'favorites': favorites,
      };

      final controller = TextEditingController(text: export.toString());

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data (JSON-like)'),
          content: SizedBox(
            width: 500,
            child: TextField(
              controller: controller,
              maxLines: 12,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);

      // Also save to Supabase user preferences if user is logged in
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await SupabaseService.from(
          'user_profiles',
        ).update({key: value}).eq('user_id', user.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save setting: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.spaceL),

                  // Notification Settings
                  _buildSectionHeader('Notifications'),
                  _buildNotificationSettings(),

                  const SizedBox(height: AppSizes.spaceXL),

                  // App Settings
                  _buildSectionHeader('App Settings'),
                  _buildAppSettings(),

                  const SizedBox(height: AppSizes.spaceXL),

                  // Account Settings
                  _buildSectionHeader('Account'),
                  _buildAccountSettings(),

                  const SizedBox(height: AppSizes.spaceXXL),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceM),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
              _saveSetting('push_notifications', value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
              _saveSetting('email_notifications', value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            title: 'Sales Notifications',
            subtitle: 'Get notified about sales and promotions',
            value: _salesNotifications,
            onChanged: (value) {
              setState(() {
                _salesNotifications = value;
              });
              _saveSetting('sales_notifications', value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            title: 'Message Notifications',
            subtitle: 'Get notified about new messages',
            value: _messageNotifications,
            onChanged: (value) {
              setState(() {
                _messageNotifications = value;
              });
              _saveSetting('message_notifications', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Dark Mode',
            subtitle: 'Use dark theme for the app',
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              _saveSetting('dark_mode', value);
              // Apply theme immediately via provider
              ref.read(themeControllerProvider.notifier).setDarkMode(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildListTile(
            title: 'Change Password',
            subtitle: 'Update your account password',
            icon: Icons.lock_outline,
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Privacy Settings',
            subtitle: 'Manage your privacy preferences',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              _showPrivacySettingsSheet();
            },
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Data Export',
            subtitle: 'Export your data',
            icon: Icons.download_outlined,
            onTap: () {
              _showDataExportDialog();
            },
          ),
          _buildDivider(),
          _buildListTile(
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            icon: Icons.delete_forever_outlined,
            onTap: () {
              _showDeleteAccountDialog();
            },
            textColor: AppColors.error,
            iconColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primaryBlue),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: textColor ?? AppColors.textGray,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textGray,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.borderGray.withValues(alpha: 0.3),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        // Delete user profile
        await SupabaseService.from(
          'user_profiles',
        ).delete().eq('user_id', user.id);

        // Delete user from Supabase Auth
        await SupabaseService.client.auth.admin.deleteUser(user.id);

        // Sign out and redirect
        ref.read(authProvider.notifier).signOut();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
