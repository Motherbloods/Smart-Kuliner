// screens/cooking_list_screen.dart
import 'package:flutter/material.dart';
import 'package:smart/data/dummy_how_to_cook.dart';
import 'package:smart/widgets/cooking/cooking_recipe_horizontal_card.dart';

import 'cooking_detail_screen.dart';

class CookingListScreen extends StatefulWidget {
  const CookingListScreen({Key? key}) : super(key: key);

  @override
  State<CookingListScreen> createState() => _CookingListScreenState();
}

class _CookingListScreenState extends State<CookingListScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<CookingRecipe> get _filteredRecipes {
    List<CookingRecipe> filtered = dummyCookingRecipes;

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

          // // Category Filter
          // Container(
          //   height: 50,
          //   margin: const EdgeInsets.symmetric(vertical: 16),
          //   child: ListView.builder(
          //     scrollDirection: Axis.horizontal,
          //     padding: const EdgeInsets.symmetric(horizontal: 16),
          //     itemCount: cookingCategories.length,
          //     itemBuilder: (context, index) {
          //       final category = cookingCategories[index];
          //       final isSelected = category == _selectedCategory;

          //       return Container(
          //         margin: const EdgeInsets.only(right: 8),
          //         child: FilterChip(
          //           label: Text(category),
          //           selected: isSelected,
          //           onSelected: (selected) {
          //             setState(() {
          //               _selectedCategory = category;
          //             });
          //           },
          //           backgroundColor: Colors.grey[100],
          //           selectedColor: const Color(0xFF4DA8DA),
          //           labelStyle: TextStyle(
          //             color: isSelected ? Colors.white : Colors.grey[700],
          //             fontWeight: isSelected
          //                 ? FontWeight.w600
          //                 : FontWeight.normal,
          //           ),
          //           showCheckmark: false,
          //         ),
          //       );
          //     },
          //   ),
          // ),

          // // Results Count
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   child: Row(
          //     children: [
          //       Text(
          //         'Ditemukan ${_filteredRecipes.length} resep',
          //         style: const TextStyle(
          //           fontSize: 14,
          //           color: Colors.grey,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // const SizedBox(height: 8),

          // Recipe List
          Expanded(
            child: _filteredRecipes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _filteredRecipes[index];
                      return CookingRecipeHorizontalCard(
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
        ],
      ),
    );
  }
}
