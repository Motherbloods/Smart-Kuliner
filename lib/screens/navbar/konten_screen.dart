import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/data/dummy_seller_content.dart';
import 'package:smart/data/dummy_template_content.dart';
import 'package:smart/models/content_template.dart';
import 'package:smart/models/seller_content.dart';
import 'package:smart/widgets/common_components.dart';
import 'package:smart/widgets/content_card.dart';
import '../../providers/auth_provider.dart';

class KontenScreen extends StatefulWidget {
  const KontenScreen({Key? key}) : super(key: key);

  @override
  State<KontenScreen> createState() => _KontenScreenState();
}

class _KontenScreenState extends State<KontenScreen> {
  bool _isLoading = false;

  // Dummy data untuk template (untuk seller)
  final List<ContentTemplate> _templates = templates;

  // Dummy data untuk konten seller
  final List<SellerContent> _sellerContents = sellerContents;

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        final isSeller = authProvider.currentUser?.seller ?? false;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Konten',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: isSeller
                ? [
                    IconButton(
                      onPressed: _addNewContent,
                      icon: const Icon(Icons.add, color: Color(0xFF4DA8DA)),
                    ),
                  ]
                : null,
          ),
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
          // Template Section
          const SectionHeader(
            title: 'Template Konten',
            subtitle: 'Pilih template untuk membuat konten yang menarik',
          ),
          const SizedBox(height: 16),
          TemplateGrid(
            templates: _templates,
            getTitleCallback: (template) => template.title,
            getImageCallback: (template) => template.previewImage,
            getLinkCallback: (template) => template.link,
            getTypeCallback: (template) =>
                null, // Content templates don't have type
            onTemplateUsed: _useTemplate,
          ),

          const SizedBox(height: 32),

          // My Content Section
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
            subtitle: 'Konten menarik dari para seller',
          ),
          const SizedBox(height: 16),
          _buildPublishedContentList(),
        ],
      ),
    );
  }

  Widget _buildMyContentList() {
    if (_sellerContents.isEmpty) {
      return const EmptyState(
        title: 'Belum ada konten',
        subtitle: 'Mulai buat konten pertama Anda',
        icon: Icons.article_outlined,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sellerContents.length,
      itemBuilder: (context, index) {
        final content = _sellerContents[index];
        return ContentCard(
          title: content.title,
          description: content.description,
          imageUrl: content.imageUrl,
          createdAt: content.createdAt,
          status: content.status,
          isOwner: true,
          onEdit: () => _editContent(content),
          onDelete: () => _deleteContent(content),
        );
      },
    );
  }

  Widget _buildPublishedContentList() {
    final publishedContents = _sellerContents
        .where((content) => content.status == 'Published')
        .toList();

    if (publishedContents.isEmpty) {
      return const EmptyState(
        title: 'Belum ada konten',
        subtitle: 'Konten dari seller akan muncul di sini',
        icon: Icons.article_outlined,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: publishedContents.length,
      itemBuilder: (context, index) {
        final content = publishedContents[index];
        return ContentCard(
          title: content.title,
          description: content.description,
          imageUrl: content.imageUrl,
          createdAt: content.createdAt,
          isOwner: false,
          onView: () => _viewContent(content),
        );
      },
    );
  }

  Future<void> _refreshContent() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });
  }

  void _addNewContent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur tambah konten akan segera hadir'),
        backgroundColor: Color(0xFF4DA8DA),
      ),
    );
  }

  void _useTemplate(dynamic template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menggunakan template: ${template.title}'),
        backgroundColor: const Color(0xFF4DA8DA),
      ),
    );
  }

  void _editContent(SellerContent content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit konten: ${content.title}'),
        backgroundColor: const Color(0xFF4DA8DA),
      ),
    );
  }

  void _deleteContent(SellerContent content) {
    DeleteConfirmationDialog.show(
      context,
      title: 'Hapus Konten',
      contentName: content.title,
      onConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konten berhasil dihapus'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _viewContent(SellerContent content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Melihat konten: ${content.title}'),
        backgroundColor: const Color(0xFF4DA8DA),
      ),
    );
  }
}
