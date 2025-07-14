import 'package:flutter/foundation.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final String sellerId;
  final String nameToko;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    required this.nameToko,
    required this.quantity,
  });

  double get totalPrice => price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount {
    return _items.length;
  }

  int get totalQuantity {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  bool addItem({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    required String sellerId,
    required String nameToko,
    required int quantity,
  }) {
    try {
      if (quantity <= 0) {
        print('❌ Invalid quantity: $quantity');
        return false;
      }

      if (_items.containsKey(productId)) {
        // Jika produk sudah ada, tambah quantity
        _items.update(
          productId,
          (existingCartItem) => CartItem(
            productId: existingCartItem.productId,
            name: existingCartItem.name,
            price: existingCartItem.price,
            imageUrl: existingCartItem.imageUrl,
            sellerId: existingCartItem.sellerId,
            nameToko: existingCartItem.nameToko,
            quantity: existingCartItem.quantity + quantity,
          ),
        );
        print('✅ Updated quantity for product: $name');
      } else {
        // Jika produk belum ada, tambah item baru
        _items.putIfAbsent(
          productId,
          () => CartItem(
            productId: productId,
            name: name,
            price: price,
            imageUrl: imageUrl,
            sellerId: sellerId,
            nameToko: nameToko,
            quantity: quantity,
          ),
        );
        print('✅ Added new product to cart: $name');
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error adding item to cart: $e');
      return false;
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (_items.containsKey(productId)) {
      if (newQuantity <= 0) {
        removeItem(productId);
      } else {
        _items.update(
          productId,
          (existingCartItem) => CartItem(
            productId: existingCartItem.productId,
            name: existingCartItem.name,
            price: existingCartItem.price,
            imageUrl: existingCartItem.imageUrl,
            sellerId: existingCartItem.sellerId,
            nameToko: existingCartItem.nameToko,
            quantity: newQuantity,
          ),
        );
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  int getQuantityById(String productId) {
    return _items.containsKey(productId) ? _items[productId]!.quantity : 0;
  }
}
