import 'package:flutter/material.dart';
import 'package:smart/models/order.dart';

class OrderEmptyState extends StatelessWidget {
  final OrderStatus? status;

  const OrderEmptyState({super.key, this.status});

  String _getStatusText(OrderStatus status) {
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

  @override
  Widget build(BuildContext context) {
    String message = 'Belum ada pesanan';
    if (status != null) {
      message = 'Belum ada pesanan dengan status ${_getStatusText(status!)}';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan Anda akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
