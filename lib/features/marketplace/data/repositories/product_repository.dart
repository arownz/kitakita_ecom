import '../../domain/models/product.dart';
import '../../../../shared/services/supabase_service.dart';
import 'package:logger/logger.dart';

class ProductRepository {
  static const String _productsTable = 'products';
  static const String _categoriesTable = 'categories';
  static const String _favoritesTable = 'user_favorites';

  final _logger = Logger();

  // Get products with filters and pagination
  Future<List<Product>> getProducts({
    int offset = 0,
    int limit = 20,
    ProductFilters? filters,
  }) async {
    try {
      var query = SupabaseService.from('products').select('''
            *,
            categories(name),
            user_favorites!left(user_id)
          ''');

      // Apply filters
      if (filters != null) {
        if (filters.categoryId != null) {
          query = query.eq('category_id', filters.categoryId!);
        }
        if (filters.minPrice != null) {
          query = query.gte('price', filters.minPrice!);
        }
        if (filters.maxPrice != null) {
          query = query.lte('price', filters.maxPrice!);
        }
        if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
          query = query.or(
            'title.ilike.%${filters.searchQuery}%,description.ilike.%${filters.searchQuery}%',
          );
        }
        if (filters.condition != null) {
          query = query.eq('condition', filters.condition!.name);
        }
        if (filters.location != null && filters.location!.isNotEmpty) {
          query = query.ilike('location', '%${filters.location}%');
        }
      }

      // Apply ordering and pagination
      final finalQuery = query
          .eq('is_available', true)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await finalQuery;
      final List<Product> products = [];

      for (final row in response) {
        try {
          final categoryName =
              (row['categories'] as Map<String, dynamic>?)?['name'] ??
              'Unknown';
          final favorites = row['user_favorites'] as List<dynamic>? ?? [];
          final isFavorited = favorites.isNotEmpty;

          final product = Product(
            id: row['id'] ?? '',
            sellerId: row['seller_id'] ?? '',
            categoryId: row['category_id'] ?? '',
            categoryName: categoryName,
            title: row['title'] ?? '',
            description: row['description'] ?? '',
            price: (row['price'] ?? 0).toDouble(),
            condition: _parseProductCondition(row['condition'] ?? ''),
            location: row['location'] ?? '',
            images: List<String>.from(row['images'] ?? []),
            isAvailable: row['is_available'] ?? true,
            isFavorited: isFavorited,
            createdAt:
                DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
            updatedAt:
                DateTime.tryParse(row['updated_at'] ?? '') ?? DateTime.now(),
          );
          products.add(product);
        } catch (e) {
          _logger.w('Error parsing product: $e');
          continue;
        }
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Helper method to parse product condition
  ProductCondition _parseProductCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
      case 'brand new':
        return ProductCondition.new_;
      case 'like new':
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

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
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

      // Check if favorited by current user (for now, just mark as not favorited)
      productData['is_favorited'] = false;

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
        name: 'Lab Manuals',
        description: 'Laboratory guides and experiment manuals',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '3',
        name: 'Business',
        description: 'Business and management materials',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '4',
        name: 'Language',
        description: 'Language learning materials and workbooks',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '5',
        name: 'Arts',
        description: 'Art history and creative materials',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '6',
        name: 'Electronics',
        description: 'Gadgets, laptops, and tech accessories',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '7',
        name: 'Clothing',
        description: 'Apparel and fashion items',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '8',
        name: 'School Supplies',
        description: 'Stationery, notebooks, and supplies',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '9',
        name: 'Sports',
        description: 'Sports equipment and gear',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '10',
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
  }) async {
    final filters = ProductFilters(
      searchQuery: query,
      sortBy: ProductSortBy.newest,
    );

    return getProducts(filters: filters, limit: limit, offset: offset);
  }

  Future<List<Product>> getUserProducts(String userId) async {
    try {
      final response = await SupabaseService.from('products')
          .select('''
            *,
            categories(name)
          ''')
          .eq('seller_id', userId)
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

        // Remove nested objects for clean parsing
        productData.remove('categories');

        return Product.fromJson(productData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user products: $e');
    }
  }
}
