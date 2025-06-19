// screens/add_recipe_screen.dart - Complete version
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart/models/recipe.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'package:smart/services/cloudinary_service.dart';
import 'package:smart/services/recipe_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart/widgets/cooking/basic_info_form_card.dart';
import 'package:smart/widgets/cooking/image_section.dart';
import 'package:smart/widgets/cooking/recipe_steps_ingredients_card.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({Key? key}) : super(key: key);

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Services
  final RecipeService _recipeService = RecipeService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _servingsController = TextEditingController();

  String _selectedDifficulty = 'Mudah';
  final List<String> _difficulties = ['Mudah', 'Sedang', 'Sulit'];
  String _selectedCategory = 'Makanan Utama';

  final List<String> _ingredients = [];
  final List<CookingStep> _steps = [];
  final _ingredientController = TextEditingController();
  final _stepController = TextEditingController();

  // Image handling
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isUploadingImage = false;
  bool _isSavingRecipe = false;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _ingredientController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  // Image selection and upload methods
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Validate image file
        if (!_cloudinaryService.isValidImageFile(image)) {
          SnackbarHelper.showErrorSnackbar(
            context,
            'Format gambar tidak didukung. Gunakan JPG, PNG, atau WEBP.',
          );
          return;
        }

        // Validate image size
        if (!await _cloudinaryService.isValidImageSize(image, maxSizeMB: 5.0)) {
          SnackbarHelper.showErrorSnackbar(
            context,
            'Ukuran gambar terlalu besar. Maksimal 5MB.',
          );
          return;
        }

        setState(() {
          _selectedImage = image;
        });

        // Upload to Cloudinary
        await _uploadImageToCloudinary();
      }
    } catch (e) {
      print('Error picking image: $e');
      SnackbarHelper.showErrorSnackbar(context, 'Gagal memilih gambar: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Validate image file
        if (!_cloudinaryService.isValidImageFile(image)) {
          SnackbarHelper.showErrorSnackbar(
            context,
            'Format gambar tidak didukung. Gunakan JPG, PNG, atau WEBP.',
          );
          return;
        }

        // Validate image size
        if (!await _cloudinaryService.isValidImageSize(image, maxSizeMB: 5.0)) {
          SnackbarHelper.showErrorSnackbar(
            context,
            'Ukuran gambar terlalu besar. Maksimal 5MB.',
          );
          return;
        }

        setState(() {
          _selectedImage = image;
        });

        // Upload to Cloudinary
        await _uploadImageToCloudinary();
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      SnackbarHelper.showErrorSnackbar(context, 'Gagal mengambil foto: $e');
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Get current user ID
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      // Upload image using RecipeService
      String imageUrl = await _recipeService.uploadRecipeImage(
        _selectedImage!,
        userId: userId,
      );

      setState(() {
        _uploadedImageUrl = imageUrl;
        _imageUrlController.text = imageUrl;
        _isUploadingImage = false;
      });

      SnackbarHelper.showSuccessSnackbar(context, 'Gambar berhasil diupload!');
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      print('Error uploading image: $e');
      SnackbarHelper.showErrorSnackbar(context, 'Gagal mengupload gambar: $e');
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _imageUrlController.clear();
    });
  }

  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text.trim());
        _ingredientController.clear();
      });
    }
  }

  void _addStep() {
    if (_stepController.text.trim().isNotEmpty) {
      setState(() {
        _steps.add(
          CookingStep(
            stepNumber: _steps.length + 1,
            instruction: _stepController.text.trim(),
          ),
        );
        _stepController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      // Update step numbers
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = CookingStep(
          stepNumber: i + 1,
          instruction: _steps[i].instruction,
        );
      }
    });
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              if (_selectedImage != null || _uploadedImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Hapus Gambar',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeSelectedImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      if (_ingredients.isEmpty) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Harap tambahkan minimal satu bahan!',
        );
        return;
      }

      if (_steps.isEmpty) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Harap tambahkan minimal satu langkah memasak!',
        );
        return;
      }

      setState(() {
        _isSavingRecipe = true;
      });

      try {
        // Get current user ID
        String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

        // Create new recipe object
        final newRecipe = CookingRecipe(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl:
              _uploadedImageUrl ??
              (_imageUrlController.text.trim().isNotEmpty
                  ? _imageUrlController.text.trim()
                  : 'https://via.placeholder.com/300x200?text=Recipe+Image'),
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
          duration: int.tryParse(_durationController.text) ?? 30,
          servings: int.tryParse(_servingsController.text) ?? 2,
          rating: 5.0,
          reviewCount: 0, // Start with 0 reviews
          ingredients: List.from(_ingredients),
          steps: List.from(_steps),
          userId: userId,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          isActive: true,
          viewCount: 0,
          favoriteCount: 0,
        );

        // Save to Firebase
        String? recipeId = await _recipeService.addRecipe(
          newRecipe,
          userId: userId,
        );

        if (recipeId != null) {
          // Update recipe with the actual Firebase ID
          final updatedRecipe = newRecipe.copyWith(id: recipeId);

          SnackbarHelper.showSuccessSnackbar(
            context,
            'Resep berhasil disimpan!',
          );

          // Return the updated recipe to previous screen
          Navigator.pop(context, updatedRecipe);
        } else {
          throw 'Gagal mendapatkan ID resep';
        }
      } catch (e) {
        print('Error saving recipe: $e');
        SnackbarHelper.showErrorSnackbar(context, 'Gagal menyimpan resep: $e');
      } finally {
        setState(() {
          _isSavingRecipe = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF4DA8DA),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: _isSavingRecipe
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                onPressed: _isSavingRecipe ? null : _saveRecipe,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Tambah Resep',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4DA8DA), Color(0xFF40A0D0)],
                  ),
                ),
              ),
            ),
          ),

          // Form Content
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    RecipeImageCard(
                      isUploadingImage: _isUploadingImage,
                      uploadedImageUrl: _uploadedImageUrl,
                      showImagePicker: _showImagePickerBottomSheet,
                    ),

                    const SizedBox(height: 16),

                    // Basic Info Section
                    BasicInfoFormCard(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      durationController: _durationController,
                      servingsController: _servingsController,
                      selectedCategory: _selectedCategory,
                      selectedDifficulty: _selectedDifficulty,
                      categories: _recipeService.getRecipeCategories(),
                      difficulties: _difficulties,
                      onCategoryChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      onDifficultyChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Ingredients and Steps Tabs
                    RecipeStepsAndIngredientsCard(
                      tabController: _tabController,
                      ingredientController: _ingredientController,
                      stepController: _stepController,
                      ingredients: _ingredients,
                      steps: _steps,
                      onAddIngredient: _addIngredient,
                      onRemoveIngredient: _removeIngredient,
                      onAddStep: _addStep,
                      onRemoveStep: _removeStep,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSavingRecipe ? null : _saveRecipe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DA8DA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSavingRecipe
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Menyimpan...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Simpan Resep',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
