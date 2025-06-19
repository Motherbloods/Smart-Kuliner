// services/recipe_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart/models/recipe.dart';
import 'cloudinary_service.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Get all active recipes (untuk halaman beranda)
  Stream<List<CookingRecipe>> getAllActiveRecipes() {
    return _firestore
        .collection('recipes')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CookingRecipe.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get latest recipes
  Stream<List<CookingRecipe>> getLatestRecipes({int limit = 10}) {
    return _firestore
        .collection('recipes')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CookingRecipe.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get recipes by user ID (untuk profile user)
  Stream<List<CookingRecipe>> getUserRecipes(String userId) {
    return _firestore
        .collection('recipes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CookingRecipe.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get recipes by category
  Stream<List<CookingRecipe>> getRecipesByCategory(String category) {
    return _firestore
        .collection('recipes')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CookingRecipe.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get single recipe by ID
  Future<CookingRecipe?> getRecipe(String recipeId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('recipes')
          .doc(recipeId)
          .get();

      if (doc.exists) {
        return CookingRecipe.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting recipe: $e');
      return null;
    }
  }

  // Add new recipe
  Future<String?> addRecipe(CookingRecipe recipe, {String? userId}) async {
    try {
      // Prepare recipe data with additional Firebase fields
      Map<String, dynamic> recipeData = recipe.toMap();
      recipeData.addAll({
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'userId': userId ?? 'anonymous', // ID user yang membuat recipe
        'viewCount': 0,
        'favoriteCount': 0,
      });

      DocumentReference docRef = await _firestore
          .collection('recipes')
          .add(recipeData);

      print('✅ Recipe added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding recipe: $e');
      throw 'Gagal menambahkan resep: $e';
    }
  }

  // Update recipe
  Future<void> updateRecipe(String recipeId, CookingRecipe recipe) async {
    try {
      Map<String, dynamic> recipeData = recipe.toMap();
      recipeData['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection('recipes').doc(recipeId).update(recipeData);

      print('✅ Recipe updated successfully');
    } catch (e) {
      print('❌ Error updating recipe: $e');
      throw 'Gagal memperbarui resep: $e';
    }
  }

  // Delete recipe
  Future<void> deleteRecipe(String recipeId) async {
    try {
      // Get recipe data first to delete image
      DocumentSnapshot doc = await _firestore
          .collection('recipes')
          .doc(recipeId)
          .get();

      if (doc.exists) {
        CookingRecipe recipe = CookingRecipe.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Delete image from Cloudinary if it's from Cloudinary
        if (recipe.imageUrl.contains('cloudinary.com')) {
          await _cloudinaryService.deleteImage(recipe.imageUrl);
        }
      }

      // Delete recipe document
      await _firestore.collection('recipes').doc(recipeId).delete();

      print('✅ Recipe deleted successfully');
    } catch (e) {
      print('❌ Error deleting recipe: $e');
      throw 'Gagal menghapus resep: $e';
    }
  }

  // Upload recipe image to Cloudinary
  Future<String> uploadRecipeImage(XFile imageFile, {String? userId}) async {
    try {
      // Create folder path for better organization
      String folderPath = 'recipes/${userId ?? 'anonymous'}';

      // Upload to Cloudinary
      String imageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folderPath,
      );

      print('✅ Recipe image uploaded successfully to Cloudinary');
      return imageUrl;
    } catch (e) {
      print('❌ Error uploading recipe image: $e');
      throw 'Gagal mengupload gambar resep: $e';
    }
  }

  // Search recipes
  Future<List<CookingRecipe>> searchRecipes(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('isActive', isEqualTo: true)
          .get();

      List<CookingRecipe> recipes = snapshot.docs.map((doc) {
        return CookingRecipe.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Filter by title, description, or ingredients
      return recipes
          .where(
            (recipe) =>
                recipe.title.toLowerCase().contains(query.toLowerCase()) ||
                recipe.description.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                recipe.ingredients.any(
                  (ingredient) =>
                      ingredient.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
    } catch (e) {
      print('❌ Error searching recipes: $e');
      return [];
    }
  }

  // Get recipe categories
  List<String> getRecipeCategories() {
    return [
      'Makanan Utama',
      'Makanan Pembuka',
      'Cemilan',
      'Minuman',
      'Dessert',
      'Makanan Sehat',
      'Makanan Tradisional',
      'Lainnya',
    ];
  }

  // Get recipe difficulties
  List<String> getRecipeDifficulties() {
    return ['Mudah', 'Sedang', 'Sulit'];
  }

  // Toggle recipe active status
  Future<void> toggleRecipeStatus(String recipeId, bool isActive) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Recipe status updated successfully');
    } catch (e) {
      print('❌ Error updating recipe status: $e');
      throw 'Gagal memperbarui status resep: $e';
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String recipeId) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).update({
        'viewCount': FieldValue.increment(1),
      });

      print('✅ Recipe view count updated successfully');
    } catch (e) {
      print('❌ Error updating view count: $e');
      // Don't throw error for view count as it's not critical
    }
  }
}
