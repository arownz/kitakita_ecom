import 'package:flutter/material.dart';
import '../../domain/models/product.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final Function(String categoryId)? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(category.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.iconName != null) ...[
              Icon(
                _getIconData(category.iconName!),
                size: 16,
                color: isSelected ? AppColors.black : AppColors.primaryBlue,
              ),
              const SizedBox(width: AppSizes.spaceXS),
            ],
            Text(
              category.name,
              style: AppTextStyles.categoryText.copyWith(
                color: isSelected ? AppColors.black : AppColors.primaryBlue,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'devices':
        return Icons.devices;
      case 'book':
        return Icons.book;
      case 'shirt':
        return Icons.checkroom;
      case 'restaurant':
        return Icons.restaurant;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'home':
        return Icons.home;
      case 'palette':
        return Icons.palette;
      case 'build':
        return Icons.build;
      case 'category':
      default:
        return Icons.category;
    }
  }
}
