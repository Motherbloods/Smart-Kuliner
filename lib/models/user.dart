class UserModel {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final bool seller;
  final String? namaToko;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profileImageUrl;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final List<String> favoriteCategories;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.seller,
    this.namaToko,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.profileImageUrl,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    this.favoriteCategories = const [],
    this.emailVerified = false,
    this.phoneVerified = false,
    this.lastLoginAt,
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
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'city': city,
      'province': province,
      'postalCode': postalCode,
      'favoriteCategories': favoriteCategories,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
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
      phoneNumber: map['phoneNumber'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      gender: map['gender'],
      profileImageUrl: map['profileImageUrl'],
      address: map['address'],
      city: map['city'],
      province: map['province'],
      postalCode: map['postalCode'],
      favoriteCategories: List<String>.from(map['favoriteCategories'] ?? []),
      emailVerified: map['emailVerified'] ?? false,
      phoneVerified: map['phoneVerified'] ?? false,
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
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
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    List<String>? favoriteCategories,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      seller: seller ?? this.seller,
      namaToko: namaToko ?? this.namaToko,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Helper methods
  String get fullAddress {
    List<String> addressParts = [];
    if (address != null && address!.isNotEmpty) addressParts.add(address!);
    if (city != null && city!.isNotEmpty) addressParts.add(city!);
    if (province != null && province!.isNotEmpty) addressParts.add(province!);
    if (postalCode != null && postalCode!.isNotEmpty)
      addressParts.add(postalCode!);
    return addressParts.join(', ');
  }

  bool get hasCompleteProfile {
    return phoneNumber != null &&
        address != null &&
        city != null &&
        province != null;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, seller: $seller, namaToko: $namaToko, phoneNumber: $phoneNumber)';
  }
}
