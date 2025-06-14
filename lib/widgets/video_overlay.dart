import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/user.dart';
import 'package:intl/intl.dart';

class VideoOverlay extends StatefulWidget {
  final EdukasiModel content;
  final VoidCallback onClose;
  final Function(int) onViewsChanged;
  final Function(int, bool) onLikesChanged;
  final bool initialLikedState;
  final UserModel? currentUser;

  const VideoOverlay({
    Key? key,
    required this.content,
    required this.onClose,
    required this.onViewsChanged,
    required this.onLikesChanged,
    required this.initialLikedState,
    this.currentUser,
  }) : super(key: key);

  @override
  State<VideoOverlay> createState() => _VideoOverlayState();
}

class _VideoOverlayState extends State<VideoOverlay>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLiked = false;
  int _currentViews = 0;
  int _currentLikes = 0;
  AnimationController? _controlsAnimationController;
  AnimationController? _likeAnimationController;

  // Target aspect ratio (9:16)
  static const double targetAspectRatio = 9.0 / 16.0;

  // Check if current user is the owner of this content
  bool get _isOwner {
    return widget.currentUser?.uid == widget.content.sellerId;
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLikedState;
    _currentViews = widget.content.views!;
    _currentLikes = widget.content.likes!;

    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _initializeVideo();
    _incrementViews();
  }

  void _initializeVideo() async {
    if (widget.content.videoUrl != null &&
        widget.content.videoUrl!.isNotEmpty) {
      try {
        _videoController = VideoPlayerController.network(
          widget.content.videoUrl!,
        );
        await _videoController!.initialize();

        setState(() {
          _isVideoInitialized = true;
        });

        _videoController!.addListener(_videoListener);
      } catch (e) {
        print('Error initializing video: $e');
      }
    }
  }

  void _videoListener() {
    if (_videoController != null) {
      setState(() {
        _isPlaying = _videoController!.value.isPlaying;
      });
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

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _controlsAnimationController!.forward();
      // Auto hide controls after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
          _controlsAnimationController!.reverse();
        }
      });
    } else {
      _controlsAnimationController!.reverse();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        color: Colors.black,
        child: widget.content.imageUrl != null
            ? Image.network(
                widget.content.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  );
                },
              )
            : const Center(
                child: CircularProgressIndicator(color: Color(0xFF4DA8DA)),
              ),
      );
    }

    final videoAspectRatio = _videoController!.value.aspectRatio;

    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: videoAspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _controlsAnimationController?.dispose();
    _likeAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
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

            // Video Player with 9:16 aspect ratio
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: targetAspectRatio,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // Video Container with black background
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GestureDetector(
                              onTap: _toggleControls,
                              child: _buildVideoPlayer(),
                            ),
                          ),
                        ),

                        // Play/Pause Button - Centered
                        if (_isVideoInitialized && _videoController != null)
                          Center(
                            child: AnimatedBuilder(
                              animation: _controlsAnimationController!,
                              builder: (context, child) {
                                return AnimatedOpacity(
                                  opacity: _showControls ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Video Controls Overlay (Progress Bar)
                        if (_isVideoInitialized && _videoController != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: AnimatedBuilder(
                              animation: _controlsAnimationController!,
                              builder: (context, child) {
                                return AnimatedOpacity(
                                  opacity: _showControls ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        VideoProgressIndicator(
                                          _videoController!,
                                          allowScrubbing: true,
                                          colors: const VideoProgressColors(
                                            playedColor: Color(0xFF4DA8DA),
                                            bufferedColor: Colors.white38,
                                            backgroundColor: Colors.white24,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(
                                                _videoController!
                                                    .value
                                                    .position,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(
                                                _videoController!
                                                    .value
                                                    .duration,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content Info
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  widget.content.namaToko,
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
                                      borderRadius: BorderRadius.circular(8),
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
                                  1.0 + (_likeAnimationController!.value * 0.2),
                              child: GestureDetector(
                                onTap: _toggleLike,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isLiked ? Colors.red : Colors.white,
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
                      Icon(Icons.visibility, color: Colors.white70, size: 16),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
