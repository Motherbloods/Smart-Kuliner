import 'package:flutter/material.dart';
import 'package:smart/models/order.dart';
import 'package:smart/widgets/review/add_review_dialog.dart';
import 'package:smart/services/review_service.dart';
import 'package:smart/services/product_service.dart';

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool isSeller;
  final VoidCallback onViewDetails;
  final Widget actionButton;

  const OrderCard({
    super.key,
    required this.order,
    required this.isSeller,
    required this.onViewDetails,
    required this.actionButton,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService();

  String _formatDate(DateTime date) {
    // Format sesuai kebutuhan
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatPrice(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.indigo;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProductItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatPrice(item.totalPrice.toInt()),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4DA8DA),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewButton(OrderItem item) {
    print('ini reviewButton');
    return FutureBuilder<bool>(
      future: _reviewService.canUserReviewProduct(
        widget.order.buyerId,
        item.productId,
      ),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          print('ini snapshot data true');
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () => _showReviewDialog(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DA8DA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Review', style: TextStyle(fontSize: 12)),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showReviewDialog(OrderItem item) async {
    try {
      // Get product details
      final product = await _productService.getProduct(item.productId);
      if (product == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat data produk'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AddReviewDialog(
            product: product,
            onReviewAdded: (review) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ulasan berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the widget
                setState(() {});
              }
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.order.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.order.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(widget.order.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(widget.order.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info pembeli/penjual
                Row(
                  children: [
                    Icon(
                      widget.isSeller ? Icons.person : Icons.store,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isSeller
                          ? 'Pembeli: ${widget.order.buyerName}'
                          : 'Penjual: ${widget.order.items.first.sellerName}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Produk
                ...widget.order.items.map(_buildProductItem),

                const SizedBox(height: 12),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total (${widget.order.items.length} item)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatPrice(widget.order.totalAmount.toInt()),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4DA8DA),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tombol
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onViewDetails,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4DA8DA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(color: Color(0xFF4DA8DA)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: widget.actionButton),

                    // Tombol Review - hanya untuk pembeli dan status completed
                    if (!widget.isSeller &&
                        widget.order.status == OrderStatus.completed)
                      ...widget.order.items.map(
                        (item) => _buildReviewButton(item),
                      ),
                    // ...widget.order.items.map((item) {
                    //   print('ini item $item.');
                    //   return _buildReviewButton(item); // atau widget lain
                    // }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
