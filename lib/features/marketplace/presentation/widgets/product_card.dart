import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/product.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import 'product_detail_popup.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showSellerInfo;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.showSellerInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap ?? () => product.showDetailPopup(context),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Image container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSizes.cardBorderRadius),
                      ),
                      color: AppColors.lightGray,
                    ),
                    child: product.primaryImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppSizes.cardBorderRadius),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: product.primaryImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.textGray,
                                      size: 32,
                                    ),
                                  ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              color: AppColors.textGray,
                              size: 32,
                            ),
                          ),
                  ),

                  // Favorite button
                  if (onFavorite != null)
                    Positioned(
                      top: AppSizes.spaceS,
                      right: AppSizes.spaceS,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.spaceS),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            product.isFavorited == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: product.isFavorited == true
                                ? AppColors.error
                                : AppColors.textGray,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                  // Condition badge
                  if (product.condition != ProductCondition.good)
                    Positioned(
                      top: AppSizes.spaceS,
                      left: AppSizes.spaceS,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spaceS,
                          vertical: AppSizes.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: _getConditionColor(product.condition),
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Text(
                          product.conditionDisplay,
                          style: AppTextStyles.categoryText.copyWith(
                            color: AppColors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: AppTextStyles.h4.copyWith(fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.spaceXS),
                        Text(
                          product.formattedPrice,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    // Seller info and stats
                    if (showSellerInfo)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.sellerName != null)
                            Text(
                              'by ${product.sellerName}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: AppSizes.spaceXS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (product.location?.isNotEmpty == true)
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: AppColors.textGray,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          product.location!,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 12,
                                    color: AppColors.textGray,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${product.viewCount}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.new_:
        return AppColors.success;
      case ProductCondition.likeNew:
        return AppColors.info;
      case ProductCondition.good:
        return AppColors.primaryBlue;
      case ProductCondition.fair:
        return AppColors.warning;
      case ProductCondition.poor:
        return AppColors.error;
    }
  }
}
