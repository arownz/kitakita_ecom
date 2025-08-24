import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_sizes.dart';
import '../providers/auth_provider.dart';

class EmailVerificationBanner extends ConsumerStatefulWidget {
  final bool isPermanent; // If true, no close button (for profile page)

  const EmailVerificationBanner({super.key, this.isPermanent = false});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> {
  bool _isDismissed = false;
  String? _lastUserEmail; // Track user changes to reset dismissal

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final currentUserEmail = authState.user?.email;

    // Reset dismissal when user changes (new login)
    if (currentUserEmail != _lastUserEmail) {
      _lastUserEmail = currentUserEmail;
      if (_isDismissed) {
        _isDismissed = false;
      }
    }

    // Check if user is actually verified by looking at the user's email confirmation
    final isActuallyVerified = authState.user?.emailConfirmedAt != null;

    // Don't show banner if user is not logged in, email is actually verified, or dismissed (and not permanent)
    if (!isLoggedIn ||
        isActuallyVerified ||
        (_isDismissed && !widget.isPermanent)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify your email address',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'To add products and use all features, please verify your email.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Close button (only if not permanent)
              if (!widget.isPermanent) ...[
                const SizedBox(width: AppSizes.spaceS),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isDismissed = true;
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(24, 24),
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => _resendVerificationEmail(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue,
                            ),
                          ),
                        )
                      : Text(
                          'Resend Email',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceS),
              TextButton(
                onPressed: () => _showVerificationInfo(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue.withValues(alpha: 0.7),
                ),
                child: Text(
                  'Learn more',
                  style: AppTextStyles.bodySmall.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resendVerificationEmail(BuildContext context, WidgetRef ref) async {
    try {
      final success = await ref
          .read(authProvider.notifier)
          .resendVerificationEmail();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Verification email sent! Please check your inbox.'
                  : 'Failed to send verification email. Please try again.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showVerificationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification'),
        content: const Text(
          'To ensure the security of our marketplace and prevent spam, all users must verify their email address before they can:\n\n'
          '• Add products for sale or trade\n'
          '• Update their profile information\n'
          '• Send messages to other users\n\n'
          'Please check your email inbox (including spam folder) for the verification link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
