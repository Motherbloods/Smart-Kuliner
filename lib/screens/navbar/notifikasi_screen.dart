import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/screens/pesanan_saya_screen.dart';
import 'package:smart/widgets/notification/empty_state_widget.dart';
import 'package:smart/utils/notification_utils.dart';
import 'package:smart/widgets/notification/clear_all_dialog.dart';
import 'package:smart/widgets/notification/mark_all_as_read_dialog.dart';
import 'package:smart/widgets/notification/notification_details_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../models/notifikasi.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({Key? key}) : super(key: key);

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  final OrderService _orderService = OrderService();

  String? currentUserId;
  Stream<List<NotificationModel>>? notificationsStream;
  Stream<int>? unreadCountStream;

  // Add loading and error states
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationModel> _cachedNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId != null) {
        // Create streams
        notificationsStream = _notificationService.getUserNotifications(
          currentUserId!,
        );
        unreadCountStream = _notificationService.getUnreadNotificationCount(
          currentUserId!,
        );

        // Listen to the first emission to cache data and handle initial loading
        notificationsStream!.first
            .then((notifications) {
              if (mounted) {
                setState(() {
                  _cachedNotifications = notifications;
                  _isLoading = false;
                });
              }
            })
            .catchError((error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = error.toString();
                });
              }
            });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User tidak ditemukan';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        final isSeller = authProvider.currentUser?.seller ?? false;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                // Unread count badge
                StreamBuilder<int>(
                  stream: unreadCountStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data! > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4DA8DA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.mark_chat_read_outlined,
                  color: Colors.black54,
                ),
                onPressed: () {
                  _showMarkAllAsReadDialog();
                },
                tooltip: 'Tandai semua sudah dibaca',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                onSelected: (value) {
                  switch (value) {
                    case 'clear_all':
                      _showClearAllDialog();
                      break;
                    case 'refresh':
                      _initializeNotifications();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus Semua'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4DA8DA),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF4DA8DA),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Transaksi'),
                Tab(text: 'Promosi'),
              ],
            ),
          ),
          body: currentUserId == null
              ? const Center(child: Text('Silakan login terlebih dahulu'))
              : _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    // Show initial loading
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat notifikasi...'),
          ],
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Terjadi kesalahan: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _initializeNotifications();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Show tabs with data
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllNotifications(),
        _buildTransactionNotifications(),
        _buildPromotionNotifications(),
      ],
    );
  }

  Widget _buildAllNotifications() {
    return StreamBuilder<List<NotificationModel>>(
      stream: notificationsStream,
      initialData: _cachedNotifications, // Use cached data as initial
      builder: (context, snapshot) {
        // Use cached data while waiting for new data
        final notifications = snapshot.data ?? _cachedNotifications;

        if (notifications.isEmpty) {
          return const EmptyStateWidget(message: 'Belum ada notifikasi');
        }

        return RefreshIndicator(
          onRefresh: () async {
            _initializeNotifications();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionNotifications() {
    return StreamBuilder<List<NotificationModel>>(
      stream: notificationsStream,
      initialData: _cachedNotifications, // Use cached data as initial
      builder: (context, snapshot) {
        final allNotifications = snapshot.data ?? _cachedNotifications;
        final transactionNotifications = allNotifications
            .where(
              (n) => [
                'new_order',
                'order_status_update',
                'payment_success',
                'shipping_update',
              ].contains(n.type),
            )
            .toList();

        if (transactionNotifications.isEmpty) {
          return const EmptyStateWidget(
            message: 'Belum ada notifikasi transaksi',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _initializeNotifications();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactionNotifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(transactionNotifications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPromotionNotifications() {
    return StreamBuilder<List<NotificationModel>>(
      stream: notificationsStream,
      initialData: _cachedNotifications, // Use cached data as initial
      builder: (context, snapshot) {
        final allNotifications = snapshot.data ?? _cachedNotifications;
        final promotionNotifications = allNotifications
            .where((n) => n.type == 'promotion')
            .toList();

        if (promotionNotifications.isEmpty) {
          return const EmptyStateWidget(
            message: "Belum ada notifikasi promosi",
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _initializeNotifications();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promotionNotifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(promotionNotifications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFFFF4F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey[200]!
              : const Color(0xFFFFE5DD),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NotificationUtils.getNotificationIconColor(
                    notification.type,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  NotificationUtils.getNotificationIcon(notification.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4DA8DA),
                              shape: BoxShape.circle,
                            ),
                          ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'delete':
                                NotificationUtils.deleteNotification(
                                  context: context,
                                  service: _notificationService,
                                  notification: notification,
                                );
                                break;
                              case 'mark_read':
                                _markAsRead(notification);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (!notification.isRead)
                              const PopupMenuItem(
                                value: 'mark_read',
                                child: Row(
                                  children: [
                                    Icon(Icons.mark_chat_read, size: 16),
                                    SizedBox(width: 8),
                                    Text('Tandai Dibaca'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Hapus'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          NotificationUtils.formatTime(
                            notification.createdAt.toIso8601String(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (NotificationUtils.getActionText(
                              notification.type,
                            ) !=
                            null)
                          TextButton(
                            onPressed: () =>
                                _handleNotificationAction(notification),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PesananSayaScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                NotificationUtils.getActionText(
                                  notification.type,
                                )!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4DA8DA),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mark notification as read
  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await _notificationService.markNotificationAsRead(notification.id);
      } catch (e) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // Handle notification tap
  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    await _markAsRead(notification);

    // Navigate based on notification type
    switch (notification.type) {
      case 'new_order':
      case 'order_status_update':
        if (notification.orderId != null) {
          _navigateToOrderDetails(notification.orderId!);
        }
        break;
      case 'promotion':
        _navigateToPromotions();
        break;
      default:
        // Show notification details dialog
        showDialog(
          context: context,
          builder: (context) =>
              NotificationDetailsDialog(notification: notification),
        );
        break;
    }
  }

  // Handle notification action button
  void _handleNotificationAction(NotificationModel notification) {
    switch (notification.type) {
      case 'new_order':
        if (notification.orderId != null) {
          _navigateToOrderDetails(notification.orderId!);
        }
        break;
      case 'order_status_update':
        if (notification.orderId != null) {
          _navigateToOrderTracking(notification.orderId!);
        }
        break;
      case 'promotion':
        _navigateToPromotions();
        break;
      default:
        break;
    }
  }

  void _showMarkAllAsReadDialog() {
    showDialog(
      context: context,
      builder: (context) => MarkAllAsReadDialog(
        onConfirm: () async {
          if (currentUserId != null) {
            try {
              await _notificationService.markAllNotificationsAsRead(
                currentUserId!,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Semua notifikasi telah ditandai sebagai sudah dibaca',
                    ),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menandai notifikasi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => ClearAllDialog(
        onConfirm: () async {
          if (currentUserId != null) {
            try {
              await _notificationService.clearAllNotifications(currentUserId!);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi berhasil dihapus'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus notifikasi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  // Navigation methods
  void _navigateToOrderDetails(String orderId) {
    // Implement navigation to order details screen
    Navigator.pushNamed(context, '/order-details', arguments: orderId);
  }

  void _navigateToOrderTracking(String orderId) {
    // Implement navigation to order tracking screen
    Navigator.pushNamed(context, '/order-tracking', arguments: orderId);
  }

  void _navigateToPromotions() {
    // Implement navigation to promotions screen
    Navigator.pushNamed(context, '/promotions');
  }
}
