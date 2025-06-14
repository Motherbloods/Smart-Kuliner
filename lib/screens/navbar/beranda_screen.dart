// beranda_screen.dart - Main screen file
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/utils/searchable.dart';
import 'package:smart/models/user.dart';
import 'package:smart/providers/auth_provider.dart';
import 'package:smart/screens/beranda/beranda_data_manager.dart';
import 'package:smart/screens/beranda/beranda_user_view.dart';
import 'package:smart/screens/beranda/beranda_seller_view.dart';

class BerandaScreen extends StatefulWidget implements Searchable {
  BerandaScreen({Key? key}) : super(key: key);

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();

  @override
  void onSearch(String query) {
    print('🔍 Menerima query pencarian: $query');
    if (_state != null) {
      print('🔍 Memanggil _performSearch di state');
      _state!._performSearch(query);
    } else {
      print('🔍 ERROR: _state is null!');
    }
  }

  // ignore: prefer_final_fields, diagnostic_describe_all_properties

  _BerandaScreenState? _state;
}

class _BerandaScreenState extends State<BerandaScreen> {
  late final BerandaDataManager _dataManager;

  String _activeSearchQuery = '';
  bool _isSearchActive = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    widget._state = this;
    _dataManager = BerandaDataManager();
    _loadCurrentUser();
    print('🔍 BerandaScreen initState - _state di-set');
  }

  @override
  void dispose() {
    widget._state = null;
    _dataManager.dispose();
    print('🔍 BerandaScreen dispose - _state di-clear');
    super.dispose();
  }

  void _loadCurrentUser() {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    _currentUser = authProvider.currentUser;
    _dataManager.loadData(_currentUser);
  }

  void _performSearch(String query) {
    print('🔍 Melakukan pencarian untuk: $query');
    if (mounted) {
      setState(() {
        _activeSearchQuery = query.trim();
        _isSearchActive = query.trim().isNotEmpty;
      });
      print(
        '🔍 Search berhasil di-set: $_activeSearchQuery, isActive: $_isSearchActive',
      );
    } else {
      print('🔍 ERROR: Widget not mounted!');
    }
  }

  void _refreshData() {
    _dataManager.refreshData(_currentUser);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        final isSeller = authProvider.currentUser?.seller ?? false;

        return Scaffold(
          backgroundColor: Colors.white,
          body: RefreshIndicator(
            onRefresh: () async {
              _refreshData();
            },
            child: StreamBuilder<BerandaState>(
              stream: _dataManager.stateStream,
              builder: (context, snapshot) {
                final state = snapshot.data ?? BerandaState();

                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4DA8DA)),
                  );
                }

                return isSeller
                    ? BerandaSellerView(
                        state: state,
                        activeSearchQuery: _activeSearchQuery,
                        isSearchActive: _isSearchActive,
                        onRefresh: _refreshData,
                        onCategoryChanged: _dataManager.setSelectedCategory,
                      )
                    : BerandaUserView(state: state, onRefresh: _refreshData);
              },
            ),
          ),
        );
      },
    );
  }
}
