import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/layouts/main_layout.dart';

import '../../../../core/router/app_router.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';

import '../../domain/models/product.dart';
import '../../../../shared/widgets/email_verification_banner.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String? _selectedCategoryId;
  Set<String> _selectedConditions = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productsProvider.notifier).loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final content = Column(
      children: [
        // Top navigation bar with integrated search
        _buildTopNavigation(context),

        // Email verification banner
        const EmailVerificationBanner(),

        // Main content area
        Expanded(child: _buildMainContent(categoriesAsync, productsState)),
      ],
    );

    return MainLayout(currentIndex: 0, title: 'Marketplace', child: content);
  }

  Widget _buildTopNavigation(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side - Search bar with filters
          Expanded(child: _buildIntegratedSearchBar(context)),

          const SizedBox(width: 24),

          // Right side - Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildIntegratedSearchBar(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(Icons.search, color: Color(0xFF6C757D), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for products...',
                hintStyle: TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF212529),
              ),
              onChanged: (value) {
                _performSearch(value);
              },
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFE9ECEF),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          IconButton(
            onPressed: () {
              _showFiltersBottomSheet(context);
            },
            icon: const Icon(Icons.tune, color: Color(0xFF6C757D), size: 24),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Profile button
        _buildActionButton(
          icon: Icons.person_outline,
          onTap: () => context.go(AppRoutes.profile),
        ),

        const SizedBox(width: 16),

        // Chat button
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          onTap: () => context.go(AppRoutes.chatList),
        ),

        const SizedBox(width: 16),

        // Notifications button
        _buildActionButton(
          icon: Icons.notifications_outlined,
          onTap: () => _showNotificationsDropdown(context),
          showBadge: true, // TODO: Connect to actual notification count
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Center(
                child: Icon(icon, color: const Color(0xFF495057), size: 24),
              ),
              if (showBadge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    AsyncValue<List<Category>> categoriesAsync,
    ProductsState productsState,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildCategoriesSection(categoriesAsync)),
        _buildProductsGrid(productsState),
        if (productsState.isLoading && productsState.products.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingL),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  void _showNotificationsDropdown(BuildContext context) {
    // TODO: Implement notifications dropdown
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications dropdown coming soon!')),
    );
  }

  Widget _buildCategoriesSection(AsyncValue<List<Category>> categoriesAsync) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.isMobile(context)
            ? AppSizes.paddingS
            : AppSizes.paddingM,
      ),
      child: categoriesAsync.when(
        data: (categories) => SizedBox(
          height: ResponsiveUtils.isMobile(context) ? 36 : 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.isMobile(context)
                  ? AppSizes.paddingS
                  : AppSizes.paddingM,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: ResponsiveUtils.isMobile(context)
                      ? AppSizes.spaceXS
                      : AppSizes.spaceS,
                ),
                child: CategoryChip(
                  category: category,
                  isSelected: _selectedCategoryId == category.id,
                  onTap: (categoryId) => _onCategorySelected(categoryId),
                ),
              );
            },
          ),
        ),
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildProductsGrid(ProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.products.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceL),
                Text(
                  'Unable to load products',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceS),
                Text(
                  'Please check your internet connection and try again.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spaceXL),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(productsProvider.notifier).refreshProducts(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.products.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.store_outlined,
                    size: 48,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceL),
                Text(
                  'No products available',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceS),
                Text(
                  'Be the first to add a product to the marketplace!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spaceXL),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.addProduct),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(
        ResponsiveUtils.isMobile(context)
            ? AppSizes.paddingS
            : AppSizes.paddingM,
      ),
      sliver: SliverGrid(
        gridDelegate: ResponsiveUtils.getProductGridDelegate(context),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = state.products[index];
          return ProductCard(
            product: product,
            onTap: () =>
                context.push('${AppRoutes.productDetail}/${product.id}'),
            onFavorite: () =>
                ref.read(productsProvider.notifier).toggleFavorite(product.id),
          );
        }, childCount: state.products.length),
      ),
    );
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = _selectedCategoryId == categoryId
          ? null
          : categoryId;
    });

    final currentFilters = ref.read(productsProvider).filters;
    final newFilters = currentFilters.copyWith(categoryId: _selectedCategoryId);
    ref.read(productsProvider.notifier).applyFilters(newFilters);
  }

  void _performSearch(String query) {
    final currentFilters = ref.read(productsProvider).filters;
    final newFilters = currentFilters.copyWith(searchQuery: query.trim());
    ref.read(productsProvider.notifier).applyFilters(newFilters);
  }

  void _showFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: AppTextStyles.h2.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 20),

            // Price Range
            Text(
              'Price Range',
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    decoration: InputDecoration(
                      hintText: 'Min Price',
                      prefixText: '₱',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    decoration: InputDecoration(
                      hintText: 'Max Price',
                      prefixText: '₱',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Condition
            Text(
              'Condition',
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('New'),
                  selected: _selectedConditions.contains('new'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedConditions.add('new');
                      } else {
                        _selectedConditions.remove('new');
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Like New'),
                  selected: _selectedConditions.contains('like_new'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedConditions.add('like_new');
                      } else {
                        _selectedConditions.remove('like_new');
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Good'),
                  selected: _selectedConditions.contains('good'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedConditions.add('good');
                      } else {
                        _selectedConditions.remove('good');
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Fair'),
                  selected: _selectedConditions.contains('fair'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedConditions.add('fair');
                      } else {
                        _selectedConditions.remove('fair');
                      }
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Apply Filters Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _applyFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    final currentFilters = ref.read(productsProvider).filters;

    // Parse price range
    double? minPrice;
    double? maxPrice;

    if (_minPriceController.text.isNotEmpty) {
      minPrice = double.tryParse(_minPriceController.text);
    }

    if (_maxPriceController.text.isNotEmpty) {
      maxPrice = double.tryParse(_maxPriceController.text);
    }

    // Apply all filters
    final newFilters = currentFilters.copyWith(
      categoryId: _selectedCategoryId,
      searchQuery: _searchController.text.trim(),
      minPrice: minPrice,
      maxPrice: maxPrice,
      // For now, only use the first selected condition
      condition: _selectedConditions.isEmpty
          ? null
          : ProductCondition.values.firstWhere(
              (c) => c.value == _selectedConditions.first,
              orElse: () => ProductCondition.new_,
            ),
    );

    ref.read(productsProvider.notifier).applyFilters(newFilters);
  }
}
