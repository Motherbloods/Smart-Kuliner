import 'package:flutter/material.dart';
import 'package:smart/models/konten.dart';
import 'package:smart/models/product.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/recipe.dart';
import 'package:smart/models/seller.dart';
import 'package:smart/screens/all_education_screen.dart';
import 'package:smart/screens/all_sellers_screen.dart';
import 'package:smart/screens/all_konten_screen.dart';
import 'package:smart/screens/cooking_detail_screen.dart';
import 'package:smart/screens/cooking_list_screen.dart';
import 'package:smart/widgets/cooking/cooking_recipe_card.dart';
import 'package:smart/widgets/konten_card.dart';
import 'package:smart/widgets/search_result_type.dart';
import 'package:smart/widgets/product_card.dart';
import 'package:smart/widgets/edukasi_card.dart';
import 'package:smart/widgets/seller_card.dart';
import 'package:smart/managers/content_interaction_manager.dart';
import 'package:smart/managers/user_manager.dart';

class SearchResultsGrid extends StatefulWidget {
  final List<ProductModel> products;
  final List<EdukasiModel> edukasiList;
  final List<KontenModel> konteList;
  final List<SellerModel> sellers;
  final List<CookingRecipe> recipes;
  final SearchResultType resultType;
  final VoidCallback? onRefresh;

  const SearchResultsGrid({
    Key? key,
    required this.products,
    required this.edukasiList,
    required this.konteList,
    required this.sellers,
    required this.recipes,
    required this.resultType,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<SearchResultsGrid> {
  final ContentInteractionManager _contentManager = ContentInteractionManager();
  final UserManager _userManager = UserManager();

  // Local state for edukasi content and liked status
  late List<EdukasiModel> _localEdukasiList;
  late List<KontenModel> _localKontenList;
  Set<String> _likedContentIds = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _localEdukasiList = List.from(widget.edukasiList);
    _localKontenList = List.from(widget.konteList);
    _initializeLikedContent();
  }

  @override
  void didUpdateWidget(SearchResultsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update local list when parent updates
    if (oldWidget.edukasiList != widget.edukasiList) {
      setState(() {
        _localEdukasiList = List.from(widget.edukasiList);
      });
    }
    if (oldWidget.konteList != widget.konteList) {
      setState(() {
        _localKontenList = List.from(widget.konteList);
      });
    }
  }

  Future<void> _initializeLikedContent() async {
    if (_isInitialized) return;

    try {
      final userId = _userManager.getUserId(context);
      if (userId != null) {
        final likedIds = await _contentManager.getUserLikedContentIds(userId);
        if (mounted) {
          setState(() {
            _likedContentIds = likedIds;
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error loading liked content: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _handleEdukasiContentUpdated(EdukasiModel updatedContent) {
    // Update local edukasi list
    final index = _localEdukasiList.indexWhere(
      (item) => item.id == updatedContent.id,
    );
    if (index != -1) {
      setState(() {
        _localEdukasiList[index] = updatedContent;
      });
    }
  }

  void _handleKontenContentUpdated(KontenModel updatedContent) {
    // Update local konten list
    final index = _localKontenList.indexWhere(
      (item) => item.id == updatedContent.id,
    );
    if (index != -1) {
      setState(() {
        _localKontenList[index] = updatedContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmpty()) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF4DA8DA),
      onRefresh: () async {
        // Refresh liked content status
        await _initializeLikedContent();
        widget.onRefresh?.call();
      },
      child: _buildGridContent(),
    );
  }

  bool _isEmpty() {
    switch (widget.resultType) {
      case SearchResultType.products:
        return widget.products.isEmpty;
      case SearchResultType.edukasi:
        return _localEdukasiList.isEmpty && _localKontenList.isEmpty;
      case SearchResultType.sellers:
        return widget.sellers.isEmpty;
      case SearchResultType.recipes:
        return widget.recipes.isEmpty;
      case SearchResultType.all:
        return widget.products.isEmpty &&
            _localEdukasiList.isEmpty &&
            _localKontenList.isEmpty &&
            widget.sellers.isEmpty &&
            widget.recipes.isEmpty;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci yang berbeda atau\nubah filter pencarian',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DA8DA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridContent() {
    switch (widget.resultType) {
      case SearchResultType.products:
        return _buildProductsGrid();
      case SearchResultType.edukasi:
        return _buildEdukasiGrid();
      case SearchResultType.sellers:
        return _buildSellersGrid();
      case SearchResultType.recipes:
        return _buildRecipesGrid();
      case SearchResultType.all:
        return _buildAllResultsGrid();
    }
  }

  Widget _buildRecipesGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.recipes.length,
      itemBuilder: (context, index) {
        return CookingRecipeCard(
          recipe: widget.recipes[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CookingDetailScreen(recipe: widget.recipes[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: widget.products[index]);
      },
    );
  }

  Widget _buildEdukasiGrid() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4DA8DA)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _localEdukasiList.length + _localKontenList.length,
      itemBuilder: (context, index) {
        if (index < _localEdukasiList.length) {
          // Show Edukasi items first
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EdukasiCard(
              edukasi: _localEdukasiList[index],
              likedContentIds: _likedContentIds,
              onContentUpdated: _handleEdukasiContentUpdated,
            ),
          );
        } else {
          // Show Konten items after Edukasi
          final kontenIndex = index - _localEdukasiList.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KontenCard(
              konten: _localKontenList[kontenIndex],
              likedContentIds: _likedContentIds,
              onContentUpdated: (updatedContent) {
                // Convert EdukasiModel to KontenModel if needed
                // This assumes KontenModel and EdukasiModel are compatible
                // You might need to adjust this based on your actual model structure
                if (updatedContent is KontenModel) {
                  _handleKontenContentUpdated(updatedContent);
                }
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildSellersGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.sellers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SellerCard(seller: widget.sellers[index]),
        );
      },
    );
  }

  Widget _buildAllResultsGrid() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Products Section
        if (widget.products.isNotEmpty) ...[
          _buildSectionHeader('Produk', widget.products.length),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final cardWidth = (screenWidth - 16 * 2 - 12) / 2;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == widget.products.length - 1 ? 0 : 12,
                      ),
                      child: SizedBox(
                        width: cardWidth,
                        child: ProductCard(product: widget.products[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        //recipes
        if (widget.recipes.isNotEmpty) ...[
          _buildSectionHeader('Resep', widget.recipes.length),
          const SizedBox(height: 12),
          ...widget.recipes
              .take(3)
              .map(
                (recipe) => CookingRecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllEducationScreen(),
                      ),
                    );
                  },
                ),
              ),
          if (widget.recipes.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CookingListScreen(isSeller: false),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4DA8DA),
                ),
                child: Text('Lihat ${widget.recipes.length - 3} resep lainnya'),
              ),
            ),
          const SizedBox(height: 24),
        ],

        // Sellers Section
        if (widget.sellers.isNotEmpty) ...[
          _buildSectionHeader('Toko', widget.sellers.length),
          const SizedBox(height: 12),
          ...widget.sellers
              .take(3)
              .map(
                (seller) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SellerCard(seller: seller),
                ),
              ),
          if (widget.sellers.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllSellersScreen(sellers: widget.sellers),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4DA8DA),
                ),
                child: Text('Lihat ${widget.sellers.length - 3} toko lainnya'),
              ),
            ),
          const SizedBox(height: 24),
        ],

        // Edukasi Section
        if (_localEdukasiList.isNotEmpty) ...[
          _buildSectionHeader('Edukasi', _localEdukasiList.length),
          const SizedBox(height: 12),
          if (!_isInitialized)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF4DA8DA)),
              ),
            )
          else ...[
            ..._localEdukasiList
                .take(3)
                .map(
                  (edukasi) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EdukasiCard(
                      edukasi: edukasi,
                      likedContentIds: _likedContentIds,
                      onContentUpdated: _handleEdukasiContentUpdated,
                    ),
                  ),
                ),
            if (_localEdukasiList.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllEducationScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4DA8DA),
                  ),
                  child: Text(
                    'Lihat ${_localEdukasiList.length - 3} edukasi lainnya',
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
        ],

        // Konten Section
        if (_localKontenList.isNotEmpty) ...[
          _buildSectionHeader('Konten', _localKontenList.length),
          const SizedBox(height: 12),
          if (!_isInitialized)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF4DA8DA)),
              ),
            )
          else ...[
            ..._localKontenList
                .take(3)
                .map(
                  (konten) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: KontenCard(
                      konten:
                          konten, // Assuming KontenModel is compatible with EdukasiCard
                      likedContentIds: _likedContentIds,
                      onContentUpdated: (updatedContent) {
                        // Handle konten update
                        if (updatedContent is KontenModel) {
                          _handleKontenContentUpdated(updatedContent);
                        }
                      },
                    ),
                  ),
                ),
            if (_localKontenList.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllKontenScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4DA8DA),
                  ),
                  child: Text(
                    'Lihat ${_localKontenList.length - 3} konten lainnya',
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            '($count)',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
