// screens/beranda/beranda_user_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/screens/all_konten_screen.dart';
import 'package:smart/screens/beranda/beranda_data_manager.dart';
import 'package:smart/widgets/product_card.dart';
import 'package:smart/widgets/content_card.dart';
import 'package:smart/widgets/video_overlay.dart';
import 'package:smart/widgets/picture_overlay.dart'; // Import PictureOverlay
import 'package:smart/screens/all_products_screen.dart';
import 'package:smart/screens/all_education_screen.dart';
import 'package:smart/providers/auth_provider.dart';
import 'package:smart/managers/content_interaction_manager.dart';
import 'package:smart/managers/user_manager.dart';
import 'package:smart/models/user.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/konten.dart'; // Import KontenModel

class BerandaUserView extends StatefulWidget {
  final BerandaState state;
  final VoidCallback onRefresh;

  const BerandaUserView({
    Key? key,
    required this.state,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<BerandaUserView> createState() => _BerandaUserViewState();
}

class _BerandaUserViewState extends State<BerandaUserView> {
  final ContentInteractionManager _contentInteractionManager =
      ContentInteractionManager();
  final UserManager _userManager = UserManager();
  Set<String> _likedContentIds = <String>{};
  Set<String> _likedKontenIds = <String>{}; // Separate set for konten
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    _currentUser = _userManager.getCurrentUser(context);
    if (_currentUser != null) {
      await _loadUserLikedContent();
    }
  }

  Future<void> _loadUserLikedContent() async {
    if (_currentUser?.uid != null) {
      // Load liked education content
      final likedEducationIds = await _contentInteractionManager
          .getUserLikedContentIds(_currentUser!.uid);

      // Load liked konten
      final likedKontenIds = await _contentInteractionManager
          .getUserLikedKontenIds(_currentUser!.uid);

      if (mounted) {
        setState(() {
          _likedContentIds = likedEducationIds;
          _likedKontenIds = likedKontenIds;
        });
      }
    }
  }

  void _showVideoOverlay(EdukasiModel education) {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (education.videoUrl.isEmpty && education.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten tidak memiliki video atau gambar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isLiked = _likedContentIds.contains(education.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VideoOverlay(
        content: education,
        currentUser: _currentUser,
        initialLikedState: isLiked,
        onClose: () {
          Navigator.of(context).pop();
        },
        onViewsChanged: (newViewsCount) {
          _handleViewsChanged(education.id!, newViewsCount);
        },
        onLikesChanged: (newLikesCount, isLiked) {
          _handleLikesChanged(education.id!, newLikesCount, isLiked);
        },
      ),
    ).then((_) {
      // PERBAIKAN: Refresh state setelah overlay ditutup
      if (mounted) {
        setState(() {
          // Trigger rebuild untuk memastikan UI terupdate
        });
      }
    });
  }

  // Method baru untuk menampilkan PictureOverlay untuk konten promosi
  void _showPicture(KontenModel konten) {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (konten.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten tidak memiliki gambar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isLiked = _likedKontenIds.contains(konten.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PictureOverlay(
        content: konten,
        currentUser: _currentUser,
        initialLikedState: isLiked,
        onClose: () {
          Navigator.of(context).pop();
        },
        onViewsChanged: (newViewsCount) {
          _handleViewsChangedKonten(konten.id!, newViewsCount);
        },
        onLikesChanged: (newLikesCount, isLiked) {
          _handleLikesChangedKonten(konten.id!, newLikesCount, isLiked);
        },
      ),
    ).then((_) {
      // PERBAIKAN: Refresh state setelah overlay ditutup
      if (mounted) {
        setState(() {
          // Trigger rebuild untuk memastikan UI terupdate
        });
      }
    });
  }

  Future<void> _handleViewsChanged(String contentId, int newViewsCount) async {
    // Update views in Firebase
    await _contentInteractionManager.updateContentViews(
      isEdukasi: true,
      contentId: contentId,
      newViewsCount: newViewsCount,
      context: context,
    );

    // Update local data
    _updateLocalEducationData(contentId, newViews: newViewsCount);
  }

  Future<void> _handleLikesChanged(
    String contentId,
    int newLikesCount,
    bool isLiked,
  ) async {
    if (_currentUser?.uid == null) return;

    // Update likes in Firebase
    final success = await _contentInteractionManager.updateContentLikes(
      isEdukasi: true,
      contentId: contentId,
      newLikesCount: newLikesCount,
      isLiked: isLiked,
      userId: _currentUser!.uid,
      context: context,
    );

    if (success) {
      // Update local liked content IDs IMMEDIATELY
      setState(() {
        _contentInteractionManager.updateLikedContentIds(
          likedContentIds: _likedContentIds,
          contentId: contentId,
          isLiked: isLiked,
        );
      });

      // Update local data
      _updateLocalEducationData(contentId, newLikes: newLikesCount);

      print('✅ Education like updated locally: $contentId -> $isLiked');
    }
  }

  // Method baru untuk handle views changed untuk konten
  Future<void> _handleViewsChangedKonten(
    String contentId,
    int newViewsCount,
  ) async {
    // Update views in Firebase
    await _contentInteractionManager.updateContentViews(
      isEdukasi: false,
      contentId: contentId,
      newViewsCount: newViewsCount,
      context: context,
    );

    // Update local data
    _updateLocalKontenData(contentId, newViews: newViewsCount);
  }

  // Method baru untuk handle likes changed untuk konten
  Future<void> _handleLikesChangedKonten(
    String contentId,
    int newLikesCount,
    bool isLiked,
  ) async {
    if (_currentUser?.uid == null) return;

    // Update likes in Firebase
    final success = await _contentInteractionManager.updateContentLikes(
      isEdukasi: false,
      contentId: contentId,
      newLikesCount: newLikesCount,
      isLiked: isLiked,
      userId: _currentUser!.uid,
      context: context,
    );

    if (success) {
      // Update local liked content IDs IMMEDIATELY
      setState(() {
        _contentInteractionManager.updateLikedContentIds(
          likedContentIds: _likedKontenIds,
          contentId: contentId,
          isLiked: isLiked,
        );
      });

      // Update local data
      _updateLocalKontenData(contentId, newLikes: newLikesCount);

      print('✅ Konten like updated locally: $contentId -> $isLiked');
    }
  }

  void _updateLocalEducationData(
    String contentId, {
    int? newViews,
    int? newLikes,
  }) {
    // Find and update the education item in the state
    final educationIndex = widget.state.latestEducation.indexWhere(
      (education) => education.id == contentId,
    );

    if (educationIndex != -1) {
      if (newViews != null) {
        widget.state.latestEducation[educationIndex].views = newViews;
      }
      if (newLikes != null) {
        widget.state.latestEducation[educationIndex].likes = newLikes;
      }

      if (mounted) {
        setState(() {
          // Trigger rebuild to update UI
        });
      }
    }
  }

  // Method baru untuk update local konten data
  void _updateLocalKontenData(
    String contentId, {
    int? newViews,
    int? newLikes,
  }) {
    // Find and update the konten item in the state
    final kontenIndex = widget.state.latestKonten.indexWhere(
      (konten) => konten.id == contentId,
    );

    if (kontenIndex != -1) {
      if (newViews != null) {
        widget.state.latestKonten[kontenIndex].views = newViews;
      }
      if (newLikes != null) {
        widget.state.latestKonten[kontenIndex].likes = newLikes;
      }

      if (mounted) {
        setState(() {
          // Trigger rebuild to update UI
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        // Update current user if it changes
        if (_currentUser?.uid != authProvider.currentUser?.uid) {
          _currentUser = authProvider.currentUser;
          if (_currentUser != null) {
            _loadUserLikedContent();
          }
        }

        return CustomScrollView(
          slivers: [
            // Latest Products Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Produk Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllProductsScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              color: Color(0xFF4DA8DA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Products Grid
            if (widget.state.latestProducts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = widget.state.latestProducts[index];
                    return ProductCard(product: product);
                  }, childCount: widget.state.latestProducts.length),
                ),
              ),

            // Empty state untuk products
            if (widget.state.latestProducts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Belum ada produk terbaru',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Education Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Konten Edukasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllEducationScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: Color(0xFF4DA8DA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Education List - Now with real-time like updates
            if (widget.state.latestEducation.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final education = widget.state.latestEducation[index];
                    final isLiked = _likedContentIds.contains(education.id);

                    final isOwner = _currentUser?.uid == education.sellerId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ContentCard(
                        key: ValueKey(
                          'education_${education.id}',
                        ), // TAMBAHKAN KEY
                        title: education.title,
                        namaToko: education.namaToko,
                        description: education.description,
                        imageUrl: education.imageUrl,
                        category: education.category,
                        readTime: education.readTime,
                        createdAt: education.createdAt,
                        views: education.views,
                        likes: education.likes,
                        status: education.status,
                        isOwner: isOwner,
                        contentId: education.id,
                        initialLikedState: isLiked,
                        onView: () {
                          _showVideoOverlay(education);
                        },
                        onViewsChanged: (newViewsCount) {
                          _handleViewsChanged(education.id!, newViewsCount);
                        },
                        onLikesChanged: (newLikesCount, isLiked) {
                          _handleLikesChanged(
                            education.id!,
                            newLikesCount,
                            isLiked,
                          );
                        },
                      ),
                    );
                  }, childCount: widget.state.latestEducation.length),
                ),
              ),

            // Empty state untuk education
            if (widget.state.latestEducation.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Belum ada konten edukasi',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Konten Promosi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllKontenScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: Color(0xFF4DA8DA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Konten List - Now with real-time like updates
            if (widget.state.latestKonten.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final konten = widget.state.latestKonten[index];
                    final isLiked = _likedKontenIds.contains(konten.id);
                    final isOwner = _currentUser?.uid == konten.sellerId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ContentCard(
                        key: ValueKey('konten_${konten.id}'), // TAMBAHKAN KEY
                        title: konten.title,
                        namaToko: konten.namaToko,
                        description: konten.description,
                        imageUrl: konten.imageUrl,
                        category: konten.category,
                        createdAt: konten.createdAt,
                        views: konten.views,
                        likes: konten.likes,
                        status: konten.status,
                        isOwner: isOwner,
                        contentId: konten.id,
                        initialLikedState: isLiked,
                        onView: () {
                          _showPicture(konten);
                        },
                        onViewsChanged: (newViewsCount) {
                          _handleViewsChangedKonten(konten.id!, newViewsCount);
                        },
                        onLikesChanged: (newLikesCount, isLiked) {
                          _handleLikesChangedKonten(
                            konten.id!,
                            newLikesCount,
                            isLiked,
                          );
                        },
                      ),
                    );
                  }, childCount: widget.state.latestKonten.length),
                ),
              ),

            // Empty state untuk konten
            if (widget.state.latestKonten.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Belum ada konten promosi',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}
