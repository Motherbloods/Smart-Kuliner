import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/models/notifikasi.dart';
import 'package:smart/providers/auth_provider.dart';
import 'package:smart/services/notification_service.dart';
import 'package:smart/services/order_service.dart';
import 'notification_tile.dart';

class NotificationBottomSheet {
  static void show({
    required BuildContext context,
    required NotificationService notificationService,
    required OrderService orderService,
    required void Function(String orderId) onNavigateToOrderDetails,
  }) {
    final authProvider = context.read<MyAuthProvider>();
    if (authProvider.currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationSheetContent(
        notificationService: notificationService,
        orderService: orderService,
        userId: authProvider.currentUser!.uid,
        onNavigateToOrderDetails: onNavigateToOrderDetails,
      ),
    );
  }
}

class _NotificationSheetContent extends StatefulWidget {
  final NotificationService notificationService;
  final OrderService orderService;
  final String userId;
  final void Function(String orderId) onNavigateToOrderDetails;

  const _NotificationSheetContent({
    required this.notificationService,
    required this.orderService,
    required this.userId,
    required this.onNavigateToOrderDetails,
  });

  @override
  State<_NotificationSheetContent> createState() =>
      _NotificationSheetContentState();
}

class _NotificationSheetContentState extends State<_NotificationSheetContent> {
  int _unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    if (_unreadCount > 0)
                      TextButton(
                        onPressed: () =>
                            _markAllNotificationsAsRead(widget.userId),
                        child: const Text('Tandai Semua Dibaca'),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Notifications list
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: widget.notificationService.getUserNotifications(
                widget.userId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final notifications = snapshot.data ?? [];
                _unreadCount = notifications.where((n) => !n.isRead).length;

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada notifikasi',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return NotificationTile(
                      notification: notification,
                      notificationService: widget.notificationService,
                      onNavigateToOrderDetails: widget.onNavigateToOrderDetails,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _markAllNotificationsAsRead(String userId) {
    widget.notificationService.markAllNotificationsAsRead(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi telah ditandai sebagai dibaca'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
