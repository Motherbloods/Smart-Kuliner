import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionHeader({Key? key, required this.title, required this.subtitle})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyState({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TemplateGrid extends StatelessWidget {
  final List<dynamic> templates; // Can be ContentTemplate or EducationTemplate
  final String Function(dynamic) getTitleCallback;
  final String Function(dynamic) getImageCallback;
  final String Function(dynamic) getLinkCallback;
  final String? Function(dynamic) getTypeCallback;
  final void Function(dynamic) onTemplateUsed;

  const TemplateGrid({
    Key? key,
    required this.templates,
    required this.getTitleCallback,
    required this.getImageCallback,
    required this.getLinkCallback,
    required this.getTypeCallback,
    required this.onTemplateUsed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return const EmptyState(
        title: 'Tidak ada template',
        subtitle: 'Template untuk kategori ini belum tersedia',
        icon: Icons.library_books_outlined,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return TemplateCard(
          title: getTitleCallback(template),
          link: getLinkCallback(template),
          previewImage: getImageCallback(template),
          type: getTypeCallback(template),
          onTap: () => onTemplateUsed(template),
        );
      },
    );
  }
}

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String contentName;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    Key? key,
    required this.title,
    required this.contentName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text('Apakah Anda yakin ingin menghapus "$contentName"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Hapus'),
        ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String contentName,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: title,
        contentName: contentName,
        onConfirm: onConfirm,
      ),
    );
  }
}

class TemplateCard extends StatefulWidget {
  final String title;
  final String previewImage;
  final String link;
  final String? type; // Optional type for education templates
  final VoidCallback onTap;

  const TemplateCard({
    Key? key,
    required this.title,
    required this.previewImage,
    required this.link,
    this.type,
    required this.onTap,
  }) : super(key: key);

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _loadingController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleTemplatePress() async {
    setState(() {
      _isLoading = true;
    });

    _loadingController.repeat();

    try {
      final uri = Uri.parse(widget.link);

      // Cek apakah link CapCut
      final isCapCut = uri.host.contains('capcut://');

      if (isCapCut && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        widget.onTap();

        await Future.delayed(const Duration(milliseconds: 500));
        await _fadeController.forward();

        _loadingController.reset();
        _fadeController.reset();
      } else {
        // Kalau bukan CapCut, buka seperti biasa di browser
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          // Coba buka dalam webview di dalam aplikasi
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }
      }
    } catch (e) {
      print("Error launching URL: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat membuka template'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _loadingController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _isLoading ? _fadeAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview Image - Allow it to be flexible
                Flexible(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 100, // Minimum height for image
                      maxHeight:
                          140, // Maximum height to leave space for content
                    ),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Image.asset(
                            widget.previewImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.library_books,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                          if (widget.type != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.type!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          // Loading overlay
                          if (_isLoading)
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RotationTransition(
                                      turns: _loadingController,
                                      child: const Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Membuka CapCut...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content - Use Container with fixed height instead of Expanded
                Container(
                  height: 80, // Fixed height for content area
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title - Flexible to take available space
                      Flexible(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Button - Fixed at bottom
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleTemplatePress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoading
                                ? Colors.grey[400]
                                : const Color(0xFF4DA8DA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Membuka...',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Coba Template',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
