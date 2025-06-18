import 'package:cloud_firestore/cloud_firestore.dart';

class KontenModel {
  String? id;
  String title;
  String description;
  String category;
  String imageUrl;
  String sellerId;
  String namaToko;
  String sellerAvatar;
  String status; // 'Draft', 'Published', 'Archived'
  int views;
  int likes;
  DateTime createdAt;

  KontenModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.sellerId,
    required this.namaToko,
    this.sellerAvatar = '',
    this.status = 'Draft',
    this.views = 0,
    this.likes = 0,
    required this.createdAt,
  });

  // Factory constructor untuk membuat instance dari JSON/Map
  factory KontenModel.fromJson(Map<String, dynamic> json) {
    return KontenModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Lainnya',
      imageUrl: json['imageUrl'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? '',
      namaToko: json['namaToko'] as String? ?? '',
      sellerAvatar: json['sellerAvatar'] as String? ?? '',
      status: json['status'] as String? ?? 'Draft',
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  // Method untuk convert ke JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'namaToko': namaToko,
      'sellerAvatar': sellerAvatar,
      'status': status,
      'views': views,
      'likes': likes,
      'createdAt': createdAt,
    };
  }

  // Method untuk convert ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'namaToko': namaToko,
      'sellerAvatar': sellerAvatar,
      'status': status,
      'views': views,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Helper method untuk parsing timestamp dari Firestore
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  // Copy with method untuk membuat salinan dengan perubahan
  KontenModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    String? sellerId,
    String? namaToko,
    String? sellerAvatar,
    int? readTime,
    String? status,
    int? views,
    int? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KontenModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerId: sellerId ?? this.sellerId,
      namaToko: namaToko ?? this.namaToko,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      status: status ?? this.status,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Factory constructor untuk membuat konten baru
  factory KontenModel.create({
    required String title,
    required String description,
    required String category,
    required String imageUrl,
    required String sellerId,
    required String namaToko,
    String sellerAvatar = '',
    required int readTime,
    String status = 'Draft',
  }) {
    final now = DateTime.now();
    return KontenModel(
      title: title,
      description: description,
      category: category,
      imageUrl: imageUrl,
      sellerId: sellerId,
      namaToko: namaToko,
      sellerAvatar: sellerAvatar,
      status: status,
      views: 0,
      likes: 0,
      createdAt: now,
    );
  }

  // Method untuk validasi
  bool get isValid {
    return title.isNotEmpty &&
        description.isNotEmpty &&
        category.isNotEmpty &&
        imageUrl.isNotEmpty &&
        sellerId.isNotEmpty;
  }

  // Method untuk cek apakah konten sudah published
  bool get isPublished => status == 'Published';

  // Method untuk cek apakah konten masih draft
  bool get isDraft => status == 'Draft';

  // Method untuk cek apakah konten sudah diarsipkan
  bool get isArchived => status == 'Archived';

  // Method untuk mendapatkan preview description (maksimal 150 karakter)
  String get previewDescription {
    if (description.length <= 150) {
      return description;
    }
    return '${description.substring(0, 150)}...';
  }

  // Method untuk mendapatkan word count
  int get wordCount {
    return description.split(' ').where((word) => word.isNotEmpty).length;
  }

  // Method untuk format tanggal
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Method untuk format views count
  String get formattedViews {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    } else {
      return views.toString();
    }
  }

  // Method untuk format likes count
  String get formattedLikes {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    } else {
      return likes.toString();
    }
  }

  // Override toString untuk debugging
  @override
  String toString() {
    return 'KontenModel(id: $id, title: $title, category: $category, '
        'sellerId: $sellerId, status: $status, views: $views, likes: $likes)';
  }

  // Override equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KontenModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum untuk status konten
enum KontenStatus {
  draft('Draft'),
  published('Published'),
  archived('Archived');

  const KontenStatus(this.value);
  final String value;

  static KontenStatus fromString(String status) {
    return KontenStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => KontenStatus.draft,
    );
  }
}

// Enum untuk kategori konten (sesuai dengan KontenService)
enum KontenCategory {
  semua('Semua'),
  makananUtama('Makanan Utama'),
  cemilan('Cemilan'),
  minuman('Minuman'),
  makananSehat('Makanan Sehat'),
  dessert('Dessert'),
  lainnya('Lainnya');

  const KontenCategory(this.value);
  final String value;

  static KontenCategory fromString(String category) {
    return KontenCategory.values.firstWhere(
      (e) => e.value == category,
      orElse: () => KontenCategory.lainnya,
    );
  }

  static List<String> getAllCategories() {
    return KontenCategory.values.map((e) => e.value).toList();
  }
}
