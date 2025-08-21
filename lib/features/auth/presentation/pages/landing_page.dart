import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/router/app_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlue,
              AppColors.primaryBlue,
              Color(0xFF1E3A8A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            _buildBackgroundElements(),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero section
                    _buildHeroSection(context),

                    // Features section
                    _buildFeaturesSection(context),

                    // How it works section
                    _buildHowItWorksSection(context),

                    // CTA section
                    _buildCTASection(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Floating circles
        Positioned(
          top: 100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryYellow.withValues(alpha: 0.1),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        // Grid pattern overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(painter: GridPainter()),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getScreenPadding(context),
      child: Column(
        children: [
          const SizedBox(height: 60),

          // Logo and title
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                'assets/images/kitakita_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Main title
          Text(
            'KitaKita',
            style: AppTextStyles.h1.copyWith(
              fontSize: ResponsiveUtils.getFontSize(context, 56),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryYellow.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              'Student Marketplace',
              style: AppTextStyles.h3.copyWith(
                fontSize: ResponsiveUtils.getFontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Description
          Text(
            'The ultimate peer-to-peer marketplace for students.\nBuy, sell, and trade with your campus community.',
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: ResponsiveUtils.getFontSize(context, 18),
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Action buttons (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              if (isNarrow) {
                return Column(
                  children: [
                    _buildActionButton(
                      context: context,
                      text: 'Get Started',
                      isPrimary: true,
                      onTap: () => context.go(AppRoutes.register),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      context: context,
                      text: 'Sign In',
                      isPrimary: false,
                      onTap: () => context.go(AppRoutes.login),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      text: 'Get Started',
                      isPrimary: true,
                      onTap: () => context.go(AppRoutes.register),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      text: 'Sign In',
                      isPrimary: false,
                      onTap: () => context.go(AppRoutes.login),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primaryYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(color: Colors.white, width: 2),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primaryYellow.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.buttonMedium.copyWith(
                fontSize: ResponsiveUtils.getFontSize(context, 16),
                fontWeight: FontWeight.w700,
                color: isPrimary ? AppColors.primaryBlue : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Why Students Need to Use KitaKita',
            style: AppTextStyles.h2.copyWith(
              fontSize: ResponsiveUtils.getFontSize(context, 28),
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Features grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveUtils.isMobile(context) ? 2 : 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildFeatureCard(
                icon: Icons.school,
                title: 'Student Only',
                description: 'Exclusive community',
                color: AppColors.primaryBlue,
              ),
              _buildFeatureCard(
                icon: Icons.swap_horiz,
                title: 'Buy & Sell',
                description: 'Easy trading',
                color: AppColors.primaryYellow,
              ),
              _buildFeatureCard(
                icon: Icons.location_on,
                title: 'Campus Based',
                description: 'Local meetups',
                color: AppColors.success,
              ),
              _buildFeatureCard(
                icon: Icons.shield,
                title: 'Safe Trading',
                description: 'Verified users',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryYellow.withValues(alpha: 0.1),
            AppColors.primaryBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryYellow.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'How It Works',
            style: AppTextStyles.h2.copyWith(
              fontSize: ResponsiveUtils.getFontSize(context, 28),
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Steps
          ...[
            {
              'step': '1',
              'title': 'Create Account',
              'desc': 'Sign up with your student email',
            },
            {
              'step': '2',
              'title': 'List Items',
              'desc': 'Post what you want to sell',
            },
            {
              'step': '3',
              'title': 'Connect',
              'desc': 'Chat and meet with buyers/sellers',
            },
            {
              'step': '4',
              'title': 'Trade',
              'desc': 'Complete your transaction',
            },
          ].map(
            (step) => _buildStepItem(
              step: step['step'] as String,
              title: step['title'] as String,
              description: step['desc'] as String,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                step,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color.fromARGB(174, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Ready to Start Trading?',
            style: AppTextStyles.h2.copyWith(
              fontSize: ResponsiveUtils.getFontSize(context, 24),
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Join thousands of students already trading on KitaKita',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color.fromARGB(
                174,
                255,
                255,
                255,
              ).withValues(alpha: 0.9),

              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.register),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                'Join KitaKita Now',
                style: AppTextStyles.buttonMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for grid pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    final spacing = 30.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
