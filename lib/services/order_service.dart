// services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Create new order
  Future<String> createOrder(OrderModel order) async {
    try {
      // Add order to Firestore
      DocumentReference docRef = await _firestore
          .collection('orders')
          .add(order.toMap());

      print('✅ Order created successfully with ID: ${docRef.id}');

      // Send notification to sellers
      await _sendOrderNotificationToSellers(order, docRef.id);

      return docRef.id;
    } catch (e) {
      print('❌ Error creating order: $e');
      throw 'Gagal membuat pesanan: $e';
    }
  }

  // Get orders for buyer
  Stream<List<OrderModel>> getBuyerOrders(String buyerId) {
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get orders for seller
  Stream<List<OrderModel>> getSellerOrders(String sellerId) {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          List<OrderModel> sellerOrders = [];

          for (var doc in snapshot.docs) {
            try {
              final order = OrderModel.fromMap(doc.data(), doc.id);

              // Filter items for this seller
              final sellerItems = order.items
                  .where((item) => item.sellerId == sellerId)
                  .toList();

              // Only include orders that have items for this seller
              if (sellerItems.isNotEmpty) {
                final sellerOrder = OrderModel(
                  id: order.id,
                  buyerId: order.buyerId,
                  buyerName: order.buyerName,
                  buyerEmail: order.buyerEmail,
                  items: sellerItems,
                  totalAmount: sellerItems.fold(
                    0,
                    (sum, item) => sum + item.totalPrice,
                  ),
                  status: order.status,
                  paymentMethod: order.paymentMethod,
                  shippingAddress: order.shippingAddress,
                  notes: order.notes,
                  createdAt: order.createdAt,
                  updatedAt: order.updatedAt,
                );

                sellerOrders.add(sellerOrder);

                // Debug print
                print(
                  '✅ Found order for seller $sellerId: ${order.id} - Status: ${order.status.name}',
                );
              }
            } catch (e) {
              print('❌ Error processing order ${doc.id}: $e');
            }
          }

          print(
            '📊 Total orders found for seller $sellerId: ${sellerOrders.length}',
          );
          return sellerOrders;
        });
  }

  // Get single order
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting order: $e');
      return null;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Get order details for notification
      OrderModel? order = await getOrder(orderId);
      if (order != null) {
        await _sendStatusUpdateNotification(order, status);
      }

      print('✅ Order status updated successfully');
    } catch (e) {
      print('❌ Error updating order status: $e');
      throw 'Gagal memperbarui status pesanan: $e';
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.name,
        'cancelReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Order cancelled successfully');
    } catch (e) {
      print('❌ Error cancelling order: $e');
      throw 'Gagal membatalkan pesanan: $e';
    }
  }

  // Send order notification to sellers (melanjutkan kode yang terpotong)
  Future<void> _sendOrderNotificationToSellers(
    OrderModel order,
    String orderId,
  ) async {
    try {
      // Group items by seller
      Map<String, List<OrderItem>> itemsBySeller = {};
      for (var item in order.items) {
        if (!itemsBySeller.containsKey(item.sellerId)) {
          itemsBySeller[item.sellerId] = [];
        }
        itemsBySeller[item.sellerId]!.add(item);
      }

      // Send notification to each seller
      for (var sellerId in itemsBySeller.keys) {
        final sellerItems = itemsBySeller[sellerId]!;
        final totalAmount = sellerItems.fold(
          0.0,
          (sum, item) => sum + item.totalPrice,
        );

        // Send notification to seller
        await _notificationService.sendNotificationToSeller(
          sellerId: sellerId,
          title: '🛒 Pesanan Baru!',
          body:
              'Anda mendapat pesanan baru dari ${order.buyerName} senilai Rp ${totalAmount.toStringAsFixed(0)}',
          data: {
            'type': 'new_order',
            'orderId': orderId,
            'buyerId': order.buyerId,
            'buyerName': order.buyerName,
            'totalAmount': totalAmount.toString(),
          },
        );

        // Save notification to database for seller
        await _saveNotificationToDatabase(
          userId: sellerId,
          title: '🛒 Pesanan Baru!',
          body:
              'Pesanan dari ${order.buyerName} senilai Rp ${totalAmount.toStringAsFixed(0)}',
          type: 'new_order',
          orderId: orderId,
        );

        print('✅ Notification sent to seller: $sellerId');
      }
    } catch (e) {
      print('❌ Error sending notification to sellers: $e');
    }
  }

  // Send status update notification
  Future<void> _sendStatusUpdateNotification(
    OrderModel order,
    OrderStatus status,
  ) async {
    try {
      String title = '';
      String body = '';

      switch (status) {
        case OrderStatus.confirmed:
          title = '✅ Pesanan Dikonfirmasi';
          body = 'Pesanan Anda telah dikonfirmasi oleh penjual';
          break;
        case OrderStatus.processing:
          title = '📦 Pesanan Diproses';
          body = 'Pesanan Anda sedang diproses';
          break;
        case OrderStatus.shipped:
          title = '🚚 Pesanan Dikirim';
          body = 'Pesanan Anda telah dikirim';
          break;
        case OrderStatus.delivered:
          title = '🎉 Pesanan Diterima';
          body = 'Pesanan Anda telah sampai tujuan';
          break;
        case OrderStatus.cancelled:
          title = '❌ Pesanan Dibatalkan';
          body = 'Pesanan Anda telah dibatalkan';
          break;
        case OrderStatus.completed:
          title = '✨ Pesanan Selesai';
          body = 'Pesanan Anda telah selesai';
          break;
        default:
          return;
      }

      // Send notification to buyer
      await _notificationService.sendNotificationToUser(
        userId: order.buyerId,
        title: title,
        body: body,
        data: {
          'type': 'order_status_update',
          'orderId': order.id,
          'status': status.name,
        },
      );

      // Save notification to database for buyer
      await _saveNotificationToDatabase(
        userId: order.buyerId,
        title: title,
        body: body,
        type: 'order_status_update',
        orderId: order.id,
      );

      print('✅ Status update notification sent to buyer: ${order.buyerId}');
    } catch (e) {
      print('❌ Error sending status update notification: $e');
    }
  }

  // Save notification to database
  Future<void> _saveNotificationToDatabase({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'orderId': orderId,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error saving notification to database: $e');
    }
  }

  // Get recent orders for seller dashboard
  Future<List<OrderModel>> getRecentSellerOrders(
    String sellerId, {
    int limit = 5,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where(
            'items',
            arrayContainsAny: [
              {'sellerId': sellerId},
            ],
          )
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      List<OrderModel> orders = [];
      for (var doc in snapshot.docs) {
        final order = OrderModel.fromMap(doc.data(), doc.id);
        // Filter items for this seller only
        final sellerItems = order.items
            .where((item) => item.sellerId == sellerId)
            .toList();
        if (sellerItems.isNotEmpty) {
          orders.add(
            OrderModel(
              id: order.id,
              buyerId: order.buyerId,
              buyerName: order.buyerName,
              buyerEmail: order.buyerEmail,
              items: sellerItems,
              totalAmount: sellerItems.fold(
                0,
                (sum, item) => sum + item.totalPrice,
              ),
              status: order.status,
              paymentMethod: order.paymentMethod,
              shippingAddress: order.shippingAddress,
              notes: order.notes,
              createdAt: order.createdAt,
              updatedAt: order.updatedAt,
            ),
          );
        }
      }

      return orders;
    } catch (e) {
      print('❌ Error getting recent seller orders: $e');
      return [];
    }
  }

  // Mark order as completed (buyer confirms receipt)
  Future<void> completeOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, OrderStatus.completed);
      print('✅ Order marked as completed');
    } catch (e) {
      print('❌ Error completing order: $e');
      throw 'Gagal menyelesaikan pesanan: $e';
    }
  }

  // Confirm order (seller confirms)
  Future<void> confirmOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, OrderStatus.confirmed);
      print('✅ Order confirmed by seller');
    } catch (e) {
      print('❌ Error confirming order: $e');
      throw 'Gagal mengkonfirmasi pesanan: $e';
    }
  }
}
