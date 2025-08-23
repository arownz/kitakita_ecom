import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../core/router/app_router.dart';

class ProductDetailPage extends ConsumerWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Icon(Icons.book, size: 80, color: AppColors.primaryBlue),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product title and price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Engineering Mathematics Textbook',
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spaceS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Like New',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.spaceM),
                      Text(
                        '₱1,500',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.spaceL),

                  // Seller info
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            'M',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spaceM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maria Santos',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '⭐ 4.8 • 23 reviews',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textGray,
                                ),
                              ),
                              Text(
                                'Engineering Student',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('${AppRoutes.chatDetail}/1');
                          },
                          child: const Text('Message'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spaceL),

                  // Description
                  Text(
                    'Description',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceS),
                  Text(
                    'Comprehensive engineering mathematics textbook used for only one semester. '
                    'No highlighting or damage. Perfect for ENGR 101 and 102 courses. '
                    'Includes practice problems and solution manual.',
                    style: AppTextStyles.bodyMedium,
                  ),

                  const SizedBox(height: AppSizes.spaceL),

                  // Details
                  Text(
                    'Details',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceS),
                  _buildDetailRow('Category', 'Textbooks'),
                  _buildDetailRow('Condition', 'Like New'),
                  _buildDetailRow('Location', 'University Campus'),
                  _buildDetailRow('Posted', '2 days ago'),
                  _buildDetailRow('Views', '45'),

                  const SizedBox(height: AppSizes.spaceXL),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to favorites')),
                );
              },
              icon: const Icon(Icons.favorite_border),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.lightGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('${AppRoutes.chatDetail}/1');
                },
                icon: const Icon(Icons.message),
                label: const Text('Contact Seller'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return MainLayout(
      currentIndex: -1, // Not a main navigation item
      title: 'Product Details',
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'report':
                _showReportProductDialog(context);
                break;
              case 'share':
                _shareProduct(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, color: AppColors.error),
                  SizedBox(width: AppSizes.spaceS),
                  Text('Report Product'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, color: AppColors.primaryBlue),
                  SizedBox(width: AppSizes.spaceS),
                  Text('Share Product'),
                ],
              ),
            ),
          ],
        ),
      ],
      child: content,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportProductDialog(
        productTitle: 'Engineering Mathematics Textbook',
        onReport: (reason, description) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product reported successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _shareProduct(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature - Coming soon')),
    );
  }
}

class ReportProductDialog extends StatefulWidget {
  final String productTitle;
  final Function(String reason, String description) onReport;

  const ReportProductDialog({
    super.key,
    required this.productTitle,
    required this.onReport,
  });

  @override
  State<ReportProductDialog> createState() => _ReportProductDialogState();
}

class _ReportProductDialogState extends State<ReportProductDialog> {
  String _selectedReason = 'Misleading Description';
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _reportReasons = [
    'Misleading Description',
    'Fake Product',
    'Inappropriate Content',
    'Overpriced',
    'Duplicate Listing',
    'Prohibited Item',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report "${widget.productTitle}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this product?'),
            const SizedBox(height: AppSizes.spaceM),

            // Report reasons
            ...(_reportReasons.map(
              (reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value!;
                  });
                },
              ),
            )),

            const SizedBox(height: AppSizes.spaceM),

            // Description
            const Text('Additional details (optional):'),
            const SizedBox(height: AppSizes.spaceS),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Provide more details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onReport(_selectedReason, _descriptionController.text);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
}
