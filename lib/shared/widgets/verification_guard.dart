import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

/// Widget that shows a verification required dialog for unverified users
class VerificationRequiredDialog extends StatelessWidget {
  final String feature;
  final String description;

  const VerificationRequiredDialog({
    super.key,
    required this.feature,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.email_outlined,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Email Verification Required',
              style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To use $feature, you need to verify your email address first.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textGray.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryYellow.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check your university email inbox for the verification link.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Maybe Later',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);
            return ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      await ref
                          .read(authProvider.notifier)
                          .resendVerificationEmail();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Verification email sent! Please check your inbox.',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Verification Email'),
            );
          },
        ),
      ],
    );
  }
}

/// Helper function to check if user is verified and show dialog if not
Future<bool> checkEmailVerificationAndPrompt(
  BuildContext context,
  WidgetRef ref, {
  required String feature,
  required String description,
}) async {
  final isVerified = ref.read(isEmailVerifiedProvider);

  if (!isVerified) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationRequiredDialog(
        feature: feature,
        description: description,
      ),
    );
    return false;
  }

  return true;
}
