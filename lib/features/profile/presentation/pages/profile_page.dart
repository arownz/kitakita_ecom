import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/router/app_router.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final metadata = user.userMetadata ?? {};
      _firstNameController.text = metadata['first_name'] ?? '';
      _lastNameController.text = metadata['last_name'] ?? '';
      _studentIdController.text = metadata['student_id'] ?? '';
      _phoneController.text = metadata['phone_number'] ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: Text('Please log in to view your profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _loadUserData(); // Reset data if canceling edit
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.getScreenPadding(context),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.spaceL),

            // Profile Avatar
            _buildProfileAvatar(),

            const SizedBox(height: AppSizes.spaceXL),

            // Profile Form
            _buildProfileForm(),

            const SizedBox(height: AppSizes.spaceXL),

            // Action Buttons
            _buildActionButtons(context),

            const SizedBox(height: AppSizes.spaceXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final user = ref.read(currentUserProvider);
    final firstName = _firstNameController.text.isNotEmpty
        ? _firstNameController.text
        : user?.userMetadata?['first_name'] ?? '';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppSizes.spaceM),

          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppSizes.spaceM),

          _buildTextField(
            controller: _studentIdController,
            label: 'Student ID',
            icon: Icons.badge,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppSizes.spaceM),

          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSizes.spaceM),

          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            enabled: false, // Email can't be changed easily
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium.copyWith(
        color: enabled ? AppColors.primaryBlue : AppColors.textGray,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.inputLabel,
        prefixIcon: Icon(
          icon,
          color: enabled ? AppColors.primaryBlue : AppColors.textGray,
        ),
        filled: true,
        fillColor: enabled
            ? AppColors.lightGray.withValues(alpha: 0.3)
            : AppColors.lightGray.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      validator: enabled
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (_isEditing) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: AppSizes.spaceM),
        ],

        // My Products
        _buildMenuButton(
          icon: Icons.inventory,
          title: 'My Products',
          subtitle: 'Manage your listings',
          onTap: () {
            // TODO: Navigate to user products page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('My Products - Coming Soon')),
            );
          },
        ),

        const SizedBox(height: AppSizes.spaceS),

        // My Favorites
        _buildMenuButton(
          icon: Icons.favorite,
          title: 'My Favorites',
          subtitle: 'Saved products',
          onTap: () {
            // TODO: Navigate to favorites page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('My Favorites - Coming Soon')),
            );
          },
        ),

        const SizedBox(height: AppSizes.spaceS),

        // Settings
        _buildMenuButton(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences',
          onTap: () {
            // TODO: Navigate to settings page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings - Coming Soon')),
            );
          },
        ),

        const SizedBox(height: AppSizes.spaceL),

        // Sign Out
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _showSignOutDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textGray,
        ),
        onTap: onTap,
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement profile update with Supabase
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
              context.go(AppRoutes.landing);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
