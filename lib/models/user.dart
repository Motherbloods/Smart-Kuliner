class UserModel {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final bool seller;
  final String? namaToko; // Hanya untuk seller

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.seller,
    this.namaToko,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'seller': seller,
      'namaToko': namaToko,
    };
  }

  // Create from Map from Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      seller: map['seller'] ?? false,
      namaToko: map['namaToko'],
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    DateTime? createdAt,
    bool? seller,
    String? namaToko,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      seller: seller ?? this.seller,
      namaToko: namaToko ?? this.namaToko,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, seller: $seller, namaToko: $namaToko)';
  }
}
