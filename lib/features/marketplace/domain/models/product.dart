class Product {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String title;
  final String description;
  final double price;
  final ProductCondition condition;
  final bool isAvailable;
  final bool isFeatured;
  final String? location;
  final List<String> tags;
  final List<String> images;
  final int viewCount;
  final int favoriteCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final String? sellerName;
  final String? categoryName;
  final bool? isFavorited;

  const Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    this.isAvailable = true,
    this.isFeatured = false,
    this.location,
    this.tags = const [],
    this.images = const [],
    this.viewCount = 0,
    this.favoriteCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.sellerName,
    this.categoryName,
    this.isFavorited,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      condition: ProductCondition.values.firstWhere(
        (e) => e.name == json['condition'],
        orElse: () => ProductCondition.good,
      ),
      isAvailable: json['is_available'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      location: json['location'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      viewCount: json['view_count'] as int? ?? 0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sellerName: json['seller_name'] as String?,
      categoryName: json['category_name'] as String?,
      isFavorited: json['is_favorited'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition.name,
      'is_available': isAvailable,
      'is_featured': isFeatured,
      'location': location,
      'tags': tags,
      'images': images,
      'view_count': viewCount,
      'favorite_count': favoriteCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? categoryId,
    String? title,
    String? description,
    double? price,
    ProductCondition? condition,
    bool? isAvailable,
    bool? isFeatured,
    String? location,
    List<String>? tags,
    List<String>? images,
    int? viewCount,
    int? favoriteCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sellerName,
    String? categoryName,
    bool? isFavorited,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerName: sellerName ?? this.sellerName,
      categoryName: categoryName ?? this.categoryName,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  String get primaryImage => images.isNotEmpty ? images.first : '';

  String get formattedPrice => '₱${price.toStringAsFixed(2)}';

  String get conditionDisplay {
    switch (condition) {
      case ProductCondition.new_:
        return 'New';
      case ProductCondition.likeNew:
        return 'Like New';
      case ProductCondition.good:
        return 'Good';
      case ProductCondition.fair:
        return 'Fair';
      case ProductCondition.poor:
        return 'Poor';
    }
  }
}

enum ProductCondition {
  new_('new'),
  likeNew('like_new'),
  good('good'),
  fair('fair'),
  poor('poor');

  const ProductCondition(this.value);
  final String value;
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final bool isActive;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.isActive = true,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProductFilters {
  final String? categoryId;
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final ProductCondition? condition;
  final String? location;
  final ProductSortBy sortBy;
  final bool? isAvailable;

  const ProductFilters({
    this.categoryId,
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.location,
    this.sortBy = ProductSortBy.newest,
    this.isAvailable = true,
  });

  ProductFilters copyWith({
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    ProductCondition? condition,
    String? location,
    ProductSortBy? sortBy,
    bool? isAvailable,
  }) {
    return ProductFilters(
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      sortBy: sortBy ?? this.sortBy,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  bool get hasActiveFilters {
    return categoryId != null ||
        searchQuery?.isNotEmpty == true ||
        minPrice != null ||
        maxPrice != null ||
        condition != null ||
        location?.isNotEmpty == true;
  }
}

enum ProductSortBy {
  newest,
  oldest,
  priceLowToHigh,
  priceHighToLow,
  mostViewed,
  mostFavorited,
}
