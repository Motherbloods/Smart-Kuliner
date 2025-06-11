import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/data/dummy_education_templates.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/user.dart';
import 'package:smart/screens/add_video_edukasi.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'package:smart/widgets/common_components.dart';
import 'package:smart/widgets/content_card.dart';
import '../../providers/auth_provider.dart';
import "../../models/education_template.dart";
import "../../services/edukasi_service.dart";

class EdukasiScreen extends StatefulWidget {
  const EdukasiScreen({Key? key}) : super(key: key);

  @override
  State<EdukasiScreen> createState() => _EdukasiScreenState();
}

class _EdukasiScreenState extends State<EdukasiScreen> {
  bool _isLoading = false;
  String _selectedCategory = 'Semua';
  UserModel? _userData;

  // Dummy data untuk template edukasi (untuk seller)
  final List<EducationTemplate> _educationTemplates = educationTemplates;

  // Data edukasi dari Firebase
  List<EdukasiModel> _educationContents = [];
  final EdukasiService _edukasiService = EdukasiService();

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
        final likedContentIds = await _edukasiService.getUserLikedContentIds(
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

  // Fungsi untuk memuat data edukasi dari Firebase
  Future<void> _loadEducationData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final educationData = await _edukasiService.getAllEdukasi();

      setState(() {
        _educationContents = educationData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memuat data edukasi: $e',
        );
      }
    }
  }

  // Handle views update
  Future<void> _handleViewsUpdate(String contentId, int newViewsCount) async {
    try {
      // Update views in Firebase
      await _edukasiService.updateViews(contentId, newViewsCount);

      // Update local data
      setState(() {
        final index = _educationContents.indexWhere(
          (content) => content.id == contentId,
        );
        if (index != -1) {
          _educationContents[index].views = newViewsCount;
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
      await _edukasiService.updateLikes(contentId, newLikesCount);

      // Update user like status in Firebase
      await _edukasiService.setUserLikeStatus(
        contentId,
        _userData!.uid,
        isLiked,
      );

      // Update local data
      setState(() {
        final index = _educationContents.indexWhere(
          (content) => content.id == contentId,
        );
        if (index != -1) {
          _educationContents[index].likes = newLikesCount;
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
    await _loadEducationData(); // Then load education data
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        final isSeller = authProvider.currentUser?.seller ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Edukasi',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: isSeller
                ? [
                    IconButton(
                      onPressed: _addNewEducationContent,
                      icon: const Icon(Icons.add, color: Color(0xFFFF6B35)),
                    ),
                  ]
                : null,
          ),
          body: RefreshIndicator(
            onRefresh: _refreshContent,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
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
          // Template Section
          const SectionHeader(
            title: 'Template Edukasi',
            subtitle: 'Pilih template untuk membuat konten edukatif',
          ),
          const SizedBox(height: 16),
          _buildTemplateGrid(),

          const SizedBox(height: 32),

          // My Education Content Section
          const SectionHeader(
            title: 'Konten Edukasi Saya',
            subtitle: 'Kelola konten edukasi yang telah Anda buat',
          ),
          const SizedBox(height: 16),
          _buildMyEducationList(),
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
            title: 'Konten Edukasi Terbaru',
            subtitle: 'Pelajari hal baru dari para ahli',
          ),
          const SizedBox(height: 16),
          _buildPublishedEducationList(),
        ],
      ),
    );
  }

  Widget _buildTemplateGrid() {
    List<EducationTemplate> filteredTemplates = _selectedCategory == 'Semua'
        ? _educationTemplates
        : _educationTemplates
              .where((t) => t.category == _selectedCategory)
              .toList();

    return TemplateGrid(
      templates: filteredTemplates,
      getTitleCallback: (template) => template.title,
      getImageCallback: (template) => template.previewImage,
      getTypeCallback: (template) => template.type,
      getLinkCallback: (template) => template.link,
      onTemplateUsed: _useEducationTemplate,
    );
  }

  Widget _buildMyEducationList() {
    // Filter berdasarkan seller ID untuk menampilkan hanya edukasi milik seller yang login
    List<EdukasiModel> myContents = _educationContents
        .where((content) => content.sellerId == _userData?.uid)
        .where(
          (content) =>
              _selectedCategory == 'Semua' ||
              content.category == _selectedCategory,
        )
        .toList();

    if (myContents.isEmpty) {
      return const EmptyState(
        title: 'Belum ada konten edukasi',
        subtitle: 'Mulai buat konten edukasi pertama Anda',
        icon: Icons.school_outlined,
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
              category: content.category,
              readTime: content.readTime,
              createdAt: content.createdAt,
              views: content.views,
              likes: content.likes,
              status: content.status,
              isOwner: true,
              contentId: content.id,
              initialLikedState: content.id != null
                  ? _likedContentIds.contains(content.id!)
                  : false,
              onEdit: () => _editEducationContent(content),
              onDelete: () => _deleteEducationContent(content),
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

  Widget _buildPublishedEducationList() {
    final publishedContents = _educationContents
        .where((content) => content.status == 'Published')
        .where(
          (content) =>
              _selectedCategory == 'Semua' ||
              content.category == _selectedCategory,
        )
        .toList();

    if (publishedContents.isEmpty) {
      return const EmptyState(
        title: 'Belum ada konten edukasi',
        subtitle: 'Konten edukasi dari seller akan muncul di sini',
        icon: Icons.school_outlined,
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
              readTime: content.readTime,
              createdAt: content.createdAt,
              views: content.views,
              likes: content.likes,
              status: content.status,
              isOwner: false,
              contentId: content.id,
              initialLikedState: content.id != null
                  ? _likedContentIds.contains(content.id!)
                  : false,
              onView: () => _viewEducationContent(content),
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

  void _addNewEducationContent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEdukasiScreen(
          sellerId: _userData!.uid,
          namaToko: _userData!.namaToko!,
        ),
      ),
    ).then((_) {
      _initializeData(); // Refresh data after adding new content
    });
  }

  void _useEducationTemplate(dynamic template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menggunakan template: ${template.title}'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }

  void _editEducationContent(EdukasiModel content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit konten: ${content.title}'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }

  void _deleteEducationContent(EdukasiModel content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Konten Edukasi'),
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

                await _edukasiService.deleteEdukasi(content.id!);
                await _initializeData(); // Refresh all data

                if (mounted) {
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Konten edukasi berhasil dihapus'),
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

  void _viewEducationContent(EdukasiModel content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membaca: ${content.title}'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }
}
