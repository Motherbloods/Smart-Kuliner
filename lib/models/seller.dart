class SellerModel {
  final String id;
  final String nameToko;
  final String description;
  final String profileImage;
  final String location;
  final double rating;
  final int totalProducts;
  final bool isVerified;
  final DateTime joinedDate;
  final String
  category; // Kategori utama seller (misal: Makanan Utama, Cemilan, dll)
  final List<String> tags; // Tag untuk pencarian yang lebih baik

  SellerModel({
    required this.id,
    required this.nameToko,
    required this.description,
    required this.profileImage,
    required this.location,
    required this.rating,
    required this.totalProducts,
    required this.isVerified,
    required this.joinedDate,
    required this.category,
    required this.tags,
  });

  factory SellerModel.fromMap(Map<String, dynamic> map, String uid) {
    return SellerModel(
      id: map['id'] ?? '',
      nameToko: map['nameToko'] ?? '',
      description: map['description'] ?? '',
      profileImage: map['profileImage'] ?? '',
      location: map['location'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalProducts: map['totalProducts'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      joinedDate: DateTime.fromMillisecondsSinceEpoch(
        map['joinedDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      category: map['category'] ?? 'Lainnya',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameToko': nameToko,
      'description': description,
      'profileImage': profileImage,
      'location': location,
      'rating': rating,
      'totalProducts': totalProducts,
      'isVerified': isVerified,
      'joinedDate': joinedDate.millisecondsSinceEpoch,
      'category': category,
      'tags': tags,
    };
  }

  SellerModel copyWith({
    String? id,
    String? nameToko,
    String? description,
    String? profileImage,
    String? location,
    double? rating,
    int? totalProducts,
    bool? isVerified,
    DateTime? joinedDate,
    String? category,
    List<String>? tags,
  }) {
    return SellerModel(
      id: id ?? this.id,
      nameToko: nameToko ?? this.nameToko,
      description: description ?? this.description,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      totalProducts: totalProducts ?? this.totalProducts,
      isVerified: isVerified ?? this.isVerified,
      joinedDate: joinedDate ?? this.joinedDate,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }
}
