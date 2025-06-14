// screens/beranda/beranda_user_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/screens/beranda/beranda_data_manager.dart';
import 'package:smart/widgets/product_card.dart';
import 'package:smart/widgets/content_card.dart';
import 'package:smart/widgets/video_overlay.dart';
import 'package:smart/screens/all_products_screen.dart';
import 'package:smart/screens/all_education_screen.dart';
import 'package:smart/providers/auth_provider.dart';
import 'package:smart/managers/content_interaction_manager.dart';
import 'package:smart/managers/user_manager.dart';
import 'package:smart/models/user.dart';
import 'package:smart/models/edukasi.dart';

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
      final likedIds = await _contentInteractionManager.getUserLikedContentIds(
        _currentUser!.uid,
      );
      if (mounted) {
        setState(() {
          _likedContentIds = likedIds;
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

    // Check if this content has video or can be displayed
    if (education.videoUrl.isEmpty) {
      if (education.imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konten tidak memiliki video atau gambar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
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
    );
  }

  Future<void> _handleViewsChanged(String contentId, int newViewsCount) async {
    // Update views in Firebase
    await _contentInteractionManager.updateContentViews(
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
      contentId: contentId,
      newLikesCount: newLikesCount,
      isLiked: isLiked,
      userId: _currentUser!.uid,
      context: context,
    );

    if (success) {
      // Update local liked content IDs
      _contentInteractionManager.updateLikedContentIds(
        likedContentIds: _likedContentIds,
        contentId: contentId,
        isLiked: isLiked,
      );

      // Update local data
      _updateLocalEducationData(contentId, newLikes: newLikesCount);

      if (mounted) {
        setState(() {
          // Trigger rebuild to update UI
        });
      }
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

            // Education List - Now with clickable functionality
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
                          // Show video overlay when content is tapped
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
          ],
        );
      },
    );
  }
}
