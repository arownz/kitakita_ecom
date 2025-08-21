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
  // Basic filter state (wired to provider searchWithFilters)
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _sortBy = 'newest';
  bool _showFilters = false;

  // Demo book items for testing
  final List<Map<String, dynamic>> _demoBooks = [
    {
      'title': 'Engineering Mathematics Textbook',
      'description':
          'Comprehensive engineering mathematics textbook used for only one semester. No highlighting or damage.',
      'price': 1500.0,
      'condition': 'likeNew',
      'category': 'Textbooks',
      'location': 'University Campus',
      'seller': 'Maria Santos',
      'views': 45,
    },
    {
      'title': 'Calculus: Early Transcendentals',
      'description':
          'James Stewart calculus textbook, 8th edition. Excellent condition with minimal wear.',
      'price': 1200.0,
      'condition': 'excellent',
      'category': 'Textbooks',
      'location': 'Engineering Building',
      'seller': 'Juan Dela Cruz',
      'views': 32,
    },
    {
      'title': 'Physics for Scientists and Engineers',
      'description':
          'Serway physics textbook with practice problems. Good condition, some notes in margins.',
      'price': 800.0,
      'condition': 'good',
      'category': 'Textbooks',
      'location': 'Science Complex',
      'seller': 'Ana Rodriguez',
      'views': 28,
    },
    {
      'title': 'Organic Chemistry Lab Manual',
      'description':
          'Lab manual for organic chemistry experiments. Like new, never used.',
      'price': 600.0,
      'condition': 'likeNew',
      'category': 'Lab Manuals',
      'location': 'Chemistry Department',
      'seller': 'Carlos Mendoza',
      'views': 15,
    },
    {
      'title': 'Computer Science Fundamentals',
      'description':
          'Introduction to computer science concepts. Excellent condition, no markings.',
      'price': 900.0,
      'condition': 'excellent',
      'category': 'Textbooks',
      'location': 'Computer Science Building',
      'seller': 'Lisa Chen',
      'views': 38,
    },
    {
      'title': 'Business Management Principles',
      'description':
          'Core business management textbook. Good condition with some highlighting.',
      'price': 700.0,
      'condition': 'good',
      'category': 'Business',
      'location': 'Business School',
      'seller': 'Michael Johnson',
      'views': 22,
    },
    {
      'title': 'Spanish Language Workbook',
      'description':
          'Intermediate Spanish practice workbook. Fair condition, some pages completed.',
      'price': 300.0,
      'condition': 'fair',
      'category': 'Language',
      'location': 'Language Center',
      'seller': 'Sofia Martinez',
      'views': 12,
    },
    {
      'title': 'Art History Survey',
      'description':
          'Comprehensive art history textbook with color plates. Excellent condition.',
      'price': 1100.0,
      'condition': 'excellent',
      'category': 'Arts',
      'location': 'Fine Arts Building',
      'seller': 'David Kim',
      'views': 19,
    },
  ];

  // Sorting options are wired via _sortBy and ProductSortBy mapping in _performSearch

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

          // Price Range
          Text(
            'Price Range',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
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
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _minPrice = double.tryParse(value) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '₱',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxPrice = double.tryParse(value) ?? 10000;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spaceM),

          Row(
            children: [
              Text(
                'Sort by:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text('Newest First'),
                    ),
                    DropdownMenuItem(
                      value: 'oldest',
                      child: Text('Oldest First'),
                    ),
                    DropdownMenuItem(
                      value: 'price_low',
                      child: Text('Price: Low to High'),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text('Price: High to Low'),
                    ),
                    DropdownMenuItem(
                      value: 'most_viewed',
                      child: Text('Most Viewed'),
                    ),
                    DropdownMenuItem(
                      value: 'most_favorited',
                      child: Text('Most Favorited'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value ?? 'newest';
                    });
                    _performSearch();
                  },
                ),
              ),
            ],
          ),
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
                // Reset price and sort filters
                _minPrice = 0;
                _maxPrice = 10000;
                _sortBy = 'newest';
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
    final sort = () {
      switch (_sortBy) {
        case 'oldest':
          return ProductSortBy.oldest;
        case 'price_low':
          return ProductSortBy.priceLowToHigh;
        case 'price_high':
          return ProductSortBy.priceHighToLow;
        case 'most_viewed':
          return ProductSortBy.mostViewed;
        case 'most_favorited':
          return ProductSortBy.mostFavorited;
        case 'newest':
        default:
          return ProductSortBy.newest;
      }
    }();

    final filters = ProductFilters(
      searchQuery: _searchController.text.trim(),
      categoryId: _selectedCategoryId,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sortBy: sort,
    );

    // If no search query and no filters, show demo books
    if (_searchController.text.trim().isEmpty &&
        _selectedCategoryId == null &&
        _minPrice == 0 &&
        _maxPrice == 10000) {
      _showDemoResults();
    } else {
      ref
          .read(searchProvider.notifier)
          .searchWithFilters(filters: filters, sortBy: sort);
    }
  }

  void _showDemoResults() {
    // Filter demo books based on current filters
    List<Map<String, dynamic>> filteredBooks = _demoBooks.where((book) {
      // Category filter
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        final category = ref
            .read(categoriesProvider)
            .value
            ?.firstWhere(
              (cat) => cat.id == _selectedCategoryId,
              orElse: () => Category(
                id: '',
                name: '',
                description: '',
                createdAt: DateTime.now(),
              ),
            );
        if (category != null && book['category'] != category.name) {
          return false;
        }
      }

      // Price filter
      if (book['price'] < _minPrice || book['price'] > _maxPrice) {
        return false;
      }

      return true;
    }).toList();

    // Sort demo books
    switch (_sortBy) {
      case 'price_low':
        filteredBooks.sort(
          (a, b) => (a['price'] as double).compareTo(b['price'] as double),
        );
        break;
      case 'price_high':
        filteredBooks.sort(
          (a, b) => (b['price'] as double).compareTo(a['price'] as double),
        );
        break;
      case 'most_viewed':
        filteredBooks.sort(
          (a, b) => (b['views'] as int).compareTo(a['views'] as int),
        );
        break;
      case 'oldest':
        // Demo books don't have dates, so keep original order
        break;
      default: // newest
        // Keep original order for demo
        break;
    }

    // Convert demo books to Product objects for display
    final demoProducts = filteredBooks
        .map(
          (book) => Product(
            id: 'demo_${book['title'].hashCode}',
            title: book['title'],
            description: book['description'],
            price: book['price'],
            condition: _getProductCondition(book['condition']),
            categoryId: 'demo_category',
            categoryName: book['category'],
            sellerId: 'demo_seller',
            sellerName: book['seller'],
            location: book['location'],
            images: [],
            createdAt: DateTime.now().subtract(Duration(days: book['views'])),
            updatedAt: DateTime.now().subtract(Duration(days: book['views'])),
            viewCount: book['views'],
            isFavorited: false,
            isAvailable: true,
          ),
        )
        .toList();

    // Update the search provider with demo results
    ref.read(searchProvider.notifier).setResults(demoProducts);
  }

  ProductCondition _getProductCondition(String condition) {
    switch (condition) {
      case 'likeNew':
        return ProductCondition.likeNew;
      case 'excellent':
        return ProductCondition.likeNew;
      case 'good':
        return ProductCondition.good;
      case 'fair':
        return ProductCondition.fair;
      case 'poor':
        return ProductCondition.poor;
      default:
        return ProductCondition.good;
    }
  }

  void _debounceSearch() {
    // Simple debounce - in production, use a proper debounce package
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _performSearch();
    });
  }
}
