import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/models/product.dart';
import '../providers/marketplace_providers.dart';

class ProductDetailPopup extends ConsumerWidget {
  final Product product;

  const ProductDetailPopup({super.key, required this.product});

  String _getConditionDisplayName(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.new_:
        return 'New';
      case ProductCondition.likeNew:
        return 'Like New';
      case ProductCondition.good:
        return 'Good';
      case ProductCondition.fair:
        return 'Fair';
      case ProductCondition.poor:
        return 'Poor';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(ResponsiveUtils.isMobile(context) ? 16 : 40),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.isMobile(context) ? double.infinity : 800,
          maxHeight: ResponsiveUtils.isMobile(context)
              ? MediaQuery.of(context).size.height * 0.9
              : 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ResponsiveUtils.isMobile(context)
            ? _buildMobileLayout(context, ref)
            : _buildDesktopLayout(context, ref),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Left side - Product Image
        Expanded(flex: 1, child: _buildImageSection(context)),
        // Right side - Product Details
        Expanded(flex: 1, child: _buildDetailsSection(context, ref)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Product Image
        Expanded(flex: 1, child: _buildImageSection(context)),
        // Product Details
        Expanded(flex: 1, child: _buildDetailsSection(context, ref)),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: ResponsiveUtils.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : const BorderRadius.horizontal(left: Radius.circular(20)),
        color: const Color(0xFFF8F9FA),
      ),
      child: Stack(
        children: [
          // Main product image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: ResponsiveUtils.isMobile(context)
                  ? const BorderRadius.vertical(top: Radius.circular(20))
                  : const BorderRadius.horizontal(left: Radius.circular(20)),
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.images.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF8F9FA),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF8F9FA),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF8F9FA),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 64,
                        color: Color(0xFF6C757D),
                      ),
                    ),
            ),
          ),

          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF495057),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // Image indicators (if multiple images)
          if (product.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  product.images.length.clamp(0, 5),
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, [WidgetRef? ref]) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: ResponsiveUtils.isMobile(context)
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : const BorderRadius.horizontal(right: Radius.circular(20)),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product title
          Text(
            product.title,
            style: AppTextStyles.h2.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E1E),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Price
          Text(
            '₱${product.price.toStringAsFixed(2)}',
            style: AppTextStyles.h1.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),

          const SizedBox(height: 16),

          // Category and condition
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Text(
                  product.categoryName ?? 'Uncategorized',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C757D),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: product.condition == ProductCondition.new_
                      ? const Color(0xFFE8F5E8)
                      : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: product.condition == ProductCondition.new_
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFFC107),
                  ),
                ),
                child: Text(
                  _getConditionDisplayName(product.condition),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: product.condition == ProductCondition.new_
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFF57C00),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'Description',
            style: AppTextStyles.h3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E1E),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              child: Text(
                product.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF495057),
                  height: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              // Message seller button
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryBlue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('${AppRoutes.chatDetail}/${product.sellerId}');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Message',
                          style: AppTextStyles.buttonMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Favorite button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: IconButton(
                  onPressed: () {
                    if (ref != null) {
                      ref
                          .read(productsProvider.notifier)
                          .toggleFavorite(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            product.isFavorited == true
                                ? 'Removed from favorites'
                                : 'Added to favorites',
                          ),
                          backgroundColor: AppColors.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    product.isFavorited == true
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: product.isFavorited == true
                        ? Colors.red
                        : const Color(0xFF6C757D),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Extension method to show the popup
extension ProductDetailPopupExtension on Product {
  void showDetailPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ProductDetailPopup(product: this),
    );
  }
}
