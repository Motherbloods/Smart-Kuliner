// all_konten_screen.dart (fixed)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/konten.dart';
import 'package:smart/models/user.dart';
import 'package:smart/services/edukasi_service.dart';
import 'package:smart/services/konten_service.dart';
import 'package:smart/widgets/content_card.dart';
import 'package:smart/widgets/video_overlay.dart';
import 'package:smart/widgets/picture_overlay.dart';
import 'package:smart/managers/content_interaction_manager.dart';
import 'package:smart/managers/user_manager.dart';
import '../../providers/auth_provider.dart';

class AllKontenScreen extends StatefulWidget {
  const AllKontenScreen({Key? key}) : super(key: key);

  @override
  State<AllKontenScreen> createState() => _AllKontenScreenState();
}

class _AllKontenScreenState extends State<AllKontenScreen> {
  final KontenService _kontenService = KontenService();
  final TextEditingController _searchController = TextEditingController();
  final ContentInteractionManager _contentManager = ContentInteractionManager();
  final UserManager _userManager = UserManager();

  List<KontenModel> _allKonten = [];
  List<KontenModel> _filteredKonten = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _sortBy = 'Terbaru';

  KontenModel? _selectedContent;

  // User data and liked content tracking
  UserModel? _userData;
  Set<String> _likedContentIds = <String>{};

  // State untuk picture overlay
  bool _showPictureOverlay = false;

  final List<String> _categories = [
    'Semua',
    'Makanan Utama',
    'Cemilan',
    'Minuman',
    'Makanan Sehat',
    'Dessert',
    "Lainnya",
  ];

  final List<String> _sortOptions = [
    'Terbaru',
    'Terlama',
    'Paling Banyak Dilihat',
    'Paling Banyak Disukai',
    'Judul A-Z',
    'Judul Z-A',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Initialize all data in proper sequence
  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadUserLikedContent();
    await _loadAllKonten();
  }

  // Load user data using UserManager
  Future<void> _loadUserData() async {
    final userData = await _userManager.loadUserData(context);
    setState(() {
      _userData = userData;
    });
  }

  // Load user's liked content using ContentInteractionManager
  Future<void> _loadUserLikedContent() async {
    if (_userData?.uid != null) {
      final likedContentIds = await _contentManager.getUserLikedContentIds(
        _userData!.uid,
      );
      setState(() {
        _likedContentIds = likedContentIds;
      });
    }
  }

  Future<void> _loadAllKonten() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final kontenData = await _kontenService.getAllKonten();
      if (mounted) {
        setState(() {
          _allKonten = kontenData
              .where((content) => content.status == 'Published')
              .toList();
          _filteredKonten = _allKonten;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat konten promosi: $error';
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<KontenModel> filtered = _allKonten;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((konten) {
        return konten.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            konten.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            konten.namaToko.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'Semua') {
      filtered = filtered
          .where((konten) => konten.category == _selectedCategory)
          .toList();
    }

    // Sort konten
    switch (_sortBy) {
      case 'Terbaru':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Terlama':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Paling Banyak Dilihat':
        filtered.sort((a, b) => b.views.compareTo(a.views));
        break;
      case 'Paling Banyak Disukai':
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'Judul A-Z':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Judul Z-A':
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    setState(() {
      _filteredKonten = filtered;
    });
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Urutkan Berdasarkan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ..._sortOptions.map((option) {
                return ListTile(
                  title: Text(option),
                  trailing: _sortBy == option
                      ? const Icon(Icons.check, color: Color(0xFF4DA8DA))
                      : null,
                  onTap: () {
                    setState(() {
                      _sortBy = option;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Method untuk menampilkan picture overlay
  void _showPictureDialog(KontenModel konten) {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if this content has image
    if (konten.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten tidak memiliki gambar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isLiked = _likedContentIds.contains(konten.id);

    setState(() {
      _showPictureOverlay = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PictureOverlay(
        content: konten,
        currentUser: _userData,
        initialLikedState: isLiked,
        onClose: () {
          setState(() {
            _showPictureOverlay = false;
          });
          Navigator.of(context).pop();
        },
        onViewsChanged: (newViewsCount) {
          _handleViewsUpdate(konten.id!, newViewsCount);
        },
        onLikesChanged: (newLikesCount, isLiked) {
          _handleLikesUpdate(konten.id!, newLikesCount, isLiked);
        },
      ),
    );
  }

  // Handle views update using ContentInteractionManager
  Future<void> _handleViewsUpdate(String contentId, int newViewsCount) async {
    final success = await _contentManager.updateContentViews(
      isEdukasi: false,
      contentId: contentId,
      newViewsCount: newViewsCount,
      context: context,
    );

    if (success) {
      setState(() {
        _contentManager.updateLocalKontenData(
          contentId: contentId,
          allContent: _allKonten,
          filteredContent: _filteredKonten,
          newViewsCount: newViewsCount,
        );
      });
    }
  }

  // Handle likes update using ContentInteractionManager
  Future<void> _handleLikesUpdate(
    String contentId,
    int newLikesCount,
    bool isLiked,
  ) async {
    if (_userData?.uid == null) return;

    final success = await _contentManager.updateContentLikes(
      isEdukasi: false,
      contentId: contentId,
      newLikesCount: newLikesCount,
      isLiked: isLiked,
      userId: _userData!.uid,
      context: context,
    );

    if (success) {
      setState(() {
        _contentManager.updateLocalKontenData(
          contentId: contentId,
          allContent: _allKonten,
          filteredContent: _filteredKonten,
          newLikesCount: newLikesCount,
        );

        _contentManager.updateLikedContentIds(
          likedContentIds: _likedContentIds,
          contentId: contentId,
          isLiked: isLiked,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _showPictureOverlay
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    'Konten Edukasi',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.sort, color: Colors.black87),
                      onPressed: _showSortBottomSheet,
                    ),
                  ],
                ),
          body: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Search Bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari konten edukasi...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4DA8DA),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Category Filter
                  Container(
                    height: 50,
                    color: Colors.white,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _applyFilters();
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index == _categories.length - 1 ? 0 : 12,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4DA8DA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4DA8DA)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Results Count
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      '${_filteredKonten.length} konten edukasi ditemukan',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _initializeData();
                      },
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4DA8DA)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DA8DA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredKonten.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'Semua'
                  ? 'Konten edukasi tidak ditemukan'
                  : 'Belum ada konten edukasi',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'Semua'
                  ? 'Coba kata kunci lain atau ubah filter'
                  : 'Konten edukasi akan muncul di sini',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredKonten.length,
      itemBuilder: (context, index) {
        final konten = _filteredKonten[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ContentCard(
            title: konten.title,
            namaToko: konten.namaToko,
            description: konten.description,
            imageUrl: konten.imageUrl,
            category: konten.category,
            createdAt: konten.createdAt,
            views: konten.views,
            likes: konten.likes,
            status: konten.status,
            isOwner: false,
            contentId: konten.id,
            initialLikedState: konten.id != null
                ? _likedContentIds.contains(konten.id!)
                : false,
            onView: () {
              if (konten.imageUrl.isNotEmpty) {
                _showPictureDialog(konten);
              }
            },
            onViewsChanged: (newViewsCount) {
              if (konten.id != null) {
                _handleViewsUpdate(konten.id!, newViewsCount);
              }
            },
            onLikesChanged: (newLikesCount, isLiked) {
              if (konten.id != null) {
                _handleLikesUpdate(konten.id!, newLikesCount, isLiked);
              }
            },
          ),
        );
      },
    );
  }
}
