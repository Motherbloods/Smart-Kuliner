import 'package:flutter/material.dart';
import 'package:smart/models/order.dart';
import 'package:smart/services/order_service.dart';
import 'package:smart/utils/order_utils.dart';

class OrderActionHelper {
  static Future<void> confirmOrder({
    required BuildContext context,
    required OrderService orderService,
    required String orderId,
    required VoidCallback onLoading,
    required VoidCallback onComplete,
  }) async {
    onLoading();
    try {
      await orderService.confirmOrder(orderId);
      _showSnackbar(context, 'Pesanan berhasil dikonfirmasi', Colors.green);
    } catch (e) {
      _showSnackbar(context, 'Gagal mengkonfirmasi pesanan: $e', Colors.red);
    } finally {
      onComplete();
    }
  }

  static Future<void> updateOrderStatus({
    required BuildContext context,
    required OrderService orderService,
    required String orderId,
    required OrderStatus status,
    required VoidCallback onLoading,
    required VoidCallback onComplete,
  }) async {
    onLoading();
    try {
      await orderService.updateOrderStatus(orderId, status);
      _showSnackbar(
        context,
        'Status pesanan diperbarui ke "${OrderUtils.getStatusText(status)}"',
        Colors.green,
      );
    } catch (e) {
      _showSnackbar(context, 'Gagal memperbarui status: $e', Colors.red);
    } finally {
      onComplete();
    }
  }

  static Future<void> completeOrder({
    required BuildContext context,
    required OrderService orderService,
    required String orderId,
    required VoidCallback onLoading,
    required VoidCallback onComplete,
  }) async {
    onLoading();
    try {
      await orderService.completeOrder(orderId);
      _showSnackbar(context, 'Pesanan berhasil diselesaikan', Colors.green);
    } catch (e) {
      _showSnackbar(context, 'Gagal menyelesaikan pesanan: $e', Colors.red);
    } finally {
      onComplete();
    }
  }

  static Future<void> cancelOrder({
    required BuildContext context,
    required OrderService orderService,
    required String orderId,
    required VoidCallback onLoading,
    required VoidCallback onComplete,
  }) async {
    onLoading();
    try {
      await orderService.cancelOrder(orderId, 'Dibatalkan oleh pembeli');
      _showSnackbar(context, 'Pesanan berhasil dibatalkan', Colors.orange);
    } catch (e) {
      _showSnackbar(context, 'Gagal membatalkan pesanan: $e', Colors.red);
    } finally {
      onComplete();
    }
  }

  static void _showSnackbar(BuildContext context, String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }
}
