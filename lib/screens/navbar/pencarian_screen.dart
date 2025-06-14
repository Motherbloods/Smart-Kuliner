import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../search_results_screen.dart';

class PencarianScreen extends StatefulWidget {
  const PencarianScreen({Key? key}) : super(key: key);

  @override
  State<PencarianScreen> createState() => _PencarianScreenState();
}

class _PencarianScreenState extends State<PencarianScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];

  List<String> _popularSearches = [
    'Ayam goreng',
    'Es teh',
    'Nasi gudeg',
    'Bakso',
    'Sate ayam',
    'Gado-gado',
    'Rendang',
    'Martabak',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Load search history from SharedPreferences
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  // Save search history to SharedPreferences
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  // Add search to history
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();

    setState(() {
      // Remove if already exists
      _searchHistory.remove(trimmedQuery);

      // Add to beginning
      _searchHistory.insert(0, trimmedQuery);

      // Keep only last 10 searches
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
    });

    _saveSearchHistory();
  }

  // Remove item from search history
  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
    _saveSearchHistory();
  }

  // Clear all search history
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }

  // Perform search
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();

    // Add to history
    _addToSearchHistory(trimmedQuery);

    // Clear search field
    _searchController.clear();
    _searchFocusNode.unfocus();

    // Navigate to search results
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: trimmedQuery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pencarian',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          _searchFocusNode.unfocus();
        },
        child: Column(
          children: [
            // Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Cari makanan atau konten edukasi...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: Icon(Icons.clear, color: Colors.grey[500]),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  onSubmitted: _performSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search History Section
                    if (_searchHistory.isNotEmpty) ...[
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Riwayat Pencarian',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _clearSearchHistory,
                                  child: const Text(
                                    'Hapus Semua',
                                    style: TextStyle(
                                      color: Color(0xFF4DA8DA),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...(_searchHistory
                                .take(5)
                                .map((query) => _buildHistoryItem(query))
                                .toList()),
                          ],
                        ),
                      ),
                    ],

                    // Popular Searches Section
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pencarian Populer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularSearches
                                .map(
                                  (search) => _buildPopularSearchChip(search),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Search Tips
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tips Pencarian',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTipItem(
                            Icons.search,
                            'Gunakan kata kunci yang spesifik',
                            'Contoh: "ayam goreng crispy" lebih baik dari "ayam"',
                          ),
                          _buildTipItem(
                            Icons.category,
                            'Cari berdasarkan kategori',
                            'Contoh: "minuman segar", "makanan sehat"',
                          ),
                          _buildTipItem(
                            Icons.school,
                            'Temukan konten edukasi',
                            'Cari tutorial memasak dan tips kuliner',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String query) {
    return InkWell(
      onTap: () => _performSearch(query),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.history, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            IconButton(
              onPressed: () => _removeFromHistory(query),
              icon: Icon(Icons.close, size: 18, color: Colors.grey[500]),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSearchChip(String search) {
    return GestureDetector(
      onTap: () => _performSearch(search),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              search,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4DA8DA)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
