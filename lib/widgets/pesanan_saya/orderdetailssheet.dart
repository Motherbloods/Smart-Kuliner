import 'package:flutter/material.dart';
import 'package:smart/models/order.dart';
import 'package:smart/models/timelinestep.dart';
import 'package:smart/utils/order_utils.dart';

class OrderDetailsSheet extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onClose;

  const OrderDetailsSheet({
    Key? key,
    required this.order,
    required this.onClose,
  }) : super(key: key);

  String _formatPrice(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  String formatDatePesanan(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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
                  'Detail Pesanan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ID dan Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: ${order.id.substring(0, 8)}...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: OrderUtils.getStatusColor(
                            order.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: OrderUtils.getStatusColor(order.status),
                          ),
                        ),
                        child: Text(
                          OrderUtils.getStatusText(order.status),
                          style: TextStyle(
                            color: OrderUtils.getStatusColor(order.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// Tanggal
                  Text(
                    'Tanggal Pesanan: ${formatDatePesanan(order.createdAt)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  ...order.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Penjual: ${item.sellerName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} x ${_formatPrice(item.price.toInt())}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatPrice(item.totalPrice.toInt()),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4DA8DA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Alamat Pengiriman',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.buyerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.shippingAddress,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Informasi Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text(_formatPrice(order.totalAmount.toInt())),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ongkos Kirim:'),
                            const Text('Rp5.000'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatPrice(order.totalAmount.toInt()),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF4DA8DA),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (order.notes.isNotEmpty) ...[
                    const Text(
                      'Catatan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        order.notes,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text(
                    'Riwayat Pesanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildOrderTimeline(order),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(OrderModel order) {
    final timeline = _getOrderTimeline(order);

    return Column(
      children: timeline.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == timeline.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: step.isCompleted ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 40, color: Colors.grey[300]),
              ],
            ),

            const SizedBox(width: 12),

            // Timeline content
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: step.isCompleted
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                    if (step.timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatDatePesanan(step.timestamp!),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<TimelineStep> _getOrderTimeline(OrderModel order) {
    final steps = <TimelineStep>[];

    // Order placed
    steps.add(
      TimelineStep(
        title: 'Pesanan Dibuat',
        timestamp: order.createdAt,
        isCompleted: true,
      ),
    );

    // Order confirmed
    if (order.status.index >= OrderStatus.confirmed.index) {
      steps.add(
        TimelineStep(
          title: 'Pesanan Dikonfirmasi',
          timestamp: order.confirmedAt,
          isCompleted: true,
        ),
      );
    } else {
      steps.add(TimelineStep(title: 'Menunggu Konfirmasi', isCompleted: false));
    }

    // Order processing
    if (order.status.index >= OrderStatus.processing.index) {
      steps.add(
        TimelineStep(
          title: 'Pesanan Diproses',
          timestamp: order.processedAt,
          isCompleted: true,
        ),
      );
    } else if (order.status.index >= OrderStatus.confirmed.index) {
      steps.add(TimelineStep(title: 'Menunggu Diproses', isCompleted: false));
    }

    // Order shipped
    if (order.status.index >= OrderStatus.shipped.index) {
      steps.add(
        TimelineStep(
          title: 'Pesanan Dikirim',
          timestamp: order.shippedAt,
          isCompleted: true,
        ),
      );
    } else if (order.status.index >= OrderStatus.processing.index) {
      steps.add(TimelineStep(title: 'Menunggu Pengiriman', isCompleted: false));
    }

    // Order delivered
    if (order.status.index >= OrderStatus.delivered.index) {
      steps.add(
        TimelineStep(
          title: 'Pesanan Tiba',
          timestamp: order.deliveredAt,
          isCompleted: true,
        ),
      );
    } else if (order.status.index >= OrderStatus.shipped.index) {
      steps.add(TimelineStep(title: 'Dalam Pengiriman', isCompleted: false));
    }

    // Order completed or cancelled
    if (order.status == OrderStatus.completed) {
      steps.add(
        TimelineStep(
          title: 'Pesanan Selesai',
          timestamp: order.completedAt,
          isCompleted: true,
        ),
      );
    } else if (order.status == OrderStatus.cancelled) {
      steps.add(
        TimelineStep(
          title: 'Pesanan Dibatalkan',
          timestamp: order.cancelledAt,
          isCompleted: true,
        ),
      );
    } else if (order.status.index >= OrderStatus.delivered.index) {
      steps.add(
        TimelineStep(
          title: 'Menunggu Konfirmasi Penerimaan',
          isCompleted: false,
        ),
      );
    }

    return steps;
  }
}
