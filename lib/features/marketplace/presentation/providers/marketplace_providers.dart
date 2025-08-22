import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../../../shared/providers/auth_provider.dart';

// Repository provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.getCategories();
});

// Products state
class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final ProductFilters filters;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.filters = const ProductFilters(),
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    String? error,
    ProductFilters? filters,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filters: filters ?? this.filters,
    );
  }
}

// Products notifier
class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier(this.repository, this.userId)
    : super(const ProductsState()) {
    loadProducts();
  }

  final ProductRepository repository;
  final String? userId;
  static const int _pageSize = 20;

  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        products: [],
        isLoading: true,
        hasMore: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final products = await repository.getProducts(
        filters: state.filters,
        limit: _pageSize,
        offset: refresh ? 0 : state.products.length,
      );

      if (refresh) {
        state = state.copyWith(
          products: products,
          isLoading: false,
          hasMore: products.length == _pageSize,
        );
      } else {
        state = state.copyWith(
          products: [...state.products, ...products],
          isLoading: false,
          hasMore: products.length == _pageSize,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilters(ProductFilters filters) async {
    state = state.copyWith(filters: filters);
    await loadProducts(refresh: true);
  }

  Future<void> refreshProducts() async {
    await loadProducts(refresh: true);
  }

  Future<void> loadMoreProducts() async {
    if (!state.hasMore || state.isLoading) return;
    await loadProducts();
  }

  Future<void> toggleFavorite(String productId) async {
    if (userId == null) return;

    try {
      final isFavorited = await repository.toggleFavorite(productId, userId!);

      // Update the product in the list
      final updatedProducts = state.products.map((product) {
        if (product.id == productId) {
          return product.copyWith(isFavorited: isFavorited);
        }
        return product;
      }).toList();

      state = state.copyWith(products: updatedProducts);
    } catch (e) {
      // Handle error silently or show a message
    }
  }
}

// Products provider
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>(
  (ref) {
    final repository = ref.read(productRepositoryProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    return ProductsNotifier(repository, userId);
  },
);

// Featured products provider
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);

  return repository.getProducts(
    filters: const ProductFilters().copyWith(sortBy: ProductSortBy.mostViewed),
    limit: 10,
  );
});

// Single product provider
final productProvider = FutureProvider.family<Product?, String>((
  ref,
  productId,
) async {
  final repository = ref.read(productRepositoryProvider);

  // Increment view count
  repository.incrementViewCount(productId);

  return repository.getProductById(productId);
});

// User's products provider
final userProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return [];

  return repository.getProductsBySeller(user.id);
});

// User's favorites provider
final userFavoritesProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return [];

  return repository.getUserFavorites(user.id);
});

// Search provider
class SearchState {
  final String query;
  final List<Product> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<Product>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this.repository) : super(const SearchState());

  final ProductRepository repository;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    try {
      final results = await repository.searchProducts(query);

      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> searchWithFilters({
    required ProductFilters filters,
    ProductSortBy sortBy = ProductSortBy.newest,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      query: filters.searchQuery ?? '',
    );
    try {
      final results = await repository.getProducts(
        filters: filters.copyWith(sortBy: sortBy),
        limit: 40,
        offset: 0,
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = const SearchState();
  }

  void setResults(List<Product> results) {
    state = state.copyWith(results: results, isLoading: false, error: null);
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  final repository = ref.read(productRepositoryProvider);
  return SearchNotifier(repository);
});

// Current filters provider
final currentFiltersProvider = StateProvider<ProductFilters>((ref) {
  return const ProductFilters();
});

// Product creation state
class ProductCreationState {
  final bool isLoading;
  final String? error;
  final Product? createdProduct;

  const ProductCreationState({
    this.isLoading = false,
    this.error,
    this.createdProduct,
  });

  ProductCreationState copyWith({
    bool? isLoading,
    String? error,
    Product? createdProduct,
  }) {
    return ProductCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdProduct: createdProduct ?? this.createdProduct,
    );
  }
}

class ProductCreationNotifier extends StateNotifier<ProductCreationState> {
  ProductCreationNotifier(this.repository)
    : super(const ProductCreationState());

  final ProductRepository repository;

  Future<bool> createProduct(Product product) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final createdProduct = await repository.createProduct(product);
      state = state.copyWith(isLoading: false, createdProduct: createdProduct);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedProduct = await repository.updateProduct(product);
      state = state.copyWith(isLoading: false, createdProduct: updatedProduct);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await repository.deleteProduct(productId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearState() {
    state = const ProductCreationState();
  }
}

final productCreationProvider =
    StateNotifierProvider<ProductCreationNotifier, ProductCreationState>((ref) {
      final repository = ref.read(productRepositoryProvider);
      return ProductCreationNotifier(repository);
    });
