import 'package:flutter/material.dart';
import 'package:smart/models/notifikasi.dart';
import 'package:smart/services/notification_service.dart';

class NotificationUtils {
  static Future<void> deleteNotification({
    required BuildContext context,
    required NotificationService service,
    required NotificationModel notification,
  }) async {
    try {
      await service.deleteNotification(notification.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi berhasil dihapus'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static IconData getNotificationIcon(String type) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_bag;
      case 'order_status_update':
        return Icons.receipt_long;
      case 'promotion':
        return Icons.local_offer;
      case 'payment_success':
        return Icons.payment;
      case 'shipping_update':
        return Icons.local_shipping;
      case 'rating':
        return Icons.star;
      case 'review':
        return Icons.rate_review;
      default:
        return Icons.info;
    }
  }

  static Color getNotificationIconColor(String type) {
    switch (type) {
      case 'new_order':
        return const Color(0xFF4CAF50);
      case 'order_status_update':
        return const Color(0xFF2196F3);
      case 'promotion':
        return const Color(0xFF4DA8DA);
      case 'payment_success':
        return const Color(0xFF9C27B0);
      case 'shipping_update':
        return const Color(0xFF795548);
      case 'rating':
        return const Color(0xFFFFC107);
      case 'review':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF607D8B);
    }
  }

  static String? getActionText(String type) {
    switch (type) {
      case 'new_order':
        return 'Lihat Pesanan';
      case 'order_status_update':
        return 'Lacak Pesanan';
      case 'promotion':
        return 'Lihat Promosi';
      case 'rating':
        return 'Beri Rating';
      default:
        return null;
    }
  }

  static String formatTime(String isoString) {
    try {
      DateTime dateTime = DateTime.parse(isoString);
      DateTime now = DateTime.now();
      Duration difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else {
        return '${(difference.inDays / 7).floor()} minggu yang lalu';
      }
    } catch (e) {
      return 'Waktu tidak valid';
    }
  }
}
