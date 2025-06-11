class EdukasiModel {
  final String uid;
  final String? id;
  final String sellerId;
  final String title;
  final String description;
  final String videoUrl;
  final String imageUrl;
  final String category;
  final int readTime; // in minutes
  final DateTime createdAt;
  final String status; // 'Published', 'Draft', 'Archived'
  final String namaToko;
  int? views;
  int? likes;
  final List<String>? tags;

  EdukasiModel({
    required this.uid,
    this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.imageUrl,
    required this.category,
    required this.readTime,
    required this.createdAt,
    required this.status,
    required this.namaToko,
    this.views = 0,
    this.likes = 0,
    this.tags,
  });

  // Convert from JSON
  factory EdukasiModel.fromJson(Map<String, dynamic> json) {
    return EdukasiModel(
      uid: json['uid'] ?? '',
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      readTime: json['readTime'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      status: json['status'] ?? 'Draft',
      namaToko: json['namaToko'] ?? '',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'category': category,
      'readTime': readTime,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'namaToko': namaToko,
      'views': views,
      'likes': likes,
      'tags': tags,
    };
  }

  // Copy with method for updates
  EdukasiModel copyWith({
    String? id,
    String? uid,
    String? sellerId,
    String? title,
    String? description,
    String? videoUrl,
    String? imageUrl,
    String? category,
    int? readTime,
    DateTime? createdAt,
    String? status,
    String? namaToko,
    int? views,
    int? likes,
    List<String>? tags,
  }) {
    return EdukasiModel(
      uid: uid ?? this.uid,
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      readTime: readTime ?? this.readTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      namaToko: namaToko ?? this.namaToko,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'EdukasiModel{'
        'uid: $uid, '
        'title: $title, '
        'category: $category, '
        'status: $status, '
        'readTime: $readTime'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdukasiModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
