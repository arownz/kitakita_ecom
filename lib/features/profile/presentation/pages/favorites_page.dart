import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../marketplace/domain/models/product.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../core/router/app_router.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  List<Product> _favoriteProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = ref.read(currentUserProvider);
      if (user != null) {
        // Get user's favorite product IDs
        final favoritesResponse = await SupabaseService.from(
          'user_favorites',
        ).select('product_id').eq('user_id', user.id);

        if (favoritesResponse.isNotEmpty) {
          final productIds = (favoritesResponse as List)
              .map((fav) => fav['product_id'] as String)
              .toList();

          // Get the actual products
          final productsResponse = await SupabaseService.from('products')
              .select(
                '*, categories(name), user_profiles(first_name, last_name)',
              )
              .inFilter('id', productIds)
              .order('created_at', ascending: false);

          final products = (productsResponse as List).map((data) {
            final categoryData = data['categories'] as Map<String, dynamic>?;
            final sellerData = data['user_profiles'] as Map<String, dynamic>?;
            final sellerName = sellerData != null
                ? '${sellerData['first_name'] ?? ''} ${sellerData['last_name'] ?? ''}'
                      .trim()
                : 'Unknown Seller';

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
              sellerName: sellerName,
              location: data['location'],
              images: List<String>.from(data['images'] ?? []),
              createdAt: DateTime.parse(data['created_at']),
              updatedAt: DateTime.parse(data['updated_at']),
              viewCount: data['view_count'] ?? 0,
              isFavorited: true,
              isAvailable: data['is_available'] ?? true,
            );
          }).toList();

          setState(() {
            _favoriteProducts = products;
            _isLoading = false;
          });
        } else {
          setState(() {
            _favoriteProducts = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await SupabaseService.from(
          'user_favorites',
        ).delete().eq('user_id', user.id).eq('product_id', productId);

        await _loadFavorites(); // Refresh the list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from favorites: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildFavoritesList(),
    );

    return MainLayout(currentIndex: 3, child: content);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: AppColors.error),
          const SizedBox(height: AppSizes.spaceM),
          Text(
            'Failed to load favorites',
            style: AppTextStyles.h3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            _error!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceL),
          ElevatedButton(onPressed: _loadFavorites, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_favoriteProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.textGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.spaceM),
            Text(
              'No favorites yet',
              style: AppTextStyles.h3.copyWith(color: AppColors.textGray),
            ),
            const SizedBox(height: AppSizes.spaceS),
            Text(
              'Start exploring products and add them to your favorites',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spaceL),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Browse Products'),
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
          Text(
            '${_favoriteProducts.length} favorite products',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.spaceM),
          Expanded(
            child: GridView.builder(
              gridDelegate: ResponsiveUtils.getProductGridDelegate(context),
              itemCount: _favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = _favoriteProducts[index];
                return Stack(
                  children: [
                    ProductCard(
                      product: product,
                      onTap: () => context.push(
                        '${AppRoutes.productDetail}/${product.id}',
                      ),
                      onFavorite: () => _removeFavorite(product.id),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
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
}
