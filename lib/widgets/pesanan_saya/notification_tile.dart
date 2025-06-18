import 'package:flutter/material.dart';
import 'package:smart/models/notifikasi.dart';
import 'package:smart/services/notification_service.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationService notificationService;
  final void Function(String orderId) onNavigateToOrderDetails;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.notificationService,
    required this.onNavigateToOrderDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.shade200
              : Colors.blue.shade200,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getNotificationIconColor(notification.type),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            notificationService.markNotificationAsRead(notification.id);
          }

          if (notification.orderId != null) {
            Navigator.pop(context);
            onNavigateToOrderDetails(notification.orderId!);
          }
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                notificationService.markNotificationAsRead(notification.id);
                break;
              case 'delete':
                notificationService.deleteNotification(notification.id);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Text('Tandai Dibaca'),
              ),
            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'order_status_update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationIconColor(String type) {
    switch (type) {
      case 'new_order':
        return Colors.green;
      case 'order_status_update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    // Contoh format manual, bisa diganti dengan intl package jika perlu
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
