enum OrderStatus {
  pending,
  confirmed,
  preparing,
  shipping,
  delivered,
  cancelled,
  processing,
  shipped,
  completed,
}

class OrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerEmail;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String paymentMethod;
  final String shippingAddress;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  final double? latitude;
  final double? longitude;

  // Timestamp tambahan
  final DateTime? confirmedAt;
  final DateTime? processedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.processedAt,
    this.shippedAt,
    this.deliveredAt,
    this.completedAt,
    this.cancelledAt,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      items: List<OrderItem>.from(
        map['items']?.map((item) => OrderItem.fromMap(item)) ?? [],
      ),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
      notes: map['notes'] ?? '',
      latitude: map['latitude'] ?? '',
      longitude: map['longitude'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      confirmedAt: map['confirmedAt'] != null
          ? DateTime.parse(map['confirmedAt'])
          : null,
      processedAt: map['processedAt'] != null
          ? DateTime.parse(map['processedAt'])
          : null,
      shippedAt: map['shippedAt'] != null
          ? DateTime.parse(map['shippedAt'])
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.parse(map['cancelledAt'])
          : null,
    );
  }
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu Konfirmasi';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.preparing:
        return 'Sedang Dipersiapkan';
      case OrderStatus.processing:
        return 'Sedang Diproses';
      case OrderStatus.shipping:
        return 'Sedang Dikirim';
      case OrderStatus.shipped:
        return 'Telah Dikirim';
      case OrderStatus.delivered:
        return 'Diterima';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
      case OrderStatus.completed:
        return 'Selesai';
    }
  }

  String get orderNumber {
    return 'ORDER-${id.substring(0, 8).toUpperCase()}';
  }

  // Group items by seller
  Map<String, List<OrderItem>> get itemsBySeller {
    Map<String, List<OrderItem>> grouped = {};
    for (var item in items) {
      if (!grouped.containsKey(item.sellerId)) {
        grouped[item.sellerId] = [];
      }
      grouped[item.sellerId]!.add(item);
    }
    return grouped;
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }

  double get totalPrice => price * quantity;
}
