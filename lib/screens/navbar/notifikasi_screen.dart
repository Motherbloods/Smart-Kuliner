import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({Key? key}) : super(key: key);

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            title: const Text(
              'Notifikasi',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
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
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAllNotifications(isSeller),
              _buildTransactionNotifications(isSeller),
              _buildPromotionNotifications(isSeller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllNotifications(bool isSeller) {
    final notifications = _getAllNotifications(isSeller);

    if (notifications.isEmpty) {
      return _buildEmptyState('Belum ada notifikasi');
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refresh
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildTransactionNotifications(bool isSeller) {
    final notifications = _getTransactionNotifications(isSeller);

    if (notifications.isEmpty) {
      return _buildEmptyState('Belum ada notifikasi transaksi');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildPromotionNotifications(bool isSeller) {
    final notifications = _getPromotionNotifications(isSeller);

    if (notifications.isEmpty) {
      return _buildEmptyState('Belum ada notifikasi promosi');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
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
        onTap: () {
          setState(() {
            notification.isRead = true;
          });
          _handleNotificationTap(notification);
        },
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
                  color: _getNotificationIconColor(notification.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
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
                          notification.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (notification.actionText != null)
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
                            child: Text(
                              notification.actionText!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4DA8DA),
                                fontWeight: FontWeight.w600,
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showMarkAllAsReadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tandai Semua Sudah Dibaca'),
          content: const Text(
            'Apakah Anda yakin ingin menandai semua notifikasi sebagai sudah dibaca?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Mark all notifications as read
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Semua notifikasi telah ditandai sebagai sudah dibaca',
                    ),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.purchase:
        return Icons.shopping_bag;
      case NotificationType.rating:
        return Icons.star;
      case NotificationType.order:
        return Icons.receipt_long;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.shipping:
        return Icons.local_shipping;
      case NotificationType.review:
        return Icons.rate_review;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.purchase:
        return const Color(0xFF4CAF50);
      case NotificationType.rating:
        return const Color(0xFFFFC107);
      case NotificationType.order:
        return const Color(0xFF2196F3);
      case NotificationType.promotion:
        return const Color(0xFF4DA8DA);
      case NotificationType.payment:
        return const Color(0xFF9C27B0);
      case NotificationType.shipping:
        return const Color(0xFF795548);
      case NotificationType.review:
        return const Color(0xFFE91E63);
      case NotificationType.system:
        return const Color(0xFF607D8B);
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Handle notification tap based on type
    switch (notification.type) {
      case NotificationType.purchase:
      case NotificationType.order:
        // Navigate to order details
        break;
      case NotificationType.rating:
      case NotificationType.review:
        // Navigate to product reviews
        break;
      case NotificationType.promotion:
        // Navigate to promotion details
        break;
      case NotificationType.payment:
        // Navigate to payment details
        break;
      case NotificationType.shipping:
        // Navigate to shipping tracking
        break;
      case NotificationType.system:
        // Show system notification details
        break;
    }
  }

  void _handleNotificationAction(NotificationItem notification) {
    // Handle notification action button
    switch (notification.type) {
      case NotificationType.rating:
        // Navigate to review form
        break;
      case NotificationType.order:
        // Navigate to order tracking
        break;
      case NotificationType.promotion:
        // Navigate to promotion page
        break;
      default:
        break;
    }
  }

  List<NotificationItem> _getAllNotifications(bool isSeller) {
    if (isSeller) {
      return _getSellerNotifications();
    } else {
      return _getBuyerNotifications();
    }
  }

  List<NotificationItem> _getTransactionNotifications(bool isSeller) {
    final allNotifications = _getAllNotifications(isSeller);
    return allNotifications
        .where(
          (n) => [
            NotificationType.purchase,
            NotificationType.order,
            NotificationType.payment,
            NotificationType.shipping,
          ].contains(n.type),
        )
        .toList();
  }

  List<NotificationItem> _getPromotionNotifications(bool isSeller) {
    final allNotifications = _getAllNotifications(isSeller);
    return allNotifications
        .where((n) => n.type == NotificationType.promotion)
        .toList();
  }

  List<NotificationItem> _getSellerNotifications() {
    return [
      NotificationItem(
        id: '1',
        type: NotificationType.purchase,
        title: 'Produk Anda Dibeli!',
        message:
            'Sepatu Nike Air Max telah dibeli oleh John Doe. Total pembelian: Rp 1.200.000',
        time: '2 menit yang lalu',
        isRead: false,
        actionText: 'Lihat Pesanan',
      ),
      NotificationItem(
        id: '2',
        type: NotificationType.rating,
        title: 'Produk Mendapat Rating Baru',
        message:
            'Tas Laptop Anda mendapat rating 5 bintang dari Sarah. "Kualitas sangat bagus dan pengiriman cepat!"',
        time: '1 jam yang lalu',
        isRead: false,
        actionText: 'Lihat Review',
      ),
      NotificationItem(
        id: '3',
        type: NotificationType.order,
        title: 'Pesanan Perlu Diproses',
        message:
            '3 pesanan baru menunggu konfirmasi Anda. Segera proses untuk kepuasan pelanggan.',
        time: '3 jam yang lalu',
        isRead: true,
        actionText: 'Proses Pesanan',
      ),
      NotificationItem(
        id: '4',
        type: NotificationType.promotion,
        title: 'Promosi Berakhir Hari Ini',
        message:
            'Flash Sale untuk Elektronik akan berakhir dalam 6 jam. 12 produk Anda sudah terjual!',
        time: '5 jam yang lalu',
        isRead: true,
        actionText: 'Lihat Promosi',
      ),
      NotificationItem(
        id: '5',
        type: NotificationType.payment,
        title: 'Pembayaran Diterima',
        message:
            'Pembayaran sebesar Rp 850.000 untuk 2 produk telah masuk ke rekening Anda.',
        time: '1 hari yang lalu',
        isRead: true,
      ),
      NotificationItem(
        id: '6',
        type: NotificationType.review,
        title: 'Review Baru dari Pembeli',
        message:
            'Michael memberikan review untuk Headphone Bluetooth Anda dengan rating 4 bintang.',
        time: '2 hari yang lalu',
        isRead: true,
        actionText: 'Balas Review',
      ),
    ];
  }

  List<NotificationItem> _getBuyerNotifications() {
    return [
      NotificationItem(
        id: '1',
        type: NotificationType.shipping,
        title: 'Pesanan Sedang Dikirim',
        message:
            'Pesanan #12345 (Sepatu Olahraga) sedang dalam perjalanan. Estimasi tiba: 2 hari.',
        time: '1 jam yang lalu',
        isRead: false,
        actionText: 'Lacak Pesanan',
      ),
      NotificationItem(
        id: '2',
        type: NotificationType.promotion,
        title: 'Flash Sale Dimulai!',
        message:
            'Diskon hingga 70% untuk kategori Fashion. Buruan sebelum kehabisan!',
        time: '2 jam yang lalu',
        isRead: false,
        actionText: 'Belanja Sekarang',
      ),
      NotificationItem(
        id: '3',
        type: NotificationType.payment,
        title: 'Pembayaran Berhasil',
        message:
            'Pembayaran untuk pesanan #12344 sebesar Rp 450.000 telah berhasil diproses.',
        time: '1 hari yang lalu',
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        type: NotificationType.order,
        title: 'Pesanan Dikonfirmasi',
        message:
            'Pesanan Anda telah dikonfirmasi penjual dan sedang dipersiapkan untuk pengiriman.',
        time: '1 hari yang lalu',
        isRead: true,
        actionText: 'Lihat Detail',
      ),
      NotificationItem(
        id: '5',
        type: NotificationType.rating,
        title: 'Jangan Lupa Beri Rating!',
        message:
            'Bagaimana pengalaman belanja Anda? Beri rating dan review untuk produk yang sudah diterima.',
        time: '3 hari yang lalu',
        isRead: true,
        actionText: 'Beri Rating',
      ),
      NotificationItem(
        id: '6',
        type: NotificationType.system,
        title: 'Pembaruan Aplikasi',
        message:
            'Versi terbaru aplikasi telah tersedia dengan fitur-fitur menarik. Update sekarang!',
        time: '1 minggu yang lalu',
        isRead: true,
        actionText: 'Update',
      ),
    ];
  }
}

enum NotificationType {
  purchase,
  rating,
  order,
  promotion,
  payment,
  shipping,
  review,
  system,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String time;
  bool isRead;
  final String? actionText;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.actionText,
  });
}
