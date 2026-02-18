// lib/widgets/global_search_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/search_service.dart';
import '../screens/search_results_screen.dart';
import '../screens/login.dart';
import '../screens/profile_screen.dart';
import '../screens/cart_screen.dart';
import '../providers/cart_provider.dart';
import '../screens/favorites_screen.dart'; // Add this import

class GlobalSearchBar extends StatefulWidget implements PreferredSizeWidget {
  const GlobalSearchBar({super.key});

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  
  // Add these from CustomNavbar
  String? _profilePicture;
  String? _userName;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  // Add this method from CustomNavbar
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userDataJson = prefs.getString('user_data');
    
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        
        if (userDataJson != null) {
          try {
            final Map<String, dynamic> userData = json.decode(userDataJson);
            _profilePicture = userData['profile_picture']?.toString();
            final firstName = userData['first_name']?.toString() ?? '';
            final lastName = userData['last_name']?.toString() ?? '';
            _userName = '$firstName $lastName'.trim();
            if (_userName!.isEmpty) {
              _userName = userData['username']?.toString();
            }
          } catch (e) {
            print('Error parsing user data: $e');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: _showSearch
          ? Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _showSearch = false;
                        _searchController.clear();
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    final results = SearchService.search(query);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchResultsScreen(
                          query: query,
                          results: results,
                        ),
                      ),
                    );
                    
                    setState(() {
                      _showSearch = false;
                      _searchController.clear();
                    });
                  }
                },
              ),
            )
          : GestureDetector(
              onTap: () {
                setState(() {
                  _showSearch = true;
                });
              },
              child: Text(
                'Closyyyy', // Keep your brand text
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
      actions: [
        // Search icon (shows when search is closed)
        if (!_showSearch)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              setState(() {
                _showSearch = true;
              });
            },
          ),
        
      IconButton(
  icon: const Icon(Icons.favorite_border, color: Colors.black87),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  },
),
        
        // CART WITH BADGE (from CustomNavbar)
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            final itemCount = cartProvider.totalQuantity;
            return Stack(
              children: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87), // or use FaIcon if you prefer
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : itemCount.toString(),
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
        
        // PROFILE/LOGIN SECTION (from CustomNavbar)
        if (_isLoggedIn && _profilePicture != null && _profilePicture!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) {
                _loadUserData();
              }),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(_profilePicture!),
                backgroundColor: Colors.grey[200],
                child: _userName != null && _userName!.isNotEmpty
                    ? null
                    : const Icon(Icons.person, size: 18, color: Colors.grey),
              ),
            ),
          )
        else if (_isLoggedIn)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) {
                _loadUserData();
              }),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.red,
                child: _userName != null && _userName!.isNotEmpty && _userName!.length >= 1
                    ? Text(
                        _userName![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : const Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ).then((_) {
                _loadUserData();
              }),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Login', 
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        
        const SizedBox(width: 4), // Small spacing at the end
      ],
    );
  }
}