import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/widgets/email_verification_banner.dart';
import '../../../../shared/layouts/main_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    final content = SingleChildScrollView(
      padding: ResponsiveUtils.getScreenPadding(context),
      child: Column(
        children: [
          // Email verification banner (permanent on profile page)
          const EmailVerificationBanner(isPermanent: true),
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
    );

    return MainLayout(
      currentIndex: 4,
      title: 'My Profile',
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
      child: content,
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
          child: ClipOval(
            child: user?.userMetadata?['profile_image_url'] != null
                ? Image.network(
                    user!.userMetadata!['profile_image_url']!,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        initial,
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Center(
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
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
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
        color: enabled ? AppColors.primaryBlue : AppColors.primaryBlue,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: enabled ? AppColors.primaryBlue : AppColors.primaryBlue,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? AppColors.primaryBlue : AppColors.primaryBlue,
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
            context.push(AppRoutes.myProducts);
          },
        ),

        const SizedBox(height: AppSizes.spaceS),

        // My Favorites
        _buildMenuButton(
          icon: Icons.favorite,
          title: 'My Favorites',
          subtitle: 'Saved products',
          onTap: () {
            context.push(AppRoutes.favorites);
          },
        ),

        const SizedBox(height: AppSizes.spaceS),

        // Settings
        _buildMenuButton(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences',
          onTap: () {
            context.push(AppRoutes.settings);
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
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
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
          ),
          trailing: const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: AppColors.textGray,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Upload image to Supabase Storage
        final user = ref.read(currentUserProvider);
        if (user != null) {
          final fileName =
              'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final filePath = 'profile-images/$fileName';

          final fileBytes = await image.readAsBytes();
          await SupabaseService.storage
              .from('profile-images')
              .uploadBinary(filePath, fileBytes);

          // Get public URL
          final imageUrl = SupabaseService.storage
              .from('profile-images')
              .getPublicUrl(filePath);

          // Update user metadata with new profile image
          await SupabaseService.client.auth.updateUser(
            UserAttributes(data: {'profile_image_url': imageUrl}),
          );

          // Update user_profiles table
          await SupabaseService.from(
            'user_profiles',
          ).update({'profile_image_url': imageUrl}).eq('user_id', user.id);

          // Refresh the page to show new image
          setState(() {});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Persist to Supabase user_profiles
        final user = ref.read(currentUserProvider);
        if (user != null) {
          await SupabaseService.from('user_profiles')
              .update({
                'first_name': _firstNameController.text.trim(),
                'last_name': _lastNameController.text.trim(),
                'student_id': _studentIdController.text.trim(),
                'phone_number': _phoneController.text.trim(),
              })
              .eq('user_id', user.id);

          // Update user metadata in Supabase Auth
          await SupabaseService.client.auth.updateUser(
            UserAttributes(
              data: {
                'first_name': _firstNameController.text.trim(),
                'last_name': _lastNameController.text.trim(),
                'student_id': _studentIdController.text.trim(),
                'phone_number': _phoneController.text.trim(),
              },
            ),
          );
        }

        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
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
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                // Use pushReplacement to ensure we can't go back
                context.go(AppRoutes.landing);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
