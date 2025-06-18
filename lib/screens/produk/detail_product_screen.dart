// screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:smart/models/product.dart';
import 'package:smart/models/review.dart';
import 'package:smart/providers/cart_provider.dart';
import 'package:smart/screens/cart_screen.dart';
import 'package:smart/screens/seller_detail_screen.dart';
import 'package:smart/services/review_service.dart';
import 'package:smart/widgets/review/review_item.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  int _quantity = 1;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  // Review Service
  final ReviewService _reviewService = ReviewService();
  Map<String, dynamic>? _reviewStats;

  // Animation controllers
  late AnimationController _flyingAnimationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _fadeAnimationController;

  late Animation<double> _flyingAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showFlyingCart = false;
  Offset _startPosition = Offset.zero;
  Offset _endPosition = Offset.zero;

  // Global key untuk cart icon
  final GlobalKey _cartIconKey = GlobalKey();
  final GlobalKey _addToCartButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadReviewStats();

    // Initialize animation controllers
    _flyingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
    _flyingAnimation = CurvedAnimation(
      parent: _flyingAnimationController,
      curve: Curves.easeInOutQuart,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _flyingAnimationController.dispose();
    _scaleAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  // Load review statistics
  Future<void> _loadReviewStats() async {
    try {
      final stats = await _reviewService.getReviewStatistics(
        widget.product.id ?? '',
      );
      if (mounted) {
        setState(() {
          _reviewStats = stats;
        });
      }
    } catch (e) {
      print('Error loading review stats: $e');
    }
  }

  // Get widget position
  Offset _getWidgetPosition(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  }

  // Start flying animation
  void _startFlyingAnimation() {
    setState(() {
      _showFlyingCart = true;
      _startPosition = _getWidgetPosition(_addToCartButtonKey);
      _endPosition = _getWidgetPosition(_cartIconKey);
    });

    // Start all animations
    _flyingAnimationController.forward();
    _scaleAnimationController.forward();
    _fadeAnimationController.forward();

    // Hide flying cart after animation completes
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showFlyingCart = false;
        });
        // Reset animations
        _flyingAnimationController.reset();
        _scaleAnimationController.reset();
        _fadeAnimationController.reset();
      }
    });
  }

  // Fungsi untuk menambah produk ke keranjang dengan animasi
  void _addToCart() {
    if (widget.product.stock > 0) {
      // Start animation first
      _startFlyingAnimation();

      // Add to cart after a small delay
      Future.delayed(const Duration(milliseconds: 100), () {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);

        cartProvider.addItem(
          productId: widget.product.id ?? '',
          name: widget.product.name,
          price: widget.product.price,
          imageUrl: widget.product.imageUrls.isNotEmpty
              ? widget.product.imageUrls.first
              : '',
          sellerId: widget.product.sellerId,
          nameToko: widget.product.nameToko,
          quantity: _quantity,
        );

        // Reset quantity ke 1 setelah berhasil menambah ke cart
        setState(() {
          _quantity = 1;
        });
      });
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartScreen()),
    );
  }

  // Build review summary widget
  Widget _buildReviewSummary() {
    if (_reviewStats == null) {
      return const SizedBox.shrink();
    }

    final totalReviews = _reviewStats!['totalReviews'] as int;
    final averageRating = _reviewStats!['averageRating'] as double;
    final ratingDistribution =
        _reviewStats!['ratingDistribution'] as Map<int, int>;

    if (totalReviews == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Belum ada ulasan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jadilah yang pertama memberikan ulasan',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Overall Rating
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4DA8DA),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 20,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews ulasan',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // Rating Distribution
              Expanded(
                child: Column(
                  children: [
                    for (int i = 5; i >= 1; i--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$i', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: totalReviews > 0
                                    ? (ratingDistribution[i] ?? 0) /
                                          totalReviews
                                    : 0,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4DA8DA),
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${ratingDistribution[i] ?? 0}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar with Image Carousel
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: GestureDetector(
                      key: _cartIconKey, // Add key for position tracking
                      onTap: _navigateToCart,
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          return Stack(
                            children: [
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xFFE53935),
                                      Color(0xFF4DA8DA),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: const Icon(
                                  Icons.shopping_cart,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                              if (cartProvider.itemCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '${cartProvider.itemCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    children: [
                      Expanded(
                        child: widget.product.imageUrls.isNotEmpty
                            ? CarouselSlider(
                                carouselController: _carouselController,
                                options: CarouselOptions(
                                  height: double.infinity,
                                  viewportFraction: 1.0,
                                  enableInfiniteScroll:
                                      widget.product.imageUrls.length > 1,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                ),
                                items: widget.product.imageUrls.map((imageUrl) {
                                  return Container(
                                    width: double.infinity,
                                    color: Colors.white,
                                    alignment: Alignment.center,
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFF4DA8DA)),
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.broken_image,
                                              size: 64,
                                              color: Colors.grey,
                                            );
                                          },
                                    ),
                                  );
                                }).toList(),
                              )
                            : Container(
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      // Image Indicators
                      if (widget.product.imageUrls.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: widget.product.imageUrls
                                .asMap()
                                .entries
                                .map((entry) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == entry.key
                                          ? const Color(0xFF4DA8DA)
                                          : Colors.grey[300],
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Product Information
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 1),
                    ),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Rating and Sold
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 18),
                          const SizedBox(width: 4),
                          Text(
                            widget.product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_reviewStats?['totalReviews'] ?? 0})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${widget.product.sold} Terjual',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Price
                      Text(
                        widget.product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4DA8DA),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Store Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4DA8DA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.nameToko,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Penjual Terpercaya',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SellerDetailScreen(
                                      sellerId: widget.product.sellerId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Section
                      const Text(
                        'Deskripsi Produk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),

                      const SizedBox(height: 24),

                      // Category and Stock Info
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kategori',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.product.category,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stok Tersedia',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.product.stock} pcs',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Reviews Section
                      const Text(
                        'Ulasan Produk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Review Summary
                      _buildReviewSummary(),

                      // Reviews List
                      StreamBuilder<List<ReviewModel>>(
                        stream: _reviewService.getProductReviews(
                          widget.product.id ?? '',
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              ),
                            );
                          }

                          final reviews = snapshot.data ?? [];

                          if (reviews.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Show only first 3 reviews in product detail
                          final displayReviews = reviews.take(3).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reviews List
                              ...displayReviews.map(
                                (review) => ReviewItem(
                                  review: review,
                                  canEdit:
                                      false, // Users can't edit reviews from product detail
                                ),
                              ),

                              // Show More Reviews Button
                              if (reviews.length > 3)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Navigate to all reviews screen
                                        Navigator.pushNamed(
                                          context,
                                          '/product-reviews',
                                          arguments: {
                                            'productId': widget.product.id,
                                            'productName': widget.product.name,
                                          },
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF4DA8DA,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF4DA8DA),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Lihat Semua ${reviews.length} Ulasan',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Flying Cart Animation Overlay
          if (_showFlyingCart)
            AnimatedBuilder(
              animation: _flyingAnimation,
              builder: (context, child) {
                // Calculate the current position based on animation progress
                final currentX =
                    _startPosition.dx +
                    (_endPosition.dx - _startPosition.dx) *
                        _flyingAnimation.value;
                final currentY =
                    _startPosition.dy +
                    (_endPosition.dy - _startPosition.dy) *
                        _flyingAnimation.value;

                return Positioned(
                  left: currentX,
                  top: currentY,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _scaleAnimation,
                      _fadeAnimation,
                    ]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4DA8DA),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4DA8DA,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),

      // Bottom Navigation Bar dengan Fungsi Cart
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        color: _quantity > 1 ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _quantity < widget.product.stock
                            ? () {
                                setState(() {
                                  _quantity++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        color: _quantity < widget.product.stock
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Add to Cart Button dengan Fungsi dan Key
              Expanded(
                child: SizedBox(
                  key: _addToCartButtonKey, // Add key for position tracking
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: widget.product.stock > 0 ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.product.stock > 0
                          ? const Color(0xFF4DA8DA)
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: Text(
                      widget.product.stock > 0
                          ? 'Tambah ke Keranjang'
                          : 'Stok Habis',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
