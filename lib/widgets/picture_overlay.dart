import 'package:flutter/material.dart';
import 'package:smart/models/konten.dart';
import 'package:smart/models/user.dart';
import 'package:intl/intl.dart';

class PictureOverlay extends StatefulWidget {
  final KontenModel content;
  final VoidCallback onClose;
  final Function(int) onViewsChanged;
  final Function(int, bool) onLikesChanged;
  final bool initialLikedState;
  final UserModel? currentUser;

  const PictureOverlay({
    Key? key,
    required this.content,
    required this.onClose,
    required this.onViewsChanged,
    required this.onLikesChanged,
    required this.initialLikedState,
    this.currentUser,
  }) : super(key: key);

  @override
  State<PictureOverlay> createState() => _PictureOverlayState();
}

class _PictureOverlayState extends State<PictureOverlay>
    with TickerProviderStateMixin {
  bool _isLiked = false;
  int _currentViews = 0;
  int _currentLikes = 0;
  AnimationController? _likeAnimationController;
  AnimationController? _fadeAnimationController;
  bool _showOverlayInfo = true;

  // Check if current user is the owner of this content
  bool get _isOwner {
    return widget.currentUser?.uid == widget.content.sellerId;
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLikedState;
    _currentViews = widget.content.views;
    _currentLikes = widget.content.likes;

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _incrementViews();
    _fadeAnimationController!.forward();

    // Auto hide overlay info after 3 seconds
    _autoHideOverlayInfo();
  }

  void _autoHideOverlayInfo() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showOverlayInfo) {
        setState(() {
          _showOverlayInfo = false;
        });
      }
    });
  }

  void _toggleOverlayInfo() {
    setState(() {
      _showOverlayInfo = !_showOverlayInfo;
    });

    if (_showOverlayInfo) {
      _autoHideOverlayInfo();
    }
  }

  void _incrementViews() {
    final newViews = _currentViews + 1;
    setState(() {
      _currentViews = newViews;
    });
    widget.onViewsChanged(newViews);
  }

  void _toggleLike() {
    // Prevent owners from liking their own content
    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menyukai konten Anda sendiri'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final newLikedState = !_isLiked;
    final newLikes = newLikedState ? _currentLikes + 1 : _currentLikes - 1;

    setState(() {
      _isLiked = newLikedState;
      _currentLikes = newLikes;
    });

    // Animate like button
    _likeAnimationController!.forward().then((_) {
      _likeAnimationController!.reverse();
    });

    widget.onLikesChanged(newLikes, newLikedState);
  }

  Widget _buildImageViewer() {
    if (widget.content.imageUrl == null || widget.content.imageUrl.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text(
                'Gambar tidak tersedia',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Image.network(
            widget.content.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF4DA8DA)),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat gambar...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController?.dispose();
    _fadeAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // Main Image Viewer
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleOverlayInfo,
                child: _buildImageViewer(),
              ),
            ),

            // Header Overlay
            AnimatedOpacity(
              opacity: _showOverlayInfo ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        widget.content.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Info Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showOverlayInfo ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title and Actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.content.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      widget.content.namaToko!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    // Show owner badge if current user is the owner
                                    if (_isOwner) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4DA8DA),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Milik Anda',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Like Button - Only show if not owner
                          if (!_isOwner)
                            AnimatedBuilder(
                              animation: _likeAnimationController!,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale:
                                      1.0 +
                                      (_likeAnimationController!.value * 0.2),
                                  child: GestureDetector(
                                    onTap: _toggleLike,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        _isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: _isLiked
                                            ? Colors.red
                                            : Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Stats
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_currentViews views',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.favorite, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_currentLikes likes',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4DA8DA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.content.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Description
                      if (widget.content.description.isNotEmpty)
                        Text(
                          widget.content.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 8),

                      // Created Date
                      Text(
                        'Dibuat ${DateFormat('dd MMM yyyy').format(widget.content.createdAt)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tap to show/hide info hint
            if (!_showOverlayInfo)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showOverlayInfo ? 0.0 : 0.7,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ketuk untuk melihat info',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
