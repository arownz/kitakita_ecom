import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/search_bar_widget.dart';
import '../../domain/models/product.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final currentUser = ref.watch(currentUserProvider);

    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(color: AppColors.gray),

          // Background with campus theme
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/campusbackground.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      _buildDesktopNavRail(context),
                      Expanded(
                        child: _buildMainScroll(categoriesAsync, productsState),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: _buildMainScroll(categoriesAsync, productsState),
                      ),
                    ],
                  ),
          ),
        ],
      ),

      // Floating action button for adding products
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.addProduct),
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.black,
              child: const Icon(Icons.add),
            )
          : null,

      // Bottom navigation (placeholder for now)
      bottomNavigationBar: isDesktop ? null : _buildBottomNavigation(context),
    );
  }

  Widget _buildMainScroll(
    AsyncValue<List<Category>> categoriesAsync,
    ProductsState productsState,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildSearchSection(context)),
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

  Widget _buildDesktopNavRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: 0,
      backgroundColor: AppColors.white,
      extended: true,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
        NavigationRailDestination(
          icon: Icon(Icons.search),
          label: Text('Search'),
        ),
        NavigationRailDestination(icon: Icon(Icons.chat), label: Text('Chat')),
        NavigationRailDestination(
          icon: Icon(Icons.favorite),
          label: Text('Favorites'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.push(AppRoutes.search);
            break;
          case 2:
            context.push(AppRoutes.chatList);
            break;
          case 3:
            _showFavoritesBottomSheet(context);
            break;
          case 4:
            context.push(AppRoutes.profile);
            break;
        }
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: AppSizes.appBarHeight,
      width: double.infinity,
      color: AppColors.primaryBlue,
      child: Stack(
        children: [
          // Yellow accent bar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Row(
              children: [
                // Menu/Drawer icon
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.white),
                    onPressed: () => _showSideMenu(context),
                  ),
                ),

                const SizedBox(width: AppSizes.spaceS),

                // App title
                Text(
                  'KitaKita',
                  style: AppTextStyles.navTitle.copyWith(
                    fontSize: ResponsiveUtils.getFontSize(
                      context,
                      ResponsiveUtils.isMobile(context) ? 18 : 20,
                    ),
                  ),
                ),

                const Spacer(),

                // Notification icon
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.white,
                  ),
                  onPressed: () => context.push(AppRoutes.notifications),
                ),

                // Profile icon
                IconButton(
                  icon: const Icon(
                    Icons.person_outline,
                    color: AppColors.white,
                  ),
                  onPressed: () => context.push(AppRoutes.profile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      padding: ResponsiveUtils.isMobile(context)
          ? const EdgeInsets.all(AppSizes.paddingS)
          : const EdgeInsets.all(AppSizes.paddingM),
      child: const SearchBarWidget(),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSizes.spaceM),
              Text('Failed to load products', style: AppTextStyles.h3),
              const SizedBox(height: AppSizes.spaceS),
              Text(
                state.error!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceL),
              ElevatedButton(
                onPressed: () =>
                    ref.read(productsProvider.notifier).refreshProducts(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.products.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, size: 64, color: AppColors.gray),
              SizedBox(height: AppSizes.spaceM),
              Text('No products found', style: AppTextStyles.h3),
              SizedBox(height: AppSizes.spaceS),
              Text(
                'Be the first to add a product!',
                style: AppTextStyles.bodyMedium,
              ),
            ],
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

  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textGray,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            context.push(AppRoutes.search);
            break;
          case 2:
            context.push(AppRoutes.chatList);
            break;
          case 3:
            _showFavoritesBottomSheet(context);
            break;
          case 4:
            context.push(AppRoutes.profile);
            break;
        }
      },
    );
  }

  void _showSideMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusL),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add Product'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.addProduct);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.chatList);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.profile);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        ),
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

  void _showFavoritesBottomSheet(BuildContext context) {
    final products = ref.read(productsProvider).products;
    final favorites = products.where((p) => p.isFavorited == true).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusL),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Favorites', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.spaceM),
            if (favorites.isEmpty)
              const Text('No favorites yet.')
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final product = favorites[index];
                    return ListTile(
                      title: Text(product.title),
                      subtitle: Text(product.formattedPrice),
                      onTap: () => context.push(
                        '${AppRoutes.productDetail}/${product.id}',
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
