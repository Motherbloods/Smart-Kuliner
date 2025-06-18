import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smart/screens/cart_screen.dart';
import 'package:smart/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart'; // Import CartProvider
import 'beranda_screen.dart';
import 'profile_screen.dart';
import 'pusat_promosi_screen.dart';
import 'pencarian_screen.dart';
import 'notifikasi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Screen instances untuk reuse
  late BerandaScreen _berandaScreen;
  late PusatPromosiScreen _pusatPromosiScreen;
  late PencarianScreen _pencarianScreen;
  late NotifikasiScreen _notifikasiScreen;
  late ProfileScreen _profileScreen;

  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navBarItems;
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationCount = 0;

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

  @override
  void initState() {
    super.initState();

    // Initialize screen instances once
    _berandaScreen = BerandaScreen();
    _pusatPromosiScreen = PusatPromosiScreen();
    _pencarianScreen = PencarianScreen();
    _notifikasiScreen = NotifikasiScreen();
    _profileScreen = ProfileScreen();

    _initializeScreensAndNavBar();
    NotificationService().initialize();

    // Setup notification listener setelah initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationListener();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Widget untuk membuat icon notifikasi dengan badge
  Widget _buildNotificationIcon({required bool isActive}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(isActive ? Icons.notifications : Icons.notifications_outlined),
        if (_unreadNotificationCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
    );
  }

  void _initializeScreensAndNavBar() {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final isSeller = authProvider.currentUser?.seller ?? false;

    if (isSeller) {
      // Seller: Produk Saya (BerandaScreen), Pusat Promosi, Notifikasi, Profile
      _screens = [
        _berandaScreen,
        _pusatPromosiScreen,
        _notifikasiScreen,
        _profileScreen,
      ];

      _navBarItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Produk Saya',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.campaign_outlined),
          activeIcon: Icon(Icons.campaign),
          label: 'Pusat Promosi',
        ),
        BottomNavigationBarItem(
          icon: _buildNotificationIcon(isActive: false),
          activeIcon: _buildNotificationIcon(isActive: true),
          label: 'Notifikasi',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else {
      // User biasa: Beranda (BerandaScreen), Pencarian, Notifikasi, Profile
      _screens = [
        _berandaScreen,
        _pencarianScreen,
        _notifikasiScreen,
        _profileScreen,
      ];

      _navBarItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Pencarian',
        ),
        BottomNavigationBarItem(
          icon: _buildNotificationIcon(isActive: false),
          activeIcon: _buildNotificationIcon(isActive: true),
          label: 'Notifikasi',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }

  // Fungsi untuk navigasi ke halaman cart
  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        // Reinitialize jika user data berubah
        if (authProvider.currentUser != null) {
          _initializeScreensAndNavBar();
        }

        return Scaffold(
          appBar: (authProvider.currentUser?.seller ?? false)
              ? (_selectedIndex == 0
                    ? _buildAppBar()
                    : null) // Seller: hanya di Produk Saya
              : (_selectedIndex == 0 ? _buildAppBar() : null),
          body: GestureDetector(
            onTap: () {
              _searchFocusNode.unfocus();
            },
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: const Color(0xFF4DA8DA),
              unselectedItemColor: Colors.grey[600],
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              items: _navBarItems,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFF4DA8DA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Text(
              'Smart Kuliner',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),

          // Hanya tampil jika user biasa (bukan seller)
          if (!(Provider.of<MyAuthProvider>(
                context,
                listen: false,
              ).currentUser?.seller ??
              false))
            GestureDetector(
              onTap: _navigateToCart,
              child: Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return Stack(
                    children: [
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFF4DA8DA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: const Icon(
                          Icons.shopping_cart,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      if (cartProvider.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${cartProvider.itemCount}',
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
