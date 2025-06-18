import 'package:flutter/material.dart';
import 'package:smart/models/order.dart';
import 'package:smart/widgets/order/order_card.dart';
import 'package:smart/widgets/order/order_empty_state.dart';

class OrderWidgets {
  static Widget buildEmptyState(OrderStatus? status) {
    return OrderEmptyState(status: status);
  }

  static Widget buildSellerEmptyState(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildOrderCard({
    required OrderModel order,
    required bool isSeller,
    required VoidCallback onViewDetails,
    required Widget actionButton,
  }) {
    return OrderCard(
      order: order,
      isSeller: isSeller,
      onViewDetails: onViewDetails,
      actionButton: actionButton,
    );
  }

  static Widget buildActionButton({
    required OrderModel order,
    required bool isSeller,
    required bool isLoading,
    required VoidCallback onConfirm,
    required VoidCallback onProcess,
    required VoidCallback onShip,
    required VoidCallback onCancel,
    required VoidCallback onComplete,
  }) {
    if (isSeller) {
      switch (order.status) {
        case OrderStatus.pending:
          return _button(
            onPressed: isLoading ? null : onConfirm,
            color: Colors.green,
            text: 'Konfirmasi',
            isLoading: isLoading,
          );
        case OrderStatus.confirmed:
          return _button(
            onPressed: isLoading ? null : onProcess,
            color: Colors.blue,
            text: 'Proses',
            isLoading: isLoading,
          );
        case OrderStatus.processing:
          return _button(
            onPressed: isLoading ? null : onShip,
            color: Colors.purple,
            text: 'Kirim',
            isLoading: isLoading,
          );
        default:
          return const SizedBox();
      }
    } else {
      switch (order.status) {
        case OrderStatus.pending:
          return _button(
            onPressed: isLoading ? null : onCancel,
            color: Colors.red,
            text: 'Batalkan',
            isLoading: false,
          );
        case OrderStatus.delivered:
          return _button(
            onPressed: isLoading ? null : onComplete,
            color: Colors.green,
            text: 'Terima',
            isLoading: isLoading,
          );
        default:
          return const SizedBox();
      }
    }
  }

  static Widget _button({
    required VoidCallback? onPressed,
    required Color color,
    required String text,
    required bool isLoading,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
