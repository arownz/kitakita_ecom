import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/router/app_router.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../../domain/models/product.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;
  // TODO: Implement price filtering
  // double _minPrice = 0;
  // double _maxPrice = 10000;
  // String _sortBy = 'newest';
  bool _showFilters = false;

  // TODO: Implement sorting options when advanced search is ready
  // final List<String> _sortOptions = [
  //   'newest',
  //   'oldest',
  //   'price_low',
  //   'price_high',
  //   'name_asc',
  //   'name_desc',
  // ];

  // final Map<String, String> _sortLabels = {
  //   'newest': 'Newest First',
  //   'oldest': 'Oldest First',
  //   'price_low': 'Price: Low to High',
  //   'price_high': 'Price: High to Low',
  //   'name_asc': 'Name: A to Z',
  //   'name_desc': 'Name: Z to A',
  // };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Filters (collapsible)
          if (_showFilters) ...[
            categoriesAsync.when(
              data: (categories) => _buildFiltersSection(categories),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ],

          // Results
          Expanded(child: _buildResults(searchState.results)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtils.isMobile(context)
            ? AppSizes.paddingM
            : AppSizes.paddingL,
      ),
      color: AppColors.primaryBlue.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search for products...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primaryBlue,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textGray,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingM,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _debounceSearch();
                },
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spaceM),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: AppColors.white),
              onPressed: _performSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(List<Category> categories) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtils.isMobile(context)
            ? AppSizes.paddingM
            : AppSizes.paddingL,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Categories
          Text(
            'Categories',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSizes.spaceS),
                    child: CategoryChip(
                      category: Category(
                        id: '',
                        name: 'All',
                        description: 'All categories',
                        createdAt: DateTime.now(),
                      ),
                      isSelected: _selectedCategoryId == null,
                      onTap: (_) {
                        setState(() {
                          _selectedCategoryId = null;
                        });
                        _performSearch();
                      },
                    ),
                  );
                }
                final category = categories[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.spaceS),
                  child: CategoryChip(
                    category: category,
                    isSelected: _selectedCategoryId == category.id,
                    onTap: (categoryId) {
                      setState(() {
                        _selectedCategoryId = categoryId;
                      });
                      _performSearch();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSizes.spaceM),

          // TODO: Implement price range filtering
          // Text(
          //   'Price Range',
          //   style: AppTextStyles.bodyMedium.copyWith(
          //     fontWeight: FontWeight.w600,
          //   ),
          // ),
          // const SizedBox(height: AppSizes.spaceS),
          // Row(
          //   children: [
          //     Expanded(
          //       child: TextField(
          //         decoration: const InputDecoration(
          //           labelText: 'Min Price',
          //           prefixText: '₱',
          //           border: OutlineInputBorder(),
          //           contentPadding: EdgeInsets.symmetric(
          //             horizontal: 12,
          //             vertical: 8,
          //           ),
          //         ),
          //         keyboardType: TextInputType.number,
          //         onChanged: (value) {
          //           _minPrice = double.tryParse(value) ?? 0;
          //         },
          //       ),
          //     ),
          //     const SizedBox(height: AppSizes.spaceM),
          //     Expanded(
          //       child: TextField(
          //           labelText: 'Max Price',
          //           prefixText: '₱',
          //           border: OutlineInputBorder(),
          //           contentPadding: EdgeInsets.symmetric(
          //             horizontal: 12,
          //             vertical: 8,
          //           ),
          //         ),
          //         keyboardType: TextInputType.number,
          //         onChanged: (value) {
          //           _maxPrice = double.tryParse(value) ?? 10000;
          //         },
          //       ),
          //     ),
          //   ],
          // ),

          // const SizedBox(height: AppSizes.spaceM),

          // TODO: Implement sorting
          // Row(
          //   children: [
          //     Text(
          //       'Sort by:',
          //       style: AppTextStyles.bodyMedium.copyWith(
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //     const SizedBox(width: AppSizes.spaceM),
          //     Expanded(
          //       child: DropdownButtonFormField<String>(
          //         value: _sortBy,
          //         decoration: const InputDecoration(
          //           border: OutlineInputBorder(),
          //           contentPadding: EdgeInsets.symmetric(
          //             horizontal: 12,
          //             vertical: 8,
          //           ),
          //         ),
          //         items: _sortOptions.map((option) {
          //           return DropdownMenuItem(
          //             child: Text(_sortLabels[option] ?? option),
          //           );
          //         }).toList(),
          //         onChanged: (value) {
          //           setState(() {
          //             _sortBy = value!;
          //           });
          //           _performSearch();
          //         },
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: AppSizes.spaceM),

          // Apply Filters Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Product> products) {
    if (products.isEmpty) {
      return _buildEmptyState();
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
            '${products.length} results found',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
          ),
          const SizedBox(height: AppSizes.spaceM),
          Expanded(
            child: GridView.builder(
              gridDelegate: ResponsiveUtils.getProductGridDelegate(context),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () =>
                      context.push('${AppRoutes.productDetail}/${product.id}'),
                  onFavorite: () => ref
                      .read(productsProvider.notifier)
                      .toggleFavorite(product.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSizes.spaceM),
          Text(
            'No products found',
            style: AppTextStyles.h3.copyWith(color: AppColors.textGray),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            'Try adjusting your search or filters',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceL),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedCategoryId = null;
                // TODO: Reset price and sort filters when implemented
              });
              _performSearch();
            },
            child: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    // TODO: Implement advanced search with filters and sorting
    ref.read(searchProvider.notifier).search(_searchController.text.trim());
  }

  void _debounceSearch() {
    // Simple debounce - in production, use a proper debounce package
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performSearch();
      }
    });
  }
}
