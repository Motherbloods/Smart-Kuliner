// screens/checkout_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/managers/user_manager.dart';
import 'package:smart/providers/cart_provider.dart';
import 'package:smart/providers/auth_provider.dart';
import 'package:smart/screens/pesanan_saya_screen.dart';
import 'package:smart/services/order_service_all.dart';
import 'package:smart/models/order.dart';
import 'package:intl/intl.dart';
import 'package:smart/widgets/order/address_section.dart';
import 'package:smart/widgets/order/bottom_checkout_button.dart';
import 'package:smart/widgets/order/payment_method_section.dart';
import 'package:smart/widgets/order/product_list_section.dart';
import 'package:smart/widgets/order/note_section.dart';
import 'package:smart/widgets/order/payment_summary_section.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late TextEditingController _alamatController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final OrderService _orderService = OrderService();

  String _selectedPaymentMethod = 'COD';
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  double? _currentLatitude;
  double? _currentLongitude;

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    final user = UserManager().getCurrentUser(context);
    _alamatController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // Check and request location permission
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layanan lokasi tidak aktif. Silakan aktifkan GPS.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin lokasi ditolak permanen. Silakan aktifkan di pengaturan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  // Get current location and convert to address
  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += '${place.locality}, ';
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          address += '${place.subAdministrativeArea}, ';
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          address += '${place.administrativeArea}, ';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          address += place.country!;
        }

        // Remove trailing comma and space
        address = address.replaceAll(RegExp(r', $'), '');

        setState(() {
          _alamatController.text = address;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil didapatkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Show location picker dialog
  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Alamat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: const Text('Gunakan Lokasi Saat Ini'),
                subtitle: const Text('Otomatis mengambil lokasi GPS'),
                onTap: () {
                  Navigator.pop(context);
                  _getCurrentLocation();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_location, color: Colors.green),
                title: const Text('Input Manual'),
                subtitle: const Text('Ketik alamat secara manual'),
                onTap: () {
                  Navigator.pop(context);
                  _showManualAddressDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show manual address input dialog
  void _showManualAddressDialog() {
    final TextEditingController manualController = TextEditingController(
      text: _alamatController.text,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Input Alamat Manual'),
          content: TextField(
            controller: manualController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Masukkan alamat lengkap...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _alamatController.text = manualController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Detail Pembelian',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer2<CartProvider, MyAuthProvider>(
        builder: (context, cartProvider, authProvider, child) {
          if (cartProvider.itemCount == 0) {
            return const Center(child: Text('Tidak ada item untuk checkout'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alamat Pengiriman dengan Geolocation
                _buildAddressSection(),
                const SizedBox(height: 16),

                // Daftar Produk
                ProductListSection(),
                const SizedBox(height: 16),

                // Metode Pembayaran
                PaymentMethodSection(),
                const SizedBox(height: 16),

                // Catatan
                NoteSection(controller: _catatanController),
                const SizedBox(height: 16),

                // Ringkasan Pembayaran
                PaymentSummarySection(),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomCheckoutButton(
        isLoading: _isLoading,
        onProcessOrder: _processOrder,
        formatPrice: _formatPrice,
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Alamat Pengiriman',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _showLocationPicker,
                  icon: const Icon(Icons.add_location_alt, color: Colors.blue),
                  tooltip: 'Pilih Lokasi',
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _alamatController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Masukkan alamat pengiriman...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.all(12),
              suffixIcon: IconButton(
                onPressed: _showLocationPicker,
                icon: const Icon(Icons.location_searching, color: Colors.blue),
                tooltip: 'Pilih Lokasi',
              ),
            ),
          ),
          if (_currentLatitude != null && _currentLongitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Koordinat: ${_currentLatitude!.toStringAsFixed(6)}, ${_currentLongitude!.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processOrder(
    CartProvider cartProvider,
    MyAuthProvider authProvider,
    double total,
  ) async {
    if (_alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat pengiriman harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create order
      final order = OrderModel(
        id: '',
        buyerId: authProvider.currentUser?.uid ?? '',
        buyerName: authProvider.currentUser?.name ?? '',
        buyerEmail: authProvider.currentUser?.email ?? '',
        items: cartProvider.items.values
            .map(
              (cartItem) => OrderItem(
                productId: cartItem.productId,
                productName: cartItem.name,
                imageUrl: cartItem.imageUrl,
                sellerId: cartItem.sellerId,
                sellerName: cartItem.nameToko,
                price: cartItem.price,
                quantity: cartItem.quantity,
              ),
            )
            .toList(),
        totalAmount: total,
        status: OrderStatus.pending,
        paymentMethod: _selectedPaymentMethod,
        shippingAddress: _alamatController.text.trim(),
        notes: _catatanController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Tambahkan koordinat jika tersedia
        latitude: _currentLatitude,
        longitude: _currentLongitude,
      );

      // Save order
      await _orderService.createOrder(order);

      // Clear cart
      cartProvider.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to Pesanan Saya
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PesananSayaScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat pesanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
