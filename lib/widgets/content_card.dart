import 'package:flutter/material.dart';
import 'package:smart/utils/date_utils.dart';

class ContentCard extends StatefulWidget {
  final String title;
  final String? namaToko;
  final String description;
  final String imageUrl;
  final String? category; // Optional for education content
  final String? type; // Optional content type
  final int? readTime; // Optional read time for education content
  final DateTime createdAt;
  final int? views; // Optional for education content
  final int? likes; // Optional for education content
  final String? status; // Optional status for owner view
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final Function(int)? onViewsChanged; // Callback when views count changes
  final Function(int, bool)?
  onLikesChanged; // Callback when likes count changes (count, isLiked)
  final String? contentId; // Content ID for tracking likes
  final bool? initialLikedState; // Initial liked state

  const ContentCard({
    Key? key,
    required this.title,
    this.namaToko,
    required this.description,
    required this.imageUrl,
    this.category,
    this.type,
    this.readTime,
    required this.createdAt,
    this.views,
    this.likes,
    this.status,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.onViewsChanged,
    this.onLikesChanged,
    this.contentId,
    this.initialLikedState,
  }) : super(key: key);

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with TickerProviderStateMixin {
  late int _currentViews;
  late int _currentLikes;
  late bool _isLiked;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _currentViews = widget.views ?? 0;
    _currentLikes = widget.likes ?? 0;
    _isLiked = widget.initialLikedState ?? false;

    // Initialize like animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleContainerTap() {
    if (!widget.isOwner) {
      // Increment views count
      setState(() {
        _currentViews++;
      });
    }

    // Call the callback to update views in parent/database
    if (widget.onViewsChanged != null) {
      widget.onViewsChanged!(_currentViews);
    }

    // Call original onView callback if exists
    if (widget.onView != null) {
      widget.onView!();
    }
  }

  void _handleLikeDoubleTap() {
    // Only allow likes for non-owner content
    if (!widget.isOwner && widget.likes != null) {
      setState(() {
        if (_isLiked) {
          // Unlike: decrease likes count
          _currentLikes = (_currentLikes - 1).clamp(0, double.infinity.toInt());
          _isLiked = false;
        } else {
          // Like: increase likes count
          _currentLikes++;
          _isLiked = true;

          // Play like animation
          _likeAnimationController.forward().then((_) {
            _likeAnimationController.reverse();
          });
        }
      });

      // Call the callback to update likes in parent/database
      if (widget.onLikesChanged != null) {
        widget.onLikesChanged!(_currentLikes, _isLiked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ini niialsfnd ${widget.initialLikedState}');
    return GestureDetector(
      onTap: _handleContainerTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Image
            Container(
              height: 160,
              width: double.infinity,
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
                    Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            widget.category != null
                                ? Icons.school
                                : Icons.image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                    ),
                    // Category badge (for education content)
                    if (widget.category != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.category!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    // Read time badge (for education content)
                    if (widget.readTime != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.readTime} menit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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

            // Content Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Type badge (for education content)
                            if (widget.type != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.type!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Status badge (for owner view)
                      if (widget.isOwner && widget.status != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.status == 'Published'
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.status!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: widget.status == 'Published'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.isOwner) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.namaToko ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(widget.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      // Views count (for education content)
                      if (widget.views != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentViews.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      // Likes count (for education content)
                      if (widget.likes != null) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onDoubleTap: _handleLikeDoubleTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _likeAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _likeAnimation.value,
                                    child: Icon(
                                      _isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 30,
                                      color: _isLiked
                                          ? Colors.red
                                          : Colors.grey[500],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentLikes.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isLiked
                                      ? Colors.red
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Action buttons
                      if (widget.isOwner) ...[
                        if (widget.onEdit != null)
                          IconButton(
                            onPressed: widget.onEdit,
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Color(0xFFFF6B35),
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        if (widget.onEdit != null && widget.onDelete != null)
                          const SizedBox(width: 8),
                        if (widget.onDelete != null)
                          IconButton(
                            onPressed: widget.onDelete,
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ] else ...[
                        if (widget.onView != null)
                          GestureDetector(
                            onTap:
                                () {}, // Prevent this from triggering container tap
                            child: IconButton(
                              onPressed: widget.onView,
                              icon: Icon(
                                // Different icons for different content types
                                widget.views != null
                                    ? Icons.arrow_forward_ios
                                    : Icons.visibility_outlined,
                                size: widget.views != null ? 16 : 20,
                                color: const Color(0xFFFF6B35),
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
