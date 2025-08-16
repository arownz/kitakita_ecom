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

      // If no products in database, return mock data for demonstration
      if (response.isEmpty) {
        return _getMockProducts(filters: filters, limit: limit, offset: offset);
      }

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

      // If no categories in database, return mock data
      if (response.isEmpty) {
        return _getMockCategories();
      }

      return (response as List).map((item) => Category.fromJson(item)).toList();
    } catch (e) {
      // Return mock data if there's an error
      return _getMockCategories();
    }
  }

  List<Category> _getMockCategories() {
    return [
      Category(
        id: '1',
        name: 'Textbooks',
        description: 'Academic books and study materials',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '2',
        name: 'Electronics',
        description: 'Gadgets, laptops, and tech accessories',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '3',
        name: 'Clothing',
        description: 'Apparel and fashion items',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '4',
        name: 'School Supplies',
        description: 'Stationery, notebooks, and supplies',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '5',
        name: 'Sports',
        description: 'Sports equipment and gear',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '6',
        name: 'Food & Drinks',
        description: 'Snacks, beverages, and meal deals',
        createdAt: DateTime.now(),
      ),
    ];
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

  List<Product> _getMockProducts({
    ProductFilters? filters,
    int limit = 20,
    int offset = 0,
  }) {
    List<Product> mockProducts = [
      Product(
        id: '1',
        title: 'Engineering Mathematics Textbook',
        description:
            'Comprehensive engineering mathematics textbook used for only one semester. No highlighting or damage.',
        price: 1500.0,
        condition: ProductCondition.likeNew,
        categoryId: '1',
        categoryName: 'Textbooks',
        sellerId: 'seller1',
        sellerName: 'Maria Santos',
        location: 'University Campus',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        viewCount: 45,
        isFavorited: false,
        isAvailable: true,
      ),
      Product(
        id: '2',
        title: 'Gaming Laptop - ASUS ROG',
        description:
            'Powerful gaming laptop with RTX 3060, 16GB RAM, perfect for CS students and gaming.',
        price: 45000.0,
        condition: ProductCondition.likeNew,
        categoryId: '2',
        categoryName: 'Electronics',
        sellerId: 'seller2',
        sellerName: 'John Doe',
        location: 'Engineering Building',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        viewCount: 128,
        isFavorited: true,
        isAvailable: true,
      ),
      Product(
        id: '3',
        title: 'Physics Lab Manual',
        description:
            'Complete physics laboratory manual with all experiments. Includes data sheets.',
        price: 800.0,
        condition: ProductCondition.good,
        categoryId: '1',
        categoryName: 'Textbooks',
        sellerId: 'seller3',
        sellerName: 'Anna Cruz',
        location: 'Science Building',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        viewCount: 23,
        isFavorited: false,
        isAvailable: true,
      ),
      Product(
        id: '4',
        title: 'School Supplies Bundle',
        description:
            'Complete set of school supplies: notebooks, pens, highlighters, calculator.',
        price: 350.0,
        condition: ProductCondition.new_,
        categoryId: '4',
        categoryName: 'School Supplies',
        sellerId: 'seller4',
        sellerName: 'Mike Johnson',
        location: 'Library Area',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        viewCount: 15,
        isFavorited: false,
        isAvailable: true,
      ),
      Product(
        id: '5',
        title: 'Basketball Shoes - Nike',
        description:
            'Barely used Nike basketball shoes, size 9. Perfect for PE classes and sports.',
        price: 2500.0,
        condition: ProductCondition.likeNew,
        categoryId: '5',
        categoryName: 'Sports',
        sellerId: 'seller5',
        sellerName: 'Sarah Lee',
        location: 'Gym Building',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        viewCount: 32,
        isFavorited: false,
        isAvailable: true,
      ),
      Product(
        id: '6',
        title: 'Calculus Textbook',
        description:
            'Stewart Calculus 8th Edition. Excellent condition with solution manual included.',
        price: 1200.0,
        condition: ProductCondition.likeNew,
        categoryId: '1',
        categoryName: 'Textbooks',
        sellerId: 'seller6',
        sellerName: 'David Kim',
        location: 'Math Building',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        viewCount: 8,
        isFavorited: true,
        isAvailable: true,
      ),
    ];

    // Apply filters
    if (filters != null) {
      if (filters.searchQuery?.isNotEmpty == true) {
        mockProducts = mockProducts.where((product) {
          return product.title.toLowerCase().contains(
                filters.searchQuery!.toLowerCase(),
              ) ||
              product.description.toLowerCase().contains(
                filters.searchQuery!.toLowerCase(),
              );
        }).toList();
      }

      if (filters.categoryId != null) {
        mockProducts = mockProducts.where((product) {
          return product.categoryId == filters.categoryId;
        }).toList();
      }

      if (filters.minPrice != null) {
        mockProducts = mockProducts.where((product) {
          return product.price >= filters.minPrice!;
        }).toList();
      }

      if (filters.maxPrice != null) {
        mockProducts = mockProducts.where((product) {
          return product.price <= filters.maxPrice!;
        }).toList();
      }

      if (filters.condition != null) {
        mockProducts = mockProducts.where((product) {
          return product.condition == filters.condition;
        }).toList();
      }

      // Apply sorting
      switch (filters.sortBy) {
        case ProductSortBy.newest:
          mockProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case ProductSortBy.oldest:
          mockProducts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case ProductSortBy.priceLowToHigh:
          mockProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case ProductSortBy.priceHighToLow:
          mockProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case ProductSortBy.mostViewed:
          mockProducts.sort((a, b) => b.viewCount.compareTo(a.viewCount));
          break;
        case ProductSortBy.mostFavorited:
          // Mock favorited sorting
          mockProducts.sort(
            (a, b) => ((b.isFavorited ?? false) ? 1 : 0).compareTo(
              (a.isFavorited ?? false) ? 1 : 0,
            ),
          );
          break;
      }
    }

    // Apply pagination
    final start = offset;
    final end = (start + limit).clamp(0, mockProducts.length);

    if (start >= mockProducts.length) return [];
    return mockProducts.sublist(start, end);
  }
}
