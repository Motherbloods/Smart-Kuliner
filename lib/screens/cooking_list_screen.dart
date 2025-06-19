// screens/cooking_list_screen.dart
import 'package:flutter/material.dart';
import 'package:smart/data/dummy_how_to_cook.dart';
import 'package:smart/models/recipe.dart';
import 'package:smart/services/recipe_service.dart'; // Import service Firebase Anda
import 'package:smart/widgets/cooking/cooking_recipe_card.dart';

import 'cooking_detail_screen.dart';
import 'add_recipe_screen.dart';

class CookingListScreen extends StatefulWidget {
  final bool isSeller;

  const CookingListScreen({Key? key, required this.isSeller}) : super(key: key);

  @override
  State<CookingListScreen> createState() => _CookingListScreenState();
}

class _CookingListScreenState extends State<CookingListScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final RecipeService _recipeService =
      RecipeService(); // Instance service Firebase

  // Kombinasi data dummy + Firebase
  List<CookingRecipe> _allRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRecipes();
  }

  void _loadAllRecipes() {
    setState(() {
      _isLoading = true;
    });

    // Listen ke stream Firebase dan gabungkan dengan data dummy
    _recipeService.getAllActiveRecipes().listen(
      (firebaseRecipes) {
        setState(() {
          // Gabungkan data dummy dengan data Firebase
          _allRecipes = [
            ...dummyCookingRecipes, // Data dummy terlebih dahulu
            ...firebaseRecipes, // Kemudian data Firebase
          ];
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() {
          // Jika error Firebase, gunakan data dummy saja
          _allRecipes = dummyCookingRecipes;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading online recipes: $error'),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );
  }

  List<CookingRecipe> get _filteredRecipes {
    List<CookingRecipe> filtered = _allRecipes;

    // Filter by category
    if (_selectedCategory != 'Semua') {
      filtered = filtered
          .where((recipe) => recipe.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (recipe) =>
                recipe.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                recipe.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  void _navigateToAddRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );

    if (result != null && result is CookingRecipe) {
      // Jika recipe berhasil ditambahkan ke Firebase,
      // data akan otomatis ter-update melalui stream
      // Tidak perlu manual setState lagi

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resep berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4DA8DA),
        title: const Text(
          'Cara Memasak',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isSeller)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 28),
              onPressed: _navigateToAddRecipe,
              tooltip: 'Tambah Resep',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4DA8DA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari resep masakan...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Recipe List
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredRecipes.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      // Optional: Show data source info
                      if (_allRecipes.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            '${_allRecipes.length} resep tersedia (${dummyCookingRecipes.length} lokal + ${_allRecipes.length - dummyCookingRecipes.length} online)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _filteredRecipes[index];
                            return CookingRecipeCard(
                              recipe: recipe,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CookingDetailScreen(recipe: recipe),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DA8DA)),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat resep...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada resep ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kategori atau kata kunci pencarian',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToAddRecipe,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Resep Pertama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DA8DA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
