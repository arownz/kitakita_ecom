import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppSizes.mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppSizes.mobileBreakpoint &&
        width < AppSizes.tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppSizes.tabletBreakpoint;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: AppSizes.paddingM);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL);
    } else {
      // Desktop - center content with max width
      final screenWidth = getScreenWidth(context);
      final contentWidth = screenWidth > AppSizes.maxContentWidth
          ? AppSizes.maxContentWidth
          : screenWidth;
      final horizontalPadding = (screenWidth - contentWidth) / 2;
      return EdgeInsets.symmetric(horizontal: horizontalPadding);
    }
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return 2; // 2 columns on mobile
    } else if (isTablet(context)) {
      return 3; // 3 columns on tablet
    } else {
      return 4; // 4 columns on desktop
    }
  }

  static double getCardWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    final padding = getScreenPadding(context);
    final availableWidth = screenWidth - padding.horizontal;
    final crossAxisCount = getGridCrossAxisCount(context);
    final spacing = AppSizes.gridSpacing * (crossAxisCount - 1);

    return (availableWidth - spacing) / crossAxisCount;
  }

  static SliverGridDelegate getProductGridDelegate(BuildContext context) {
    final crossAxisCount = getGridCrossAxisCount(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: isMobile(context) ? 0.75 : 0.8,
      crossAxisSpacing: AppSizes.gridSpacing,
      mainAxisSpacing: AppSizes.gridSpacing,
    );
  }

  static double getFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) {
      return baseFontSize * 0.9; // Slightly smaller on mobile
    } else if (isTablet(context)) {
      return baseFontSize;
    } else {
      return baseFontSize * 1.1; // Slightly larger on desktop
    }
  }

  static double getIconSize(BuildContext context, double baseIconSize) {
    if (isMobile(context)) {
      return baseIconSize;
    } else if (isTablet(context)) {
      return baseIconSize * 1.1;
    } else {
      return baseIconSize * 1.2;
    }
  }
}
