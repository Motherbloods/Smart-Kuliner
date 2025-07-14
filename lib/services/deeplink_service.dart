// deeplink_service.dart - Fixed duplicate detection logic
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/screens/checkout_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';

class DeeplinkService {
  static final DeeplinkService _instance = DeeplinkService._internal();
  factory DeeplinkService() => _instance;
  DeeplinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Untuk mencegah double processing
  bool _isProcessingDeeplink = false;
  Uri? _lastProcessedUri;
  DateTime? _lastProcessedTime;

  // Untuk mencegah navigation overlap
  bool _isNavigating = false;

  // IMPROVED: Tracking processed URIs with timestamps for better duplicate detection
  final Map<String, DateTime> _processedUris = <String, DateTime>{};

  // Initialize deeplink listener
  void initialize(BuildContext context) {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Stream deeplink received: $uri');
        _handleDeeplink(context, uri, source: 'stream');
      },
      onError: (err) {
        print('DeeplinkService Error: $err');
      },
    );
  }

  // Handle initial deeplink when app is opened
  Future<void> handleInitialLink(BuildContext context) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('🔗 Initial deeplink detected: $initialUri');

        // Add delay to ensure app is fully loaded
        await Future.delayed(const Duration(milliseconds: 1000));

        await _handleDeeplink(context, initialUri, source: 'initial');
      }
    } catch (e) {
      print('Error handling initial deeplink: $e');
    }
  }

  // IMPROVED: Handle deeplink dengan better duplicate detection
  Future<void> _handleDeeplink(
    BuildContext context,
    Uri uri, {
    required String source,
  }) async {
    final uriString = uri.toString();
    print('🔗 Deeplink received from $source: $uri');

    // Clean up old processed URIs first
    _cleanupOldProcessedUris();

    // Check if this URI was processed very recently (within 3 seconds)
    if (_isDuplicateUri(uri)) {
      print('⚠️ Duplicate deeplink detected (within 3 seconds), ignoring...');
      return;
    }

    // Prevent multiple simultaneous deeplink processing
    if (_isProcessingDeeplink) {
      print('⏳ Already processing deeplink, ignoring duplicate...');
      return;
    }

    // Mark this URI as being processed
    _processedUris[uriString] = DateTime.now();
    _lastProcessedUri = uri;
    _lastProcessedTime = DateTime.now();

    _isProcessingDeeplink = true;

    try {
      // Debugging info
      _printDeeplinkInfo(uri);

      // Check if it's a checkout deeplink
      if (uri.scheme == 'smartapp' && uri.host == 'checkout') {
        await _handleCheckoutDeeplink(context, uri);
      }
    } catch (e) {
      print('Error handling deeplink: $e');
      _showErrorSnackbar(context, 'Gagal memproses deeplink: $e');
    } finally {
      _isProcessingDeeplink = false;
    }
  }

  // IMPROVED: Better duplicate detection - only consider recent duplicates
  bool _isDuplicateUri(Uri uri) {
    final uriString = uri.toString();
    final now = DateTime.now();

    // Check if this URI was processed within the last 3 seconds
    if (_processedUris.containsKey(uriString)) {
      final processedTime = _processedUris[uriString]!;
      final timeDifference = now.difference(processedTime).inSeconds;

      print('🔍 URI "$uriString" was processed ${timeDifference}s ago');

      // Only consider as duplicate if processed within 3 seconds
      if (timeDifference < 3) {
        return true;
      } else {
        print(
          '✅ URI is old enough (${timeDifference}s), allowing reprocessing',
        );
        // Remove the old entry since it's no longer considered a duplicate
        _processedUris.remove(uriString);
        return false;
      }
    }

    return false;
  }

  // IMPROVED: Clean up old processed URIs (older than 10 seconds)
  void _cleanupOldProcessedUris() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _processedUris.forEach((uri, timestamp) {
      if (now.difference(timestamp).inSeconds > 10) {
        keysToRemove.add(uri);
      }
    });

    for (final key in keysToRemove) {
      _processedUris.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      print('🧹 Cleaned up ${keysToRemove.length} old processed URIs');
    }
  }

  // Print debugging info
  void _printDeeplinkInfo(Uri uri) {
    print('🔍 URI toString: ${uri.toString()}');
    print('🔍 URI scheme: ${uri.scheme}');
    print('🔍 URI host: ${uri.host}');
    print('🔍 URI path: ${uri.path}');
    print('🔍 URI query: ${uri.query}');
    print('🔍 URI fragment: ${uri.fragment}');
    print('🔍 Query parameters: ${uri.queryParameters}');

    // Manual parsing untuk debugging
    if (uri.query.isNotEmpty) {
      print('🔍 Manual query parsing:');
      final queryParts = uri.query.split('&');
      for (final part in queryParts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          print('  - ${keyValue[0]}: ${keyValue[1]}');
        }
      }
    }
  }

  // IMPROVED: Faster auth state checking like original code
  Future<bool> _waitForAuthState(
    BuildContext context, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

    print('⏳ Checking auth state...');
    print(
      '🔍 Current state - isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}',
    );

    // If already authenticated and not loading, return immediately
    if (!authProvider.isLoading && authProvider.isAuthenticated) {
      print('✅ Already authenticated, proceeding immediately');
      return true;
    }

    // If not loading and not authenticated, return false immediately
    if (!authProvider.isLoading && !authProvider.isAuthenticated) {
      print('❌ Not authenticated and not loading, returning false');
      return false;
    }

    // If still loading, wait briefly with shorter intervals
    print('⏳ Auth provider still loading, waiting briefly...');

    int attempts = 0;
    const maxAttempts = 20; // Max 2 seconds (20 * 100ms)

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if auth state has stabilized
      if (!authProvider.isLoading) {
        final isAuthenticated = authProvider.isAuthenticated;
        print(
          '✅ Auth state stabilized after ${attempts * 100}ms - Authenticated: $isAuthenticated',
        );
        return isAuthenticated;
      }

      attempts++;
    }

    // If still loading after 2 seconds, return current state
    print(
      '⏰ Auth state still loading after 2 seconds, returning current state',
    );
    return authProvider.isAuthenticated;
  }

  // IMPROVED: Handle checkout deeplink dengan navigation prevention
  Future<void> _handleCheckoutDeeplink(BuildContext context, Uri uri) async {
    // Prevent multiple navigation attempts
    if (_isNavigating) {
      print('⚠️ Already navigating, ignoring checkout deeplink...');
      return;
    }

    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

    print(
      '🔍 Initial auth state - isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}',
    );
    print('🔍 Current user: ${authProvider.currentUser?.uid}');

    // Show loading immediately
    _showLoadingSnackbar(context, 'Memverifikasi status login...');

    // Parse parameters first
    final params = _parseDeeplinkParams(uri);
    final productId = params['productId'];
    final userId = params['userId'];

    // Basic validation
    if (productId == null || productId.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackbar(context, 'Product ID tidak valid');
      return;
    }

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackbar(context, 'User ID tidak valid');
      return;
    }

    // Wait for auth state to be ready
    final isAuthenticated = await _waitForAuthState(context);

    // Hide loading snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (!isAuthenticated) {
      print('❌ User tidak terautentikasi setelah menunggu auth state');
      _showErrorSnackbar(context, 'Silakan login terlebih dahulu');
      return;
    }

    // Get fresh user data
    final currentUser = authProvider.currentUser;
    final currentUserId = currentUser?.uid;

    print('✅ User terautentikasi - proceeding with deeplink');
    print('🧑‍💼 Current user ID: $currentUserId');
    print('🔗 Deeplink user ID: $userId');

    // Final user ID validation
    if (currentUserId == null || currentUserId != userId) {
      print(
        '❌ User ID mismatch - Current: "$currentUserId", Deeplink: "$userId"',
      );
      _showErrorSnackbar(context, 'Deeplink tidak valid untuk user ini');
      return;
    }

    // Process deeplink
    await _processCheckoutDeeplink(context, params);
  }

  // Parse deeplink parameters
  Map<String, String?> _parseDeeplinkParams(Uri uri) {
    String? productId = uri.queryParameters['productId'];
    String? qtyStr = uri.queryParameters['qty'];
    String? userId = uri.queryParameters['userId'];

    // Fallback: Manual parsing jika queryParameters incomplete
    if (uri.query.isNotEmpty &&
        (productId == null || qtyStr == null || userId == null)) {
      print('🔄 Using manual parsing as fallback...');
      final Map<String, String> manualParams = {};
      final queryParts = uri.query.split('&');
      for (final part in queryParts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          manualParams[keyValue[0]] = Uri.decodeComponent(keyValue[1]);
        }
      }

      productId ??= manualParams['productId'];
      qtyStr ??= manualParams['qty'];
      userId ??= manualParams['userId'];

      print('🔄 Manual parsed params: $manualParams');
    }

    print('✅ Parsed productId: $productId');
    print('🔢 Parsed qty: $qtyStr');
    print('🆔 Parsed userId from deeplink: $userId');

    return {'productId': productId, 'qty': qtyStr, 'userId': userId};
  }

  // IMPROVED: Process checkout deeplink dengan navigation guard
  Future<void> _processCheckoutDeeplink(
    BuildContext context,
    Map<String, String?> params,
  ) async {
    // Set navigation flag
    _isNavigating = true;

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final productId = params['productId']!;
      final qtyStr = params['qty'];

      // Parse quantity
      int quantity = 1;
      try {
        quantity = int.parse(qtyStr ?? '1');
        if (quantity <= 0) quantity = 1;
      } catch (e) {
        print('Invalid quantity format, using default: 1');
      }

      print('📦 Final quantity: $quantity');

      // Show loading
      _showLoadingSnackbar(context, 'Memproses produk...');

      // Get product details
      final productService = ProductService();
      final product = await productService.getProduct(productId);

      // Hide loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (product == null) {
        _showErrorSnackbar(context, 'Produk tidak ditemukan');
        return;
      }

      // Add to cart
      final addToCartSuccess = cartProvider.addItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        sellerId: product.sellerId,
        nameToko: product.nameToko,
        quantity: quantity,
      );

      if (!addToCartSuccess) {
        _showErrorSnackbar(context, 'Gagal menambahkan produk ke keranjang');
        return;
      }

      // Check if already on checkout screen
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute == '/checkout' ||
          context.widget.runtimeType.toString().contains('CheckoutScreen')) {
        print('⚠️ Already on checkout screen, skipping navigation');
        _showSuccessSnackbar(
          context,
          'Produk ${product.name} (${quantity}x) ditambahkan ke keranjang',
        );
        return;
      }

      // Navigate to checkout with proper error handling
      try {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CheckoutScreen(),
            settings: const RouteSettings(name: '/checkout'),
          ),
        );
      } catch (navError) {
        print('❌ Navigation error: $navError');
        _showErrorSnackbar(context, 'Gagal membuka halaman checkout');
        return;
      }

      // Show success message
      _showSuccessSnackbar(
        context,
        'Produk ${product.name} (${quantity}x) ditambahkan ke keranjang',
      );
    } catch (e) {
      print('Error processing product: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackbar(context, 'Gagal memproses produk: $e');
    } finally {
      // Reset navigation flag after a delay
      Timer(const Duration(milliseconds: 1000), () {
        _isNavigating = false;
      });
    }
  }

  // ADDED: Method to manually clear processed URIs (useful for testing)
  void clearProcessedUris() {
    _processedUris.clear();
    print('🧹 Manually cleared all processed URIs');
  }

  // Helper methods for showing snackbars
  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLoadingSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 10),
      ),
    );
  }

  // Enhanced dispose with cleanup
  void dispose() {
    _linkSubscription?.cancel();
    _processedUris.clear();
    _isProcessingDeeplink = false;
    _isNavigating = false;
    _lastProcessedUri = null;
    _lastProcessedTime = null;
  }
}
