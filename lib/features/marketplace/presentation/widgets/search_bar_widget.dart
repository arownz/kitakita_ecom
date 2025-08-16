import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../providers/marketplace_providers.dart';
import '../../domain/models/product.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      // Apply search filter to products
      final currentFilters = ref.read(currentFiltersProvider);
      final newFilters = currentFilters.copyWith(searchQuery: query.trim());
      ref.read(productsProvider.notifier).applyFilters(newFilters);
      ref.read(currentFiltersProvider.notifier).state = newFilters;
    }
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _controller.clear();
    final currentFilters = ref.read(currentFiltersProvider);
    final newFilters = currentFilters.copyWith(searchQuery: null);
    ref.read(productsProvider.notifier).applyFilters(newFilters);
    ref.read(currentFiltersProvider.notifier).state = newFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.searchBarHeight,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Icon(Icons.search, color: AppColors.textGray, size: 20),
          ),

          // Search input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: AppTextStyles.inputHint,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: _onSearchSubmitted,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Clear button (when there's text)
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.clear,
                color: AppColors.textGray,
                size: 20,
              ),
              onPressed: _clearSearch,
            ),

          // Filter button
          Container(
            margin: const EdgeInsets.all(AppSizes.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: AppColors.black, size: 20),
              onPressed: () => _showFilterDialog(context),
              padding: const EdgeInsets.all(AppSizes.paddingS),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusL),
        ),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }
}

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late ProductFilters _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = ref.read(currentFiltersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Products', style: AppTextStyles.h3),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spaceL),

          // Category filter
          categoriesAsync.when(
            data: (categories) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceS),
                Wrap(
                  spacing: AppSizes.spaceS,
                  runSpacing: AppSizes.spaceS,
                  children: [
                    // All categories chip
                    FilterChip(
                      label: const Text('All'),
                      selected: _tempFilters.categoryId == null,
                      onSelected: (selected) {
                        setState(() {
                          _tempFilters = _tempFilters.copyWith(
                            categoryId: null,
                          );
                        });
                      },
                    ),
                    // Category chips
                    ...categories.map(
                      (category) => FilterChip(
                        label: Text(category.name),
                        selected: _tempFilters.categoryId == category.id,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilters = _tempFilters.copyWith(
                              categoryId: selected ? category.id : null,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSizes.spaceL),

          // Price range filter
          Text(
            'Price Range',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixText: '₱',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    setState(() {
                      _tempFilters = _tempFilters.copyWith(minPrice: price);
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '₱',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    setState(() {
                      _tempFilters = _tempFilters.copyWith(maxPrice: price);
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spaceL),

          // Sort by
          Text(
            'Sort By',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Wrap(
            spacing: AppSizes.spaceS,
            runSpacing: AppSizes.spaceS,
            children: ProductSortBy.values
                .map(
                  (sortBy) => FilterChip(
                    label: Text(_getSortByLabel(sortBy)),
                    selected: _tempFilters.sortBy == sortBy,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _tempFilters = _tempFilters.copyWith(sortBy: sortBy);
                        });
                      }
                    },
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: AppSizes.spaceXL),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _tempFilters = const ProductFilters();
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(currentFiltersProvider.notifier).state =
                        _tempFilters;
                    ref
                        .read(productsProvider.notifier)
                        .applyFilters(_tempFilters);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortByLabel(ProductSortBy sortBy) {
    switch (sortBy) {
      case ProductSortBy.newest:
        return 'Newest';
      case ProductSortBy.oldest:
        return 'Oldest';
      case ProductSortBy.priceLowToHigh:
        return 'Price: Low to High';
      case ProductSortBy.priceHighToLow:
        return 'Price: High to Low';
      case ProductSortBy.mostViewed:
        return 'Most Viewed';
      case ProductSortBy.mostFavorited:
        return 'Most Favorited';
    }
  }
}
