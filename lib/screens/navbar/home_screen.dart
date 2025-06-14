import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'beranda_screen.dart';
import 'profile_screen.dart';
// import 'search_results_screen.dart';
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
  // String _searchQuery = '';
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializeScreensAndNavBar() {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final isSeller = authProvider.currentUser?.seller ?? false;

    if (isSeller) {
      // Seller: Produk Saya (BerandaScreen), Pusat Promosi, Notifikasi, Profile
      _screens = [
        _berandaScreen, // BerandaScreen akan menampilkan "Produk Saya" untuk seller
        _pusatPromosiScreen,
        _notifikasiScreen,
        _profileScreen,
      ];

      _navBarItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Produk Saya',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.campaign_outlined),
          activeIcon: Icon(Icons.campaign),
          label: 'Pusat Promosi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Notifikasi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else {
      // User biasa: Beranda (BerandaScreen), Pencarian, Notifikasi, Profile
      _screens = [
        _berandaScreen, // BerandaScreen akan menampilkan "Beranda" untuk user biasa
        _pencarianScreen,
        _notifikasiScreen,
        _profileScreen,
      ];

      _navBarItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Pencarian',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Notifikasi',
        ),
        BottomNavigationBarItem(
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
      // Clear search ketika pindah tab
      // _searchQuery = '';
      _searchController.clear();
      _searchFocusNode.unfocus(); // Hilangkan focus dari search
    });
  }

  // void _clearSearch() {
  //   setState(() {
  //     _searchQuery = '';
  //   });
  //   _searchController.clear();
  //   _searchFocusNode.unfocus();
  // }

  // bool _shouldShowSearchBar() {
  //   // Tampilkan search bar hanya di screen pertama (BerandaScreen)
  //   // baik untuk seller maupun user biasa
  //   return _selectedIndex == 0 && _screens[_selectedIndex] is BerandaScreen;
  // }

  // void _performSearch() {
  //   if (_searchQuery.trim().isNotEmpty) {
  //     _searchFocusNode.unfocus();
  //     print('🔍 Navigating to search results: $_searchQuery');

  //     // Simpan query sebelum navigasi
  //     final queryToSearch = _searchQuery.trim();

  //     // Navigasi ke halaman hasil pencarian
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => SearchResultsScreen(query: queryToSearch),
  //       ),
  //     ).then((_) {
  //       // Clear search SETELAH kembali dari halaman search results
  //       _clearSearch();
  //     });
  //   } else {
  //     print('🔍 Search query is empty');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        // Reinitialize jika user data berubah
        if (authProvider.currentUser != null) {
          _initializeScreensAndNavBar();
        }

        return Scaffold(
          // appBar: _shouldShowSearchBar()
          //     ? PreferredSize(
          //         preferredSize: const Size.fromHeight(80),
          //         child: SafeArea(
          //           child: Padding(
          //             padding: const EdgeInsets.symmetric(
          //               horizontal: 16,
          //               vertical: 12,
          //             ),
          //             child: CustomSearchBar(
          //               searchController: _searchController,
          //               searchFocusNode: _searchFocusNode,
          //               searchQuery: _searchQuery,
          //               onChanged: (value) {
          //                 setState(() {
          //                   _searchQuery = value;
          //                 });
          //               },
          //               onClear: () {
          //                 _clearSearch();
          //               },
          //               onSearch: () {
          //                 _performSearch();
          //               },
          //             ),
          //           ),
          //         ),
          //       )
          //     : null,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0, // Hilangkan bayangan saat scroll
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
                      color: Colors.white, // Tetap isi meskipun ditimpa shader
                    ),
                  ),
                ),

                // IKON DENGAN GRADIENT
                Stack(
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
                        color:
                            Colors.white, // Warna default, akan ditimpa shader
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          body: GestureDetector(
            onTap: () {
              // Hilangkan focus dari search field ketika tap di area lain
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
}
