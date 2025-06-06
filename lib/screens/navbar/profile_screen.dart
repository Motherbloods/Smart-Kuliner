import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/utils/date_utils.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'package:smart/widgets/action_button.dart';
import 'package:smart/widgets/info_card.dart';
import 'package:smart/widgets/logout_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../services/product_service.dart';
import '../produk/add_product_screen.dart';
import '../produk/seller_products_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserModel? _userData;
  final ProductService _productService = ProductService();
  int _productCount = 0;
  final formatted = formatDate(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      setState(() {
        _userData = authProvider.currentUser;
        _isLoading = false;
      });

      // Load product count if user is seller
      if (_userData?.seller == true) {
        _loadProductCount();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memuat data profil: $e',
        );
      }
    }
  }

  void _loadProductCount() {
    if (_userData?.uid != null) {
      _productService.getSellerProducts(_userData!.uid).listen((products) {
        if (mounted) {
          setState(() {
            _productCount = products.length;
          });
        }
      });
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            )
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              color: const Color(0xFFFF6B35),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF6B35,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                (_userData?.name.isNotEmpty == true)
                                    ? _userData!.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            _userData?.name ?? 'Nama tidak tersedia',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),

                          // Email
                          Text(
                            _userData?.email ?? 'Email tidak tersedia',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // User Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (_userData?.seller == true)
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (_userData?.seller == true)
                                  ? 'Seller'
                                  : 'Customer',
                              style: TextStyle(
                                color: (_userData?.seller == true)
                                    ? Colors.green[700]
                                    : Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Seller Stats Card (only for sellers)
                    if (_userData?.seller == true)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statistik Toko',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_productCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Total Produk',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SellerProductsScreen(
                                                sellerId: _userData!.uid,
                                                nameToko: _userData!.namaToko!,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // User Info Cards
                    if (_userData?.seller == true &&
                        _userData?.namaToko != null)
                      InfoCard(
                        icon: Icons.store,
                        title: 'Nama Toko',
                        value: _userData!.namaToko!,
                        color: Colors.green,
                      ),

                    InfoCard(
                      icon: Icons.email,
                      title: 'Email',
                      value: _userData?.email ?? 'Email tidak tersedia',
                      color: Colors.blue,
                    ),

                    InfoCard(
                      icon: Icons.calendar_today,
                      title: 'Bergabung Sejak',
                      value: _userData?.createdAt != null
                          ? formatDate(_userData!.createdAt)
                          : 'Tanggal tidak tersedia',
                      color: Colors.purple,
                    ),

                    InfoCard(
                      icon: Icons.person,
                      title: 'Tipe Akun',
                      value: (_userData?.seller == true)
                          ? 'Seller'
                          : 'Customer',
                      color: (_userData?.seller == true)
                          ? Colors.green
                          : Colors.blue,
                    ),

                    const SizedBox(height: 24),

                    // Seller Product Management (only for sellers)
                    if (_userData?.seller == true) ...[
                      ActionButton(
                        icon: Icons.inventory_2,
                        title: 'Kelola Produk',
                        subtitle: 'Lihat dan kelola semua produk Anda',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SellerProductsScreen(
                                sellerId: _userData!.uid,
                                nameToko: _userData!.namaToko!,
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // Action Buttons
                    ActionButton(
                      icon: Icons.edit,
                      title: 'Edit Profile',
                      subtitle: 'Ubah informasi profil Anda',
                      onTap: () {
                        // TODO: Navigate to edit profile screen
                        SnackbarHelper.showWarningSnackbar(
                          context,
                          'Fitur edit profil akan segera hadir',
                        );
                      },
                    ),

                    // ActionButton(
                    //   icon: Icons.settings,
                    //   title: 'Pengaturan',
                    //   subtitle: 'Kelola pengaturan aplikasi',
                    //   onTap: () {
                    //     // TODO: Navigate to settings screen
                    //     SnackbarHelper.showWarningSnackbar(
                    //       context,
                    //       'Fitur pengaturan akan segera hadir',
                    //     );
                    //   },
                    // ),

                    // ActionButton(
                    //   icon: Icons.help_outline,
                    //   title: 'Bantuan',
                    //   subtitle: 'Dapatkan bantuan dan dukungan',
                    //   onTap: () {
                    //     // TODO: Navigate to help screen
                    //     SnackbarHelper.showWarningSnackbar(
                    //       context,
                    //       'Fitur bantuan akan segera hadir',
                    //     );
                    //   },
                    // ),

                    // const SizedBox(height: 16),

                    // Logout Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton(
                        onPressed: () =>
                            showLogoutDialog(context, _performLogout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Keluar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      // Floating Action Button for adding products (only for sellers)
      floatingActionButton: (_userData?.seller == true)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(
                      sellerId: _userData!.uid,
                      nameToko: _userData!.namaToko!,
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFFFF6B35),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Future<void> _performLogout() async {
    try {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      await authProvider.signOut();

      if (mounted) {
        // Navigate to login screen or main screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', // Adjust route name as needed
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(context, 'Gagal keluar dari akun: $e');
      }
    }
  }
}
