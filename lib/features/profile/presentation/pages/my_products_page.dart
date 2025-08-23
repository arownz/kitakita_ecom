import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../marketplace/domain/models/product.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';
import '../../../../core/router/app_router.dart';

class MyProductsPage extends ConsumerStatefulWidget {
  const MyProductsPage({super.key});

  @override
  ConsumerState<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends ConsumerState<MyProductsPage> {
  List<Product> _myProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

  Future<void> _loadMyProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = ref.read(currentUserProvider);
      if (user != null) {
        final response = await SupabaseService.from('products')
            .select('*, categories(name)')
            .eq('seller_id', user.id)
            .order('created_at', ascending: false);

        final products = (response as List).map((data) {
          final categoryData = data['categories'] as Map<String, dynamic>?;
          return Product(
            id: data['id'],
            title: data['title'],
            description: data['description'],
            price: (data['price'] as num).toDouble(),
            condition: ProductCondition.values.firstWhere(
              (e) => e.toString().split('.').last == data['condition'],
              orElse: () => ProductCondition.good,
            ),
            categoryId: data['category_id'],
            categoryName: categoryData?['name'] ?? 'Unknown',
            sellerId: data['seller_id'],
            sellerName: user.userMetadata?['first_name'] ?? 'Unknown',
            location: data['location'],
            images: List<String>.from(data['images'] ?? []),
            createdAt: DateTime.parse(data['created_at']),
            updatedAt: DateTime.parse(data['updated_at']),
            viewCount: data['view_count'] ?? 0,
            isFavorited: false,
            isAvailable: data['is_available'] ?? true,
          );
        }).toList();

        setState(() {
          _myProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await SupabaseService.from('products').delete().eq('id', productId);
      await _loadMyProducts(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _buildErrorState()
        : _buildProductsList();

    return MainLayout(
      currentIndex: -1, // Accessed from profile
      title: 'My Products',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => context.push(AppRoutes.addProduct),
        ),
      ],
      child: content,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: AppColors.error),
          const SizedBox(height: AppSizes.spaceM),
          Text(
            'Failed to load products',
            style: AppTextStyles.h3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            _error!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceL),
          ElevatedButton(
            onPressed: _loadMyProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_myProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.spaceM),
            Text(
              'No products yet',
              style: AppTextStyles.h3.copyWith(color: AppColors.textGray),
            ),
            const SizedBox(height: AppSizes.spaceS),
            Text(
              'Start selling by adding your first product',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spaceL),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.addProduct),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Add Product'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(
        ResponsiveUtils.isMobile(context)
            ? AppSizes.paddingM
            : AppSizes.paddingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_myProducts.length} products',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.addProduct),
                icon: const Icon(Icons.add),
                label: const Text('Add New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),
          Expanded(
            child: GridView.builder(
              gridDelegate: ResponsiveUtils.getProductGridDelegate(context),
              itemCount: _myProducts.length,
              itemBuilder: (context, index) {
                final product = _myProducts[index];
                return Stack(
                  children: [
                    ProductCard(
                      product: product,
                      onTap: () => context.push(
                        '${AppRoutes.productDetail}/${product.id}',
                      ),
                      onFavorite: () {}, // No favorite action for own products
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.white,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditProductSheet(product);
                          } else if (value == 'delete') {
                            _showDeleteDialog(product);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditProductSheet(Product product) {
    final titleController = TextEditingController(text: product.title);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final locationController = TextEditingController(text: product.location);
    final descriptionController = TextEditingController(
      text: product.description,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSizes.paddingM,
            right: AppSizes.paddingM,
            top: AppSizes.paddingM,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppSizes.paddingM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Product',
                style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
              ),
              const SizedBox(height: AppSizes.spaceM),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₱)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final updated = product.copyWith(
                        title: titleController.text.trim(),
                        price:
                            double.tryParse(priceController.text.trim()) ??
                            product.price,
                        location: locationController.text.trim(),
                        description: descriptionController.text.trim(),
                        updatedAt: DateTime.now(),
                      );

                      await SupabaseService.from(
                        'products',
                      ).update(updated.toJson()).eq('id', product.id);

                      if (context.mounted) Navigator.of(context).pop();
                      await _loadMyProducts();

                      if (mounted) {
                        ScaffoldMessenger.of(
                          Navigator.of(this.context).context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text('Product updated successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          Navigator.of(this.context).context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
