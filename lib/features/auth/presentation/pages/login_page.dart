import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      if (success) {
        final userRole = ref.read(userRoleProvider);
        if (userRole == UserRole.admin) {
          context.go(AppRoutes.adminDashboard);
        } else {
          context.go(AppRoutes.home);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(color: AppColors.backgroundColor),
          ),

          // Background image with opacity
          Positioned(
            left: -200,
            top: 0,
            child: Opacity(
              opacity: 0.25,
              child: Container(
                width: ResponsiveUtils.getScreenWidth(context) + 400,
                height: ResponsiveUtils.getScreenHeight(context),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/banner-nu-dasma.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: ResponsiveUtils.getScreenPadding(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section
                      _buildLogoSection(context),

                      const SizedBox(height: AppSizes.spaceXXL),

                      // Login form
                      _buildLoginForm(context, authState),

                      const SizedBox(height: AppSizes.spaceL),

                      // Register link
                      _buildRegisterLink(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    return Column(
      children: [
        // Logo image placeholder
        Container(
          width: ResponsiveUtils.isMobile(context) ? 100 : 131,
          height: ResponsiveUtils.isMobile(context) ? 112 : 147,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/kitakita-logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: AppSizes.spaceM),

        // KitaKita title
        Text(
          'KitaKita',
          style: AppTextStyles.h1.copyWith(
            fontSize: ResponsiveUtils.getFontSize(
              context,
              ResponsiveUtils.isMobile(context) ? 32 : 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthState authState) {
    final maxWidth = ResponsiveUtils.isMobile(context)
        ? double.infinity
        : ResponsiveUtils.isTablet(context)
        ? 500.0
        : 450.0;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: ResponsiveUtils.isMobile(context)
          ? const EdgeInsets.all(AppSizes.paddingL)
          : const EdgeInsets.all(AppSizes.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Email', style: AppTextStyles.inputLabel),
                const SizedBox(height: AppSizes.spaceS),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.inputText,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: AppTextStyles.inputHint,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spaceL),

            // Password field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Password', style: AppTextStyles.inputLabel),
                const SizedBox(height: AppSizes.spaceS),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: AppTextStyles.inputHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.borderGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spaceM),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Handle forgot password
                  _showForgotPasswordDialog(context);
                },
                child: const Text(
                  'Forgot password?',
                  style: AppTextStyles.linkText,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spaceL),

            // Error message
            if (authState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  border: Border.all(color: AppColors.error),
                ),
                child: Text(
                  authState.error!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
            ],

            // Login button
            SizedBox(
              height: AppSizes.buttonHeightM,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('LOG IN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryYellow),
        children: [
          const TextSpan(text: "Don't have an account ? "),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.register),
              child: const Text(
                'Register',
                style: TextStyle(
                  color: AppColors.primaryYellow,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
            ),
            const SizedBox(height: AppSizes.spaceM),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final success = await ref
                    .read(authProvider.notifier)
                    .resetPassword(emailController.text.trim());

                if (!context.mounted) return;
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to send reset email. Please try again.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}
