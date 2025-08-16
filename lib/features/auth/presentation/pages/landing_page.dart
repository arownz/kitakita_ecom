import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/router/app_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            top: 50,
            child: Opacity(
              opacity: 0.25,
              child: Container(
                width: ResponsiveUtils.getScreenWidth(context) + 400,
                height: ResponsiveUtils.getScreenHeight(context) * 0.9,
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
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // Logo and content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: ResponsiveUtils.getScreenPadding(context),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSizes.spaceXXL),

                          // Logo section
                          _buildLogoSection(context),

                          const SizedBox(height: AppSizes.spaceXXL),

                          // Welcome section
                          _buildWelcomeSection(context),

                          const SizedBox(height: AppSizes.spaceXL),

                          // Description section
                          _buildDescriptionSection(context),

                          const SizedBox(height: AppSizes.spaceXXL),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: AppSizes.appBarHeight,
      width: double.infinity,
      color: AppColors.primaryBlue,
      child: Stack(
        children: [
          // Yellow accent bar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Row(
              children: [
                // Menu icon
                Icon(
                  Icons.menu,
                  color: AppColors.white,
                  size: ResponsiveUtils.getIconSize(context, AppSizes.iconL),
                ),

                const SizedBox(width: AppSizes.spaceM),

                // App title
                Text(
                  'KitaKita',
                  style: AppTextStyles.navTitle.copyWith(
                    fontSize: ResponsiveUtils.getFontSize(context, 20),
                  ),
                ),

                const Spacer(),

                // Auth buttons
                if (ResponsiveUtils.isTablet(context) ||
                    ResponsiveUtils.isDesktop(context))
                  _buildAuthButtons(context)
                else
                  _buildMobileAuthButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Row(
      children: [
        // Login button
        Container(
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.secondaryBlue,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: TextButton(
            onPressed: () => context.go(AppRoutes.login),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Log in', style: TextStyle(fontSize: 10)),
          ),
        ),

        const SizedBox(width: AppSizes.spaceS),

        // Register button
        Container(
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: TextButton(
            onPressed: () => context.go(AppRoutes.register),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Create Account', style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAuthButtons(BuildContext context) {
    return Row(
      children: [
        // Compact login button
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondaryBlue,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: const Text(
              'Login',
              style: TextStyle(color: AppColors.white, fontSize: 10),
            ),
          ),
        ),

        const SizedBox(width: AppSizes.spaceS),

        // Compact register button
        GestureDetector(
          onTap: () => context.go(AppRoutes.register),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: const Text(
              'Register',
              style: TextStyle(color: AppColors.black, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    return Column(
      children: [
        // Logo image placeholder
        Container(
          width: 129,
          height: 148,
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
            fontSize: ResponsiveUtils.getFontSize(context, 40),
          ),
        ),

        const SizedBox(height: AppSizes.spaceS),

        // NU subtitle
        Text(
          'NU',
          style: AppTextStyles.h1.copyWith(
            fontSize: ResponsiveUtils.getFontSize(context, 40),
          ),
        ),

        const SizedBox(height: AppSizes.spaceS),

        // Tagline
        Text(
          'Student-Only e-Commerce',
          style: AppTextStyles.bodyLarge.copyWith(
            fontSize: ResponsiveUtils.getFontSize(context, 17),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTextStyles.h2.copyWith(
                fontSize: ResponsiveUtils.getFontSize(context, 32),
              ),
              children: const [
                TextSpan(text: 'Welcome to '),
                TextSpan(
                  text: 'KitaKita',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '!'),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spaceS),

          Text(
            '  - Your campus marketplace',
            style: AppTextStyles.h3.copyWith(
              fontSize: ResponsiveUtils.getFontSize(context, 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: RichText(
        textAlign: TextAlign.right,
        text: TextSpan(
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: ResponsiveUtils.getFontSize(context, 15),
            color: AppColors.primaryBlue,
          ),
          children: const [
            TextSpan(
              text: 'KitaKita',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  ' is a C2C(Customer-to-Customer) Business Platform to foster an exclusive environment for Trading. A working ecosystem for NUD Students to freely find what they need or want that other students may have available for sale.',
            ),
          ],
        ),
      ),
    );
  }
}
