import 'package:flutter/material.dart';
import 'package:smart/models/order.dart';
import 'package:smart/providers/auth_provider.dart';
import 'package:smart/services/order_service.dart';

class OrderListView extends StatelessWidget {
  final MyAuthProvider authProvider;
  final OrderStatus? status;
  final OrderService orderService;
  final void Function() onRefresh;
  final Widget Function(OrderModel order, bool isSeller) orderCardBuilder;
  final Widget Function(OrderStatus? status) emptyStateBuilder;

  const OrderListView({
    super.key,
    required this.authProvider,
    required this.status,
    required this.orderService,
    required this.onRefresh,
    required this.orderCardBuilder,
    required this.emptyStateBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isSeller = authProvider.currentUser?.seller ?? false;
    final userId = authProvider.currentUser?.uid ?? '';

    return StreamBuilder<List<OrderModel>>(
      stream: isSeller
          ? orderService.getSellerOrders(userId)
          : orderService.getBuyerOrders(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRefresh,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        List<OrderModel> orders = snapshot.data ?? [];
        if (status != null) {
          orders = orders.where((order) => order.status == status).toList();
        }

        if (orders.isEmpty) {
          return emptyStateBuilder(status);
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return orderCardBuilder(orders[index], isSeller);
            },
          ),
        );
      },
    );
  }
}
