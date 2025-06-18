import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class BottomCheckoutButton extends StatelessWidget {
  final bool isLoading;
  final Function(CartProvider, MyAuthProvider, double) onProcessOrder;
  final String Function(double) formatPrice;

  const BottomCheckoutButton({
    super.key,
    required this.isLoading,
    required this.onProcessOrder,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, MyAuthProvider>(
      builder: (context, cartProvider, authProvider, child) {
        final subtotal = cartProvider.totalPrice;
        final ongkir = 5000.0;
        final total = subtotal + ongkir;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => onProcessOrder(cartProvider, authProvider, total),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DA8DA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Bayar ${formatPrice(total)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
