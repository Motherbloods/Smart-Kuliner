class CookingRecipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String difficulty;
  final int duration; // dalam menit
  final int servings; // jumlah porsi
  final double rating;
  final int reviewCount;
  final List<String> ingredients;
  final List<CookingStep> steps;

  // Additional fields for Firebase
  final String? userId;
  final String? createdAt;
  final String? updatedAt;
  final bool? isActive;
  final int? viewCount;
  final int? favoriteCount;

  CookingRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.servings,
    required this.rating,
    required this.reviewCount,
    required this.ingredients,
    required this.steps,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.viewCount,
    this.favoriteCount,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'difficulty': difficulty,
      'duration': duration,
      'servings': servings,
      'rating': rating,
      'reviewCount': reviewCount,
      'ingredients': ingredients,
      'steps': steps.map((step) => step.toMap()).toList(),
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive ?? true,
      'viewCount': viewCount ?? 0,
      'favoriteCount': favoriteCount ?? 0,
    };
  }

  // Create from Map for Firebase
  factory CookingRecipe.fromMap(Map<String, dynamic> map, String id) {
    return CookingRecipe(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      difficulty: map['difficulty'] ?? 'Mudah',
      duration: map['duration']?.toInt() ?? 30,
      servings: map['servings']?.toInt() ?? 2,
      rating: map['rating']?.toDouble() ?? 5.0,
      reviewCount: map['reviewCount']?.toInt() ?? 0,
      ingredients: List<String>.from(map['ingredients'] ?? []),
      steps:
          (map['steps'] as List<dynamic>?)
              ?.map((step) => CookingStep.fromMap(step as Map<String, dynamic>))
              .toList() ??
          [],
      userId: map['userId'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      isActive: map['isActive'] ?? true,
      viewCount: map['viewCount']?.toInt() ?? 0,
      favoriteCount: map['favoriteCount']?.toInt() ?? 0,
    );
  }

  // Copy with method for updates
  CookingRecipe copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    String? difficulty,
    int? duration,
    int? servings,
    double? rating,
    int? reviewCount,
    List<String>? ingredients,
    List<CookingStep>? steps,
    String? userId,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
    int? viewCount,
    int? favoriteCount,
  }) {
    return CookingRecipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      servings: servings ?? this.servings,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
    );
  }
}

class CookingStep {
  final int stepNumber;
  final String instruction;
  final String? imageUrl;

  CookingStep({
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
  });
  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {'stepNumber': stepNumber, 'instruction': instruction};
  }

  // Create from Map for Firebase
  factory CookingStep.fromMap(Map<String, dynamic> map) {
    return CookingStep(
      stepNumber: map['stepNumber']?.toInt() ?? 1,
      instruction: map['instruction'] ?? '',
    );
  }

  // Copy with method
  CookingStep copyWith({int? stepNumber, String? instruction}) {
    return CookingStep(
      stepNumber: stepNumber ?? this.stepNumber,
      instruction: instruction ?? this.instruction,
    );
  }
}
