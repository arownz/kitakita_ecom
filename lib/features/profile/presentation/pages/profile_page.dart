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
import '../../../../shared/layouts/main_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadUserDataFromDatabase();
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

  Future<void> _loadUserDataFromDatabase() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        // Load from database user_profiles table
        final response = await SupabaseService.from(
          'user_profiles',
        ).select().eq('user_id', user.id).single();

        setState(() {
          _profileData = response;
          _firstNameController.text = response['first_name'] ?? '';
          _lastNameController.text = response['last_name'] ?? '';
          _studentIdController.text = response['student_id'] ?? '';
          _phoneController.text = response['phone_number'] ?? '';
          _emailController.text = user.email ?? '';
          _isLoading = false;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error loading profile data: $e');
        }
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go(AppRoutes.landing);
      return const SizedBox.shrink();
    }

    return MainLayout(
      currentIndex: 2, // Profile tab index
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryBlue,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    // Cancel editing - reload data
                    _loadUserDataFromDatabase();
                  }
                  _isEditing = !_isEditing;
                });
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: ResponsiveUtils.getScreenPadding(context),
                child: Column(
                  children: [
                    const SizedBox(height: AppSizes.spaceL),
                    _buildProfileAvatar(),
                    const SizedBox(height: AppSizes.spaceL),
                    _buildProfileForm(),
                    const SizedBox(height: AppSizes.spaceL),
                    _buildActionButtons(context),
                    const SizedBox(height: AppSizes.spaceL),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final firstName = _firstNameController.text.isNotEmpty
        ? _firstNameController.text
        : _profileData?['first_name'] ?? '';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    // Get profile image URL from database instead of userMetadata
    final profileImageUrl = _profileData?['profile_image_url'] as String?;

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
            child: profileImageUrl != null && profileImageUrl.isNotEmpty
                ? Image.network(
                    profileImageUrl,
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
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
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
              icon: Icons.person,
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
              enabled: false, // Email cannot be edited
            ),
          ],
        ),
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
            child: Icon(icon, color: AppColors.primaryBlue, size: 24),
          ),
          title: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.borderGray,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.borderGray,
            size: 16,
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
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          // Upload image to Supabase storage
          final filename =
              '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          // For web platform, read as bytes
          final bytes = await image.readAsBytes();

          final uploadResponse = await SupabaseService.storage
              .from('profile-images')
              .uploadBinary(filename, bytes);

          if (uploadResponse.isNotEmpty) {
            // Get public URL
            final publicUrl = SupabaseService.storage
                .from('profile-images')
                .getPublicUrl(filename);

            // Update database with image URL
            await SupabaseService.from(
              'user_profiles',
            ).update({'profile_image_url': publicUrl}).eq('user_id', user.id);

            // Refresh the page to show new image
            setState(() {});

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile image updated successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile image: $e'),
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
