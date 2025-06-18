import 'package:flutter/material.dart';
import 'package:smart/models/konten.dart';
import 'package:smart/widgets/picture_overlay.dart';
import 'package:smart/managers/content_interaction_manager.dart';
import 'package:smart/managers/user_manager.dart';

class KontenCard extends StatefulWidget {
  final KontenModel konten;
  final Function(KontenModel)? onContentUpdated; // Callback untuk update data
  final Set<String>? likedContentIds; // Set of liked content IDs

  const KontenCard({
    Key? key,
    required this.konten,
    this.onContentUpdated,
    this.likedContentIds,
  }) : super(key: key);

  @override
  State<KontenCard> createState() => _KontenCardState();
}

class _KontenCardState extends State<KontenCard> {
  final ContentInteractionManager _contentManager = ContentInteractionManager();
  final UserManager _userManager = UserManager();

  late KontenModel _currentKonten;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentKonten = widget.konten;
  }

  @override
  void didUpdateWidget(KontenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.konten != widget.konten) {
      setState(() {
        _currentKonten = widget.konten;
      });
    }
  }

  bool get _isLiked {
    return widget.likedContentIds?.contains(_currentKonten.id) ?? false;
  }

  void _showVideoOverlay() async {
    if (_isProcessing) return;

    // Get current user
    final currentUser = _userManager.getCurrentUser(context);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Show video overlay
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PictureOverlay(
                content: _currentKonten,
                currentUser: currentUser,
                initialLikedState: _isLiked,
                onClose: () => Navigator.of(context).pop(),
                onViewsChanged: _handleViewsChanged,
                onLikesChanged: _handleLikesChanged,
              ),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          fullscreenDialog: true,
        ),
      );
    } catch (e) {
      print('Error showing video overlay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleViewsChanged(int newViews) async {
    // Update views in Firebase
    final success = await _contentManager.updateContentViews(
      isEdukasi: false, // Karena ini konten, bukan edukasi
      contentId: _currentKonten.id!,
      newViewsCount: newViews,
      context: context,
    );

    if (success && mounted) {
      setState(() {
        _currentKonten = _currentKonten.copyWith(views: newViews);
      });

      // Notify parent about the update
      widget.onContentUpdated?.call(_currentKonten);
    }
  }

  void _handleLikesChanged(int newLikes, bool isLiked) async {
    final currentUser = _userManager.getCurrentUser(context);
    if (currentUser == null) return;

    // Update likes in Firebase
    final success = await _contentManager.updateContentLikes(
      isEdukasi: false, // Karena ini konten, bukan edukasi
      contentId: _currentKonten.id!,
      newLikesCount: newLikes,
      isLiked: isLiked,
      userId: currentUser.uid,
      context: context,
    );

    if (success && mounted) {
      setState(() {
        _currentKonten = _currentKonten.copyWith(likes: newLikes);
      });

      // Update liked content IDs in parent
      if (widget.likedContentIds != null) {
        _contentManager.updateLikedContentIds(
          likedContentIds: widget.likedContentIds!,
          contentId: _currentKonten.id!,
          isLiked: isLiked,
        );
      }

      // Notify parent about the update
      widget.onContentUpdated?.call(_currentKonten);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isProcessing ? null : _showVideoOverlay,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _currentKonten.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.grey,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                  // Play overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Processing indicator
                  if (_isProcessing)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withOpacity(0.6),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _currentKonten.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      _currentKonten.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Info tambahan (Read time, category)
                    Row(
                      children: [
                        Icon(Icons.category, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentKonten.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Likes & Views
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentKonten.views ?? 0} views',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 12,
                          color: _isLiked ? Colors.redAccent : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentKonten.likes ?? 0} likes',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
