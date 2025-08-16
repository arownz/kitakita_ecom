import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // System Font Families (fallback to system defaults)
  static const String interFamily = 'Inter';
  static const String heeboFamily = 'Heebo';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: heeboFamily,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: interFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: interFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
    height: 1.4,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: interFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
    height: 1.4,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: interFamily,
    fontSize: 17,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryBlue,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: interFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: interFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textGray,
    height: 1.4,
  );

  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: interFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
    height: 1.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: interFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: interFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
    height: 1.2,
  );

  // Form Text
  static const TextStyle inputLabel = TextStyle(
    fontFamily: interFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.white,
    height: 1.3,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: interFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.borderGray,
    height: 1.3,
  );

  static const TextStyle inputText = TextStyle(
    fontFamily: interFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
    height: 1.3,
  );

  // Navigation
  static const TextStyle navTitle = TextStyle(
    fontFamily: interFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    height: 1.2,
  );

  // Price Text
  static const TextStyle priceText = TextStyle(
    fontFamily: interFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
    height: 1.3,
  );

  // Category Text
  static const TextStyle categoryText = TextStyle(
    fontFamily: interFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
    height: 1.2,
  );

  // Link Text
  static const TextStyle linkText = TextStyle(
    fontFamily: interFamily,
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryYellow,
    height: 1.4,
  );
}
