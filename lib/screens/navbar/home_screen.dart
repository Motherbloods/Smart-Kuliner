import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/widgets/custom_search_bar.dart';
import '../../providers/auth_provider.dart';

import 'beranda_screen.dart';
import 'konten_screen.dart';
import 'edukasi_screen.dart';
import 'profile_screen.dart';
import 'search_results_screen.dart'; // Import screen baru

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late BerandaScreen _berandaScreen;
  late KontenScreen _kontenScreen;
  late EdukasiScreen _edukasiScreen;
  late ProfileScreen _profileScreen;

  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navBarItems;

  @override
  void initState() {
    super.initState();

    // Initialize screen instances once
    _berandaScreen = BerandaScreen();
    _kontenScreen = KontenScreen();
    _edukasiScreen = EdukasiScreen();
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
      // Seller: Tampilkan semua 4 screen - menggunakan instance yang sudah ada
      _screens = [
        _berandaScreen,
        _kontenScreen,
        _edukasiScreen,
        _profileScreen,
      ];
      _navBarItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          activeIcon: Icon(Icons.article),
          label: 'Konten',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Edukasi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else {
      // User biasa: Hanya Beranda dan Profil - menggunakan instance yang sudah ada
      _screens = [_berandaScreen, _profileScreen];
      _navBarItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
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
      _searchQuery = '';
      _searchController.clear();
      _searchFocusNode.unfocus(); // Hilangkan focus dari search
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
    });
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  bool _isBerandaScreen() {
    return _screens[_selectedIndex] is BerandaScreen;
  }

  void _performSearch() {
    if (_searchQuery.trim().isNotEmpty) {
      _searchFocusNode.unfocus();
      print('🔍 Navigating to search results: $_searchQuery');

      // Simpan query sebelum navigasi
      final queryToSearch = _searchQuery.trim();

      // Navigasi ke halaman hasil pencarian
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(query: queryToSearch),
        ),
      ).then((_) {
        // Clear search SETELAH kembali dari halaman search results
        _clearSearch();
      });
    } else {
      print('🔍 Search query is empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        // Reinitialize jika user data berubah (tanpa membuat instance baru)
        if (authProvider.currentUser != null) {
          _initializeScreensAndNavBar();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _isBerandaScreen()
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: CustomSearchBar(
                        searchController: _searchController,
                        searchFocusNode: _searchFocusNode,
                        searchQuery: _searchQuery,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onClear: () {
                          _clearSearch();
                        },
                        onSearch: () {
                          _performSearch();
                        },
                      ),
                    ),
                  ),
                )
              : null,
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
              selectedItemColor: const Color(0xFFFF6B35),
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
