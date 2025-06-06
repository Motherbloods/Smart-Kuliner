class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> imageUrls;
  final double rating;
  final String sellerId;
  final String nameToko;
  final int sold;
  final int stock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.nameToko,
    this.rating = 0,
    required this.sellerId,
    this.sold = 0,
    required this.stock,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert ProductModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'nameToko': nameToko,
      'price': price,
      'category': category,
      'rating': rating,
      'sold': sold,
      'imageUrls': imageUrls,
      'stock': stock,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create ProductModel from Firestore Map
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      name: map['name'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      sold: (map['sold'] ?? 0).toInt(),
      nameToko: map['nameToko'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      stock: map['stock'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Copy with method for updating
  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    String? nameToko,
    double? price,
    String? category,
    double? rating,
    int? sold,
    List<String>? imageUrls,
    int? stock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      nameToko: nameToko ?? this.nameToko,
      price: price ?? this.price,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      sold: sold ?? this.sold,
      imageUrls: imageUrls ?? this.imageUrls,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Format price to currency
  String get formattedPrice {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
