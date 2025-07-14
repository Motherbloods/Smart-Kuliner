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

  // Initialize deeplink listener
  void initialize(BuildContext context) {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeeplink(context, uri);
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
        _handleDeeplink(context, initialUri);
      }
    } catch (e) {
      print('Error handling initial deeplink: $e');
    }
  }

  // Handle deeplink logic
  Future<void> _handleDeeplink(BuildContext context, Uri uri) async {
    print('🔗 Deeplink received: $uri');
    print('🔍 URI toString: ${uri.toString()}');
    print('🔍 URI scheme: ${uri.scheme}');
    print('🔍 URI host: ${uri.host}');
    print('🔍 URI path: ${uri.path}');
    print('🔍 URI query: ${uri.query}');
    print('🔍 URI fragment: ${uri.fragment}');
    print('🔍 Query parameters: ${uri.queryParameters}');

    // Try manual parsing as fallback
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

    try {
      // Check if it's a checkout deeplink
      if (uri.scheme == 'smartapp' && uri.host == 'checkout') {
        await _handleCheckoutDeeplink(context, uri);
      }
    } catch (e) {
      print('Error handling deeplink: $e');
      _showErrorSnackbar(context, 'Gagal memproses deeplink: $e');
    }
  }

  // Handle checkout deeplink specifically
  Future<void> _handleCheckoutDeeplink(BuildContext context, Uri uri) async {
    // Remove the problematic double-decoding line
    // uri = Uri.parse(Uri.decodeFull(uri.toString()));

    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    print('🧑‍💼 Current user ID: ${authProvider.currentUser?.uid}');

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      _showErrorSnackbar(context, 'Silakan login terlebih dahulu');
      return;
    }

    // Parse query parameters - with fallback manual parsing
    String? productId = uri.queryParameters['productId'];
    String? qtyStr = uri.queryParameters['qty'];
    String? userId = uri.queryParameters['userId'];

    // Fallback: Manual parsing if queryParameters is incomplete
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
    print('🔍 All query parameters: ${uri.queryParameters}');

    // Validate parameters
    if (productId == null || productId.isEmpty) {
      _showErrorSnackbar(context, 'Product ID tidak valid');
      return;
    }

    if (userId == null || userId.isEmpty) {
      _showErrorSnackbar(context, 'User ID tidak valid');
      return;
    }

    // Check if user ID matches current user
    final currentUserId = authProvider.currentUser?.uid;
    print('🔍 Current user ID: "$currentUserId"');
    print('🔍 Deeplink user ID: "$userId"');
    print(
      '🔍 User ID length - Current: ${currentUserId?.length}, Deeplink: ${userId?.length}',
    );
    print('🔍 Are they equal? ${currentUserId == userId}');

    // Debug: Check character by character if they're different
    if (currentUserId != userId && currentUserId != null && userId != null) {
      print('🔍 Character comparison:');
      final minLength = currentUserId.length < userId.length
          ? currentUserId.length
          : userId.length;
      for (int i = 0; i < minLength; i++) {
        if (currentUserId[i] != userId[i]) {
          print(
            '  - Difference at position $i: "${currentUserId[i]}" vs "${userId[i]}"',
          );
          print(
            '  - ASCII codes: ${currentUserId.codeUnitAt(i)} vs ${userId.codeUnitAt(i)}',
          );
        }
      }
    }

    if (currentUserId != userId) {
      _showErrorSnackbar(context, 'Deeplink tidak valid untuk user ini');
      return;
    }

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

    try {
      // Get product details
      final productService = ProductService();
      final product = await productService.getProduct(productId);

      if (product == null) {
        _showErrorSnackbar(context, 'Produk tidak ditemukan');
        return;
      }

      // Add to cart
      cartProvider.addItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        sellerId: product.sellerId,
        nameToko: product.nameToko,
        quantity: quantity,
      );

      // Navigate to checkout
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const CheckoutScreen()));

      // Show success message
      _showSuccessSnackbar(
        context,
        'Produk ${product.name} (${quantity}x) ditambahkan ke keranjang',
      );
    } catch (e) {
      print('Error processing product: $e');
      _showErrorSnackbar(context, 'Gagal memproses produk: $e');
    }
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
