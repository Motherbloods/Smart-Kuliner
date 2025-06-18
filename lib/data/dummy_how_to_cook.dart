// data/dummy_cooking_recipes.dart
class CookingRecipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String difficulty;
  final int duration; // dalam menit
  final int servings;
  final List<String> ingredients;
  final List<CookingStep> steps;
  final String category;
  final double rating;
  final int reviewCount;

  CookingRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.difficulty,
    required this.duration,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.category,
    required this.rating,
    required this.reviewCount,
  });
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
}

// Dummy data untuk resep masakan
final List<CookingRecipe> dummyCookingRecipes = [
  CookingRecipe(
    id: '1',
    title: 'Nasi Goreng Spesial',
    description: 'Nasi goreng dengan telur, ayam, dan sayuran segar yang lezat',
    imageUrl:
        'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400',
    difficulty: 'Mudah',
    duration: 20,
    servings: 2,
    category: 'Nasi',
    rating: 4.5,
    reviewCount: 125,
    ingredients: [
      '2 piring nasi putih',
      '2 butir telur',
      '100g daging ayam, potong dadu',
      '2 siung bawang putih, cincang',
      '1 buah bawang bombay, iris',
      '2 sdm kecap manis',
      '1 sdm kecap asin',
      'Garam dan merica secukupnya',
      'Minyak untuk menumis',
      'Daun bawang untuk taburan',
    ],
    steps: [
      CookingStep(
        stepNumber: 1,
        instruction:
            'Panaskan minyak dalam wajan, tumis bawang putih dan bawang bombay hingga harum',
      ),
      CookingStep(
        stepNumber: 2,
        instruction: 'Masukkan daging ayam, masak hingga berubah warna',
      ),
      CookingStep(
        stepNumber: 3,
        instruction: 'Kocok telur, tuang ke dalam wajan dan aduk-aduk',
      ),
      CookingStep(
        stepNumber: 4,
        instruction: 'Masukkan nasi, aduk rata dengan bumbu',
      ),
      CookingStep(
        stepNumber: 5,
        instruction: 'Tambahkan kecap manis, kecap asin, garam, dan merica',
      ),
      CookingStep(
        stepNumber: 6,
        instruction: 'Aduk hingga semua bumbu tercampur rata, masak 2-3 menit',
      ),
      CookingStep(
        stepNumber: 7,
        instruction: 'Angkat dan sajikan dengan taburan daun bawang',
      ),
    ],
  ),
  CookingRecipe(
    id: '2',
    title: 'Soto Ayam Kuning',
    description: 'Soto ayam dengan kuah kuning yang hangat dan menyegarkan',
    imageUrl:
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
    difficulty: 'Sedang',
    duration: 45,
    servings: 4,
    category: 'Sup',
    rating: 4.8,
    reviewCount: 89,
    ingredients: [
      '500g ayam, potong-potong',
      '2 liter air',
      '3 siung bawang putih',
      '5 siung bawang merah',
      '2 cm jahe',
      '2 cm kunyit',
      '1 batang serai',
      '2 lembar daun salam',
      'Garam secukupnya',
      'Bihun, rebus',
      'Telur rebus',
      'Tauge',
      'Daun seledri',
    ],
    steps: [
      CookingStep(
        stepNumber: 1,
        instruction:
            'Rebus ayam dengan air hingga empuk, angkat dan suwir-suwir',
      ),
      CookingStep(
        stepNumber: 2,
        instruction: 'Haluskan bawang merah, bawang putih, jahe, dan kunyit',
      ),
      CookingStep(stepNumber: 3, instruction: 'Tumis bumbu halus hingga harum'),
      CookingStep(
        stepNumber: 4,
        instruction: 'Masukkan bumbu tumis ke dalam kaldu ayam',
      ),
      CookingStep(
        stepNumber: 5,
        instruction: 'Tambahkan serai, daun salam, masak 15 menit',
      ),
      CookingStep(
        stepNumber: 6,
        instruction: 'Bumbui dengan garam, koreksi rasa',
      ),
      CookingStep(
        stepNumber: 7,
        instruction: 'Sajikan dengan bihun, ayam suwir, telur, dan tauge',
      ),
    ],
  ),

  CookingRecipe(
    id: '3',
    title: 'Gado-Gado Jakarta',
    description: 'Salad sayuran tradisional dengan bumbu kacang yang lezat',
    imageUrl:
        'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400',
    difficulty: 'Mudah',
    duration: 30,
    servings: 3,
    category: 'Sayuran',
    rating: 4.3,
    reviewCount: 67,
    ingredients: [
      '100g tahu, goreng',
      '2 butir telur rebus',
      '100g tauge',
      '100g kangkung',
      '100g kol',
      '1 buah mentimun',
      '200g kacang tanah, goreng',
      '3 buah cabai rawit',
      '2 siung bawang putih',
      '2 sdm gula merah',
      '1 sdm asam jawa',
      'Garam secukupnya',
    ],
    steps: [
      CookingStep(
        stepNumber: 1,
        instruction: 'Rebus sayuran (kangkung, kol, tauge) hingga matang',
      ),
      CookingStep(
        stepNumber: 2,
        instruction: 'Haluskan kacang goreng dengan cabai, bawang putih',
      ),
      CookingStep(
        stepNumber: 3,
        instruction: 'Tambahkan gula merah, asam jawa, dan garam',
      ),
      CookingStep(
        stepNumber: 4,
        instruction: 'Beri sedikit air hangat untuk mencairkan bumbu',
      ),
      CookingStep(
        stepNumber: 5,
        instruction: 'Tata sayuran, tahu, dan telur di piring',
      ),
      CookingStep(stepNumber: 6, instruction: 'Siram dengan bumbu kacang'),
      CookingStep(stepNumber: 7, instruction: 'Sajikan dengan kerupuk'),
    ],
  ),
  CookingRecipe(
    id: '4',
    title: 'Ayam Bakar Madu',
    description: 'Ayam bakar dengan marinasi madu yang manis dan gurih',
    imageUrl:
        'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=400',
    difficulty: 'Sedang',
    duration: 60,
    servings: 4,
    category: 'Ayam',
    rating: 4.6,
    reviewCount: 156,
    ingredients: [
      '1 ekor ayam, potong 8 bagian',
      '3 sdm madu',
      '2 sdm kecap manis',
      '1 sdm kecap asin',
      '3 siung bawang putih, haluskan',
      '2 cm jahe, haluskan',
      '1 sdt ketumbar bubuk',
      'Garam dan merica secukupnya',
      '2 sdm minyak sayur',
    ],
    steps: [
      CookingStep(
        stepNumber: 1,
        instruction: 'Campurkan semua bumbu marinasi dalam wadah',
      ),
      CookingStep(
        stepNumber: 2,
        instruction: 'Lumuri ayam dengan bumbu, diamkan 2 jam',
      ),
      CookingStep(
        stepNumber: 3,
        instruction: 'Panaskan grill atau teflon anti lengket',
      ),
      CookingStep(
        stepNumber: 4,
        instruction: 'Bakar ayam hingga matang dan berwarna kecoklatan',
      ),
      CookingStep(
        stepNumber: 5,
        instruction: 'Balik ayam sesekali agar matang merata',
      ),
      CookingStep(
        stepNumber: 6,
        instruction: 'Oles kembali dengan sisa bumbu saat membakar',
      ),
      CookingStep(
        stepNumber: 7,
        instruction: 'Sajikan hangat dengan nasi dan lalapan',
      ),
    ],
  ),
];

// Categories untuk filter
final List<String> cookingCategories = [
  'Semua',
  'Nasi',
  'Sup',
  'Daging',
  'Ayam',
  'Sayuran',
  'Seafood',
  'Dessert',
];
