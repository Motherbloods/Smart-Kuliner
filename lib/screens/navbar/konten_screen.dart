import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/data/dummy_template_content.dart';
import 'package:smart/models/user.dart';
import 'package:smart/screens/add_konten_screen.dart';
import 'package:smart/screens/navbar/edit_konten_screen.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'package:smart/widgets/common_components.dart';
import 'package:smart/widgets/content_card.dart';
import 'package:smart/widgets/picture_overlay.dart';
import 'package:smart/models/konten.dart';
import '../../providers/auth_provider.dart';
import "../../models/content_template.dart";
import "../../services/konten_service.dart";

class KontenScreen extends StatefulWidget {
  const KontenScreen({Key? key}) : super(key: key);

  @override
  State<KontenScreen> createState() => _KontenScreenState();
}

class _KontenScreenState extends State<KontenScreen> {
  bool _isLoading = false;
  String _selectedCategory = 'Semua';
  UserModel? _userData;

  // Dummy data untuk template konten (untuk seller)
  final List<ContentTemplate> _contentTemplates = templates;

  // Data konten dari Firebase
  List<KontenModel> _contentList = [];
  final KontenService _kontenService = KontenService();

  // Track user's liked content
  Set<String> _likedContentIds = <String>{};

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      setState(() {
        _userData = authProvider.currentUser;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memuat data profil: $e',
        );
      }
    }
  }

  // Load user's liked content from Firebase
  Future<void> _loadUserLikedContent() async {
    try {
      if (_userData?.uid != null) {
        final likedContentIds = await _kontenService.getUserLikedContentIds(
          _userData!.uid,
        );
        setState(() {
          _likedContentIds = likedContentIds.toSet();
        });
        print(
          '✅ Loaded ${likedContentIds.length} liked contents for user: ${_userData!.uid}',
        );
      }
    } catch (e) {
      print('⚠️ Error loading user liked content: $e');
      // Don't show error to user as this is not critical
    }
  }

  // Fungsi untuk memuat data konten dari Firebase
  Future<void> _loadContentData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final contentData = await _kontenService.getAllKonten();

      setState(() {
        _contentList = contentData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memuat data konten: $e',
        );
      }
    }
  }

  // Handle views update
  Future<void> _handleViewsUpdate(String contentId, int newViewsCount) async {
    try {
      // Update views in Firebase
      await _kontenService.updateViews(contentId, newViewsCount);

      // Update local data
      setState(() {
        final index = _contentList.indexWhere(
          (content) => content.id == contentId,
        );
        if (index != -1) {
          _contentList[index].views = newViewsCount;
        }
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memperbarui views: $e',
        );
      }
    }
  }

  // Handle likes update with Firebase user tracking
  Future<void> _handleLikesUpdate(
    String contentId,
    int newLikesCount,
    bool isLiked,
  ) async {
    try {
      if (_userData?.uid == null) return;

      // Update likes in Firebase
      await _kontenService.updateLikes(contentId, newLikesCount);

      // Update user like status in Firebase
      await _kontenService.setUserLikeStatus(
        contentId,
        _userData!.uid,
        isLiked,
      );

      // Update local data
      setState(() {
        final index = _contentList.indexWhere(
          (content) => content.id == contentId,
        );
        if (index != -1) {
          _contentList[index].likes = newLikesCount;
        }

        // Update liked status
        if (isLiked) {
          _likedContentIds.add(contentId);
        } else {
          _likedContentIds.remove(contentId);
        }
      });

      print(
        '✅ Updated like status: $contentId -> $isLiked (Total likes: $newLikesCount)',
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memperbarui likes: $e',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Initialize all data in proper sequence
  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadUserLikedContent(); // Load user likes first
    await _loadContentData(); // Then load content data
  }

  // Show picture overlay with dialog (like in beranda_user_view.dart)
  void _showPictureViewer(KontenModel content) {
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
    if (content.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten tidak memiliki gambar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isLiked = content.id != null
        ? _likedContentIds.contains(content.id!)
        : false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PictureOverlay(
        content: content,
        currentUser: _userData,
        initialLikedState: isLiked,
        onClose: () {
          Navigator.of(context).pop();
        },
        onViewsChanged: (newViewsCount) {
          if (content.id != null) {
            _handleViewsUpdate(content.id!, newViewsCount);
          }
        },
        onLikesChanged: (newLikesCount, isLiked) {
          if (content.id != null) {
            _handleLikesUpdate(content.id!, newLikesCount, isLiked);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        final isSeller = authProvider.currentUser?.seller ?? false;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: null,
          body: RefreshIndicator(
            onRefresh: _refreshContent,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4DA8DA)),
                  )
                : isSeller
                ? _buildSellerView()
                : _buildUserView(),
          ),
        );
      },
    );
  }

  Widget _buildSellerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template Section Header dengan tombol +
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Template Konten',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih template untuk membuat konten menarik',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              IconButton(
                onPressed: _addNewContent,
                icon: const Icon(Icons.add, color: Color(0xFF4DA8DA)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildTemplateGrid(),

          const SizedBox(height: 32),

          // Konten Saya
          const SectionHeader(
            title: 'Konten Saya',
            subtitle: 'Kelola konten yang telah Anda buat',
          ),
          const SizedBox(height: 16),
          _buildMyContentList(),
        ],
      ),
    );
  }

  Widget _buildUserView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Konten Terbaru',
            subtitle: 'Jelajahi konten menarik dari berbagai creator',
          ),
          const SizedBox(height: 16),
          _buildPublishedContentList(),
        ],
      ),
    );
  }

  Widget _buildTemplateGrid() {
    List<ContentTemplate> filteredTemplates = _selectedCategory == 'Semua'
        ? _contentTemplates
        : _contentTemplates
              .where((t) => t.category == _selectedCategory)
              .toList();

    return TemplateGrid(
      templates: filteredTemplates,
      getTitleCallback: (template) => template.title,
      getImageCallback: (template) => template.previewImage,
      getTypeCallback: (template) => template.type,
      getLinkCallback: (template) => template.link,
      onTemplateUsed: _useContentTemplate,
    );
  }

  Widget _buildMyContentList() {
    // Filter berdasarkan seller ID untuk menampilkan hanya konten milik seller yang login
    List<KontenModel> myContents = _contentList
        .where((content) => content.sellerId == _userData?.uid)
        .where(
          (content) =>
              _selectedCategory == 'Semua' ||
              content.category == _selectedCategory,
        )
        .toList();

    if (myContents.isEmpty) {
      return const EmptyState(
        title: 'Belum ada konten',
        subtitle: 'Mulai buat konten pertama Anda',
        icon: Icons.image_outlined,
      );
    }

    return Column(
      children: myContents
          .map(
            (content) => ContentCard(
              title: content.title,
              namaToko: content.namaToko,
              description: content.description,
              imageUrl: content.imageUrl,
              createdAt: content.createdAt,
              views: content.views,
              likes: content.likes,
              status: content.status,
              isOwner: true,
              contentId: content.id,
              initialLikedState: content.id != null
                  ? _likedContentIds.contains(content.id!)
                  : false,
              onEdit: () => _editContent(content),
              onDelete: () => _deleteContent(content),
              onView: () => _showPictureViewer(content),
              onViewsChanged: (newViewsCount) {
                if (content.id != null) {
                  _handleViewsUpdate(content.id!, newViewsCount);
                }
              },
              onLikesChanged: (newLikesCount, isLiked) {
                if (content.id != null) {
                  _handleLikesUpdate(content.id!, newLikesCount, isLiked);
                }
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildPublishedContentList() {
    final publishedContents = _contentList
        .where((content) => content.status == 'Published')
        .where(
          (content) =>
              _selectedCategory == 'Semua' ||
              content.category == _selectedCategory,
        )
        .toList();

    if (publishedContents.isEmpty) {
      return const EmptyState(
        title: 'Belum ada konten',
        subtitle: 'Konten dari creator akan muncul di sini',
        icon: Icons.image_outlined,
      );
    }

    return Column(
      children: publishedContents
          .map(
            (content) => ContentCard(
              title: content.title,
              namaToko: content.namaToko,
              description: content.description,
              imageUrl: content.imageUrl,
              category: content.category,
              createdAt: content.createdAt,
              views: content.views,
              likes: content.likes,
              status: content.status,
              isOwner: false,
              contentId: content.id,
              initialLikedState: content.id != null
                  ? _likedContentIds.contains(content.id!)
                  : false,
              onView: () => _showPictureViewer(content),
              onViewsChanged: (newViewsCount) {
                if (content.id != null) {
                  _handleViewsUpdate(content.id!, newViewsCount);
                }
              },
              onLikesChanged: (newLikesCount, isLiked) {
                if (content.id != null) {
                  _handleLikesUpdate(content.id!, newLikesCount, isLiked);
                }
              },
            ),
          )
          .toList(),
    );
  }

  Future<void> _refreshContent() async {
    await _initializeData(); // Refresh all data including user likes
  }

  void _addNewContent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddKontenScreen(
          sellerId: _userData!.uid,
          namaToko: _userData!.namaToko!,
        ),
      ),
    ).then((_) {
      _initializeData(); // Refresh data after adding new content
    });
  }

  void _useContentTemplate(dynamic template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menggunakan template: ${template.title}'),
        backgroundColor: const Color(0xFF4DA8DA),
      ),
    );
  }

  void _editContent(KontenModel content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditKontenScreen(
          konten: content,
          sellerId: _userData!.uid,
          namaToko: _userData!.namaToko!,
        ),
      ),
    ).then((result) {
      // Refresh data jika edit berhasil
      if (result == true) {
        _initializeData();
      }
    });
  }

  void _deleteContent(KontenModel content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Konten'),
        content: Text('Apakah Anda yakin ingin menghapus "${content.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                navigator.pop();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Menghapus konten...'),
                        ],
                      ),
                      duration: Duration(seconds: 30),
                    ),
                  );
                }

                await _kontenService.deleteKonten(content.id!);
                await _initializeData(); // Refresh all data

                if (mounted) {
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Konten berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.hideCurrentSnackBar();
                  SnackbarHelper.showErrorSnackbar(
                    context,
                    'Gagal menghapus konten: $e',
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
