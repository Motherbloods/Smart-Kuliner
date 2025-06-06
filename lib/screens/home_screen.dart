import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/searchable.dart';

import './beranda_screen.dart';
import './konten_screen.dart';
import './edukasi_screen.dart';
import './profile_screen.dart';

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

  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navBarItems;

  @override
  void initState() {
    super.initState();
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
      // Seller: Tampilkan semua 4 screen
      _screens = [
        BerandaScreen(),
        KontenScreen(),
        EdukasiScreen(),
        ProfileScreen(),
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
      // User biasa: Hanya Beranda dan Profil
      _screens = [BerandaScreen(), ProfileScreen()];
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

    // Notify current screen if it's searchable
    if (_screens[_selectedIndex] is Searchable) {
      (_screens[_selectedIndex] as Searchable).onSearch('');
    }
  }

  bool _isBerandaScreen() {
    // Cek apakah screen saat ini adalah BerandaScreen
    return _screens[_selectedIndex] is BerandaScreen;
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
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _isBerandaScreen()
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 80,
                  flexibleSpace: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F3F4),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                  // Pass search query to BerandaScreen
                                  if (_screens[_selectedIndex] is Searchable) {
                                    (_screens[_selectedIndex] as Searchable)
                                        .onSearch(value);
                                  }
                                },
                                onSubmitted: (value) {
                                  // Hilangkan focus setelah submit
                                  _searchFocusNode.unfocus();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Cari produk kuliner...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? GestureDetector(
                                          onTap: _clearSearch,
                                          child: Icon(
                                            Icons.clear,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFF6B35),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                )
              : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 60,
                  flexibleSpace: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getScreenTitle(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Beranda';
      case 1:
        return _screens.length > 2 ? 'Konten' : 'Profil';
      case 2:
        return 'Edukasi';
      case 3:
        return 'Profil';
      default:
        return '';
    }
  }
}
