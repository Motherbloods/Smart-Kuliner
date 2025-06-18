// screens/pesanan_saya_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/services/product_service.dart';
import 'package:smart/widgets/order/order_card.dart';
import 'package:smart/widgets/order/order_list_view.dart';
import 'package:smart/widgets/pesanan_saya/notification_bottom_sheet.dart';
import 'package:smart/widgets/pesanan_saya/order_action_helper.dart';
import 'package:smart/widgets/pesanan_saya/order_widgets.dart';
import 'package:smart/widgets/pesanan_saya/orderdetailssheet.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../models/order.dart';

class PesananSayaScreen extends StatefulWidget {
  const PesananSayaScreen({Key? key}) : super(key: key);

  @override
  State<PesananSayaScreen> createState() => _PesananSayaScreenState();
}

class _PesananSayaScreenState extends State<PesananSayaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();

  final NotificationService _notificationService = NotificationService();

  // Loading states
  bool _isLoading = false;

  // Notification count
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with default length, will be updated in build
    _tabController = TabController(length: 6, vsync: this);
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Setup notification listener
  void _setupNotificationListener() {
    final authProvider = context.read<MyAuthProvider>();
    if (authProvider.currentUser != null) {
      _notificationService
          .getUnreadNotificationCount(authProvider.currentUser!.uid)
          .listen((count) {
            if (mounted) {
              setState(() {
                _unreadNotificationCount = count;
              });
            }
          });
    }
  }

  // Get tabs based on user type
  List<Tab> _getTabs(bool isSeller) {
    if (isSeller) {
      return const [
        Tab(text: 'Semua'),
        Tab(text: 'Menunggu Konfirmasi'),
        Tab(text: 'Perlu Diproses'),
        Tab(text: 'Perlu Dikirim'),
        Tab(text: 'Pesanan Selesai'),
        Tab(text: 'Dibatalkan'),
      ];
    } else {
      return const [
        Tab(text: 'Semua'),
        Tab(text: 'Menunggu Konfirmasi'),
        Tab(text: 'Dikemas'),
        Tab(text: 'Dikirim'),
        Tab(text: 'Selesai'),
        Tab(text: 'Dibatalkan'),
      ];
    }
  }

  // Get tab content based on user type
  List<Widget> _getTabViews(MyAuthProvider authProvider, bool isSeller) {
    if (isSeller) {
      return [
        // Semua pesanan
        OrderListView(
          authProvider: authProvider,
          status: null,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: OrderWidgets.buildEmptyState,
        ),
        // Menunggu Konfirmasi (Pending)
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.pending,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: (status) => OrderWidgets.buildSellerEmptyState(
            'Tidak ada pesanan yang menunggu konfirmasi',
            'Pesanan baru akan muncul di sini',
            Icons.pending_actions,
          ),
        ),
        // Perlu Diproses (Confirmed)
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.confirmed,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: (status) => OrderWidgets.buildSellerEmptyState(
            'Tidak ada pesanan yang perlu diproses',
            'Pesanan yang sudah dikonfirmasi akan muncul di sini',
            Icons.inventory_2,
          ),
        ),
        // Perlu Dikirim (Processing)
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.processing,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: (status) => OrderWidgets.buildSellerEmptyState(
            'Tidak ada pesanan yang perlu dikirim',
            'Pesanan yang siap dikirim akan muncul di sini',
            Icons.local_shipping,
          ),
        ),
        // Pesanan Selesai (Completed + Delivered)
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.completed,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: (status) => OrderWidgets.buildSellerEmptyState(
            'Belum ada pesanan yang selesai',
            'Pesanan yang telah selesai akan muncul di sini',
            Icons.check_circle,
          ),
        ),
        // Dibatalkan
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.cancelled,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: (status) => OrderWidgets.buildSellerEmptyState(
            'Tidak ada pesanan yang dibatalkan',
            'Pesanan yang dibatalkan akan muncul di sini',
            Icons.cancel,
          ),
        ),
      ];
    } else {
      return [
        // Semua pesanan (Customer)
        OrderListView(
          authProvider: authProvider,
          status: null,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: OrderWidgets.buildEmptyState,
        ),
        // Menunggu Bayar / Pending
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.pending,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: OrderWidgets.buildEmptyState,
        ),
        // Dikemas / Processing
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.confirmed,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: OrderWidgets.buildEmptyState,
        ),
        // Dikirim
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.shipped,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: OrderWidgets.buildEmptyState,
        ),
        // Selesai
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.completed,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: OrderWidgets.buildEmptyState,
        ),
        // Dibatalkan
        OrderListView(
          authProvider: authProvider,
          status: OrderStatus.cancelled,
          orderService: _orderService,
          onRefresh: () => setState(() {}),
          orderCardBuilder: _buildOrderCard,
          emptyStateBuilder: OrderWidgets.buildEmptyState,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.currentUser == null) {
          return const Scaffold(
            body: Center(child: Text('Silakan login terlebih dahulu')),
          );
        }

        final isSeller = authProvider.currentUser?.seller ?? false;
        final tabs = _getTabs(isSeller);

        // Update tab controller if length changed
        if (_tabController.length != tabs.length) {
          _tabController.dispose();
          _tabController = TabController(length: tabs.length, vsync: this);
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: Text(
              isSeller ? 'Kelola Pesanan' : 'Pesanan Saya',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Notification bell with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black87,
                    ),
                    onPressed: () => NotificationBottomSheet.show(
                      context: context,
                      notificationService: _notificationService,
                      orderService: _orderService,
                      onNavigateToOrderDetails: _navigateToOrderDetails,
                    ),
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadNotificationCount > 99
                              ? '99+'
                              : _unreadNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black87),
                onPressed: () => setState(() {}),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF4DA8DA),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF4DA8DA),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              tabs: tabs,
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: _getTabViews(authProvider, isSeller),
                ),
        );
      },
    );
  }

  void _navigateToOrderDetails(String orderId) async {
    final order = await _orderService.getOrder(orderId);
    if (order != null && context.mounted) {
      _showOrderDetails(order);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat detail pesanan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrderCard(OrderModel order, bool isSeller) {
    return OrderCard(
      order: order,
      isSeller: isSeller,
      onViewDetails: () => _showOrderDetails(order),
      actionButton: _buildActionButton(order, isSeller),
    );
  }

  Widget _buildActionButton(OrderModel order, bool isSeller) {
    if (isSeller) {
      switch (order.status) {
        case OrderStatus.pending:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tolak pesanan
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => OrderActionHelper.cancelOrder(
                        context: context,
                        orderService: _orderService,
                        orderId: order.id,
                        onLoading: () => setState(() => _isLoading = true),
                        onComplete: () => setState(() => _isLoading = false),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Tolak',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              // Terima pesanan
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => OrderActionHelper.confirmOrder(
                        context: context,
                        orderService: _orderService,
                        orderId: order.id,
                        onLoading: () => setState(() => _isLoading = true),
                        onComplete: () => setState(() => _isLoading = false),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Terima',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
              ),
            ],
          );
        case OrderStatus.confirmed:
          return ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => OrderActionHelper.updateOrderStatus(
                    context: context,
                    orderService: _orderService,
                    orderId: order.id,
                    status: OrderStatus.processing,
                    onLoading: () => setState(() => _isLoading = true),
                    onComplete: () => setState(() => _isLoading = false),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Proses Pesanan',
                    style: TextStyle(color: Colors.white),
                  ),
          );
        case OrderStatus.processing:
          return ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => OrderActionHelper.updateOrderStatus(
                    context: context,
                    orderService: _orderService,
                    orderId: order.id,
                    status: OrderStatus.shipped,
                    onLoading: () => setState(() => _isLoading = true),
                    onComplete: () => setState(() => _isLoading = false),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Kirim Pesanan',
                    style: TextStyle(color: Colors.white),
                  ),
          );
        default:
          return const SizedBox();
      }
    } else {
      switch (order.status) {
        case OrderStatus.pending:
          return ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => OrderActionHelper.cancelOrder(
                    context: context,
                    orderService: _orderService,
                    orderId: order.id,
                    onLoading: () => setState(() => _isLoading = true),
                    onComplete: () => setState(() => _isLoading = false),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Batalkan',
              style: TextStyle(color: Colors.white),
            ),
          );
        case OrderStatus.shipped:
          return ElevatedButton(
            onPressed: _isLoading ? null : () => _handleOrderReceived(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Pesanan Diterima',
                    style: TextStyle(color: Colors.white),
                  ),
          );
        case OrderStatus.delivered:
          return ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => OrderActionHelper.completeOrder(
                    context: context,
                    orderService: _orderService,
                    orderId: order.id,
                    onLoading: () => setState(() => _isLoading = true),
                    onComplete: () => setState(() => _isLoading = false),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Selesaikan Pesanan',
                    style: TextStyle(color: Colors.white),
                  ),
          );
        default:
          return const SizedBox();
      }
    }
  }

  // Handle when customer receives the order
  Future<void> _handleOrderReceived(OrderModel order) async {
    setState(() => _isLoading = true);

    try {
      // First update the order status to delivered
      await _orderService.updateOrderStatus(order.id, OrderStatus.delivered);

      // Then update the products sold count
      await _updateProductsSoldCount(order);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil diterima'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error handling order received: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Update products sold count
  Future<void> _updateProductsSoldCount(OrderModel order) async {
    try {
      for (OrderItem item in order.items) {
        await _productService.updateProductSoldCount(
          item.productId,
          item.quantity,
        );
      }
      print('✅ Products sold count updated successfully');
    } catch (e) {
      print('❌ Error updating products sold count: $e');
      rethrow; // Re-throw to be caught by the calling function
    }
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPesananDetailsSheet(order),
    );
  }

  Widget _buildPesananDetailsSheet(OrderModel order) {
    return OrderDetailsSheet(
      order: order,
      onClose: () => Navigator.pop(context),
    );
  }
}
