import 'package:flutter/material.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/widgets/video_overlay.dart';
import 'package:smart/managers/content_interaction_manager.dart';
import 'package:smart/managers/user_manager.dart';

class EdukasiCard extends StatefulWidget {
  final EdukasiModel edukasi;
  final Function(EdukasiModel)? onContentUpdated; // Callback untuk update data
  final Set<String>? likedContentIds; // Set of liked content IDs

  const EdukasiCard({
    Key? key,
    required this.edukasi,
    this.onContentUpdated,
    this.likedContentIds,
  }) : super(key: key);

  @override
  State<EdukasiCard> createState() => _EdukasiCardState();
}

class _EdukasiCardState extends State<EdukasiCard> {
  final ContentInteractionManager _contentManager = ContentInteractionManager();
  final UserManager _userManager = UserManager();

  late EdukasiModel _currentEdukasi;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentEdukasi = widget.edukasi;
  }

  @override
  void didUpdateWidget(EdukasiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.edukasi != widget.edukasi) {
      setState(() {
        _currentEdukasi = widget.edukasi;
      });
    }
  }

  bool get _isLiked {
    return widget.likedContentIds?.contains(_currentEdukasi.id) ?? false;
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
          pageBuilder: (context, animation, secondaryAnimation) => VideoOverlay(
            content: _currentEdukasi,
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
      contentId: _currentEdukasi.id!,
      newViewsCount: newViews,
      context: context,
    );

    if (success && mounted) {
      setState(() {
        _currentEdukasi = _currentEdukasi.copyWith(views: newViews);
      });

      // Notify parent about the update
      widget.onContentUpdated?.call(_currentEdukasi);
    }
  }

  void _handleLikesChanged(int newLikes, bool isLiked) async {
    final currentUser = _userManager.getCurrentUser(context);
    if (currentUser == null) return;

    // Update likes in Firebase
    final success = await _contentManager.updateContentLikes(
      contentId: _currentEdukasi.id!,
      newLikesCount: newLikes,
      isLiked: isLiked,
      userId: currentUser.uid,
      context: context,
    );

    if (success && mounted) {
      setState(() {
        _currentEdukasi = _currentEdukasi.copyWith(likes: newLikes);
      });

      // Update liked content IDs in parent
      if (widget.likedContentIds != null) {
        _contentManager.updateLikedContentIds(
          likedContentIds: widget.likedContentIds!,
          contentId: _currentEdukasi.id!,
          isLiked: isLiked,
        );
      }

      // Notify parent about the update
      widget.onContentUpdated?.call(_currentEdukasi);
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
                      _currentEdukasi.imageUrl,
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
                      _currentEdukasi.title,
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
                      _currentEdukasi.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Info tambahan (Read time, category)
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentEdukasi.readTime} min read',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.category, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentEdukasi.category,
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
                          '${_currentEdukasi.views ?? 0} views',
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
                          '${_currentEdukasi.likes ?? 0} likes',
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
