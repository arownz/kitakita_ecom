import '../../domain/models/product.dart';
import '../../../../shared/services/supabase_service.dart';

class ProductRepository {
  static const String _productsTable = 'products';
  static const String _categoriesTable = 'categories';
  static const String _favoritesTable = 'user_favorites';

  // Get products with filters and pagination
  Future<List<Product>> getProducts({
    ProductFilters? filters,
    int limit = 20,
    int offset = 0,
    String? userId,
  }) async {
    try {
      var query = SupabaseService.from(_productsTable).select('''
            *,
            categories(name),
            user_profiles!seller_id(first_name, last_name),
            user_favorites!left(user_id)
          ''');

      // Apply filters
      if (filters != null) {
        if (filters.isAvailable != null) {
          query = query.eq('is_available', filters.isAvailable!);
        }

        if (filters.categoryId != null) {
          query = query.eq('category_id', filters.categoryId!);
        }

        if (filters.searchQuery?.isNotEmpty == true) {
          query = query.textSearch('title,description', filters.searchQuery!);
        }

        if (filters.minPrice != null) {
          query = query.gte('price', filters.minPrice!);
        }

        if (filters.maxPrice != null) {
          query = query.lte('price', filters.maxPrice!);
        }

        if (filters.condition != null) {
          query = query.eq('condition', filters.condition!.value);
        }

        if (filters.location?.isNotEmpty == true) {
          query = query.ilike('location', '%${filters.location}%');
        }

        // Apply sorting
        switch (filters.sortBy) {
          case ProductSortBy.newest:
            break;
          case ProductSortBy.oldest:
            break;
          case ProductSortBy.priceLowToHigh:
            break;
          case ProductSortBy.priceHighToLow:
            break;
          case ProductSortBy.mostViewed:
            break;
          case ProductSortBy.mostFavorited:
            break;
        }
      }

      // Apply ordering and range after filtering to avoid type issues
      final orderedQuery = query.order('created_at', ascending: false);
      final limitedQuery = orderedQuery.range(offset, offset + limit - 1);

      final response = await limitedQuery;

      return (response as List).map((item) {
        final Map<String, dynamic> productData = Map<String, dynamic>.from(
          item,
        );

        // Add seller name
        final profile = productData['user_profiles'];
        if (profile != null) {
          productData['seller_name'] =
              '${profile['first_name']} ${profile['last_name']}';
        }

        // Add category name
        final category = productData['categories'];
        if (category != null) {
          productData['category_name'] = category['name'];
        }

        // Check if favorited by current user
        final favorites = productData['user_favorites'] as List?;
        productData['is_favorited'] =
            userId != null &&
            favorites?.any((fav) => fav['user_id'] == userId) == true;

        // Remove nested objects for clean parsing
        productData.remove('user_profiles');
        productData.remove('categories');
        productData.remove('user_favorites');

        return Product.fromJson(productData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String productId, {String? userId}) async {
    try {
      final response = await SupabaseService.from(_productsTable)
          .select('''
            *,
            categories(name),
            user_profiles!seller_id(first_name, last_name),
            user_favorites!left(user_id)
          ''')
          .eq('id', productId)
          .single();

      final Map<String, dynamic> productData = Map<String, dynamic>.from(
        response,
      );

      // Add seller name
      final profile = productData['user_profiles'];
      if (profile != null) {
        productData['seller_name'] =
            '${profile['first_name']} ${profile['last_name']}';
      }

      // Add category name
      final category = productData['categories'];
      if (category != null) {
        productData['category_name'] = category['name'];
      }

      // Check if favorited by current user
      final favorites = productData['user_favorites'] as List?;
      productData['is_favorited'] =
          userId != null &&
          favorites?.any((fav) => fav['user_id'] == userId) == true;

      // Remove nested objects for clean parsing
      productData.remove('user_profiles');
      productData.remove('categories');
      productData.remove('user_favorites');

      return Product.fromJson(productData);
    } catch (e) {
      return null;
    }
  }

  // Get products by seller
  Future<List<Product>> getProductsBySeller(String sellerId) async {
    try {
      final response = await SupabaseService.from(_productsTable)
          .select('*, categories(name)')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final Map<String, dynamic> productData = Map<String, dynamic>.from(
          item,
        );

        // Add category name
        final category = productData['categories'];
        if (category != null) {
          productData['category_name'] = category['name'];
        }
        productData.remove('categories');

        return Product.fromJson(productData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch seller products: $e');
    }
  }

  // Create new product
  Future<Product> createProduct(Product product) async {
    try {
      final productData = product.toJson();
      productData.remove('id'); // Let Supabase generate the ID
      productData.remove('created_at');
      productData.remove('updated_at');

      final response = await SupabaseService.from(
        _productsTable,
      ).insert(productData).select().single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  Future<Product> updateProduct(Product product) async {
    try {
      final productData = product.toJson();
      productData.remove('created_at'); // Don't update created_at
      productData['updated_at'] = DateTime.now().toIso8601String();

      final response = await SupabaseService.from(
        _productsTable,
      ).update(productData).eq('id', product.id).select().single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await SupabaseService.from(_productsTable).delete().eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String productId) async {
    try {
      await SupabaseService.client.rpc(
        'increment_product_views',
        params: {'product_uuid': productId},
      );
    } catch (e) {
      // Fail silently for view counts
    }
  }

  // Get categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await SupabaseService.from(
        _categoriesTable,
      ).select().eq('is_active', true).order('name');

      return (response as List).map((item) => Category.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String productId, String userId) async {
    try {
      // Check if already favorited
      final existing = await SupabaseService.from(_favoritesTable)
          .select()
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Remove favorite
        await SupabaseService.from(
          _favoritesTable,
        ).delete().eq('product_id', productId).eq('user_id', userId);
        return false;
      } else {
        // Add favorite
        await SupabaseService.from(
          _favoritesTable,
        ).insert({'product_id': productId, 'user_id': userId});
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Get user favorites
  Future<List<Product>> getUserFavorites(String userId) async {
    try {
      final response = await SupabaseService.from(_favoritesTable)
          .select('''
            products(
              *,
              categories(name),
              user_profiles!seller_id(first_name, last_name)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final productData = Map<String, dynamic>.from(item['products']);

        // Add seller name
        final profile = productData['user_profiles'];
        if (profile != null) {
          productData['seller_name'] =
              '${profile['first_name']} ${profile['last_name']}';
        }

        // Add category name
        final category = productData['categories'];
        if (category != null) {
          productData['category_name'] = category['name'];
        }

        // Mark as favorited
        productData['is_favorited'] = true;

        // Remove nested objects
        productData.remove('user_profiles');
        productData.remove('categories');

        return Product.fromJson(productData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch favorites: $e');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(
    String query, {
    int limit = 20,
    int offset = 0,
    String? userId,
  }) async {
    final filters = ProductFilters(
      searchQuery: query,
      sortBy: ProductSortBy.newest,
    );

    return getProducts(
      filters: filters,
      limit: limit,
      offset: offset,
      userId: userId,
    );
  }
}
