import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screens/login.dart';
import '../screens/signup.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/cart_screen.dart'; 
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../screens/create_listing_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/overview_screen.dart';
import '../screens/my_listings_screen.dart';
import '../screens/sold_items_screen.dart';

class CustomNavbar extends StatefulWidget implements PreferredSizeWidget {
  const CustomNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar> {
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

  void _navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      automaticallyImplyLeading: false,
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
                icon: const FaIcon(FontAwesomeIcons.bars, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            ),
            child: Image.asset('assets/logo.png', height: 40),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 20),
            _menuItem('Home', () => _navigateToHome(context)),
            _menuItem('Item 1', () {}),
            _menuItem('Item 2', () {}),
          ],
        ],
      ),
      actions: [
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
                  icon: const FaIcon(FontAwesomeIcons.cartShopping, color: Colors.red),
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
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
                radius: 20,
                backgroundImage: NetworkImage(_profilePicture!),
                backgroundColor: Colors.grey[200],
                child: _userName != null && _userName!.isNotEmpty
                    ? null
                    : const Icon(Icons.person, color: Colors.grey),
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
                radius: 20,
                backgroundColor: Colors.red,
                child: _userName != null && _userName!.isNotEmpty && _userName!.length >= 1
                    ? Text(
                        _userName![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
            ),
          )
        else
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ).then((_) {
              _loadUserData();
            }),
            child: const Text('Login', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _menuItem(String text, VoidCallback onPressed) => TextButton(
    onPressed: onPressed,
    child: Text(text, style: const TextStyle(color: Colors.black)),
  );
}

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
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
              _userName = userData['username']?.toString() ?? 'User';
            }
          } catch (e) {
            print('Error parsing user data: $e');
          }
        }
      });
    }
  }

  // NEW NAVIGATION METHODS
  void _navigateToOverview(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OverviewScreen()),
    );
  }

  void _navigateToMyListings(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyListingsScreen()),
    );
  }

  void _navigateToSoldItems(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SoldItemsScreen()),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _navigateToCreateListing(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateListingScreen()),
    );
  }

  void _navigateToProfile(BuildContext context, {int? tab}) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) {
      _loadUserData();
    });
  }

  void _navigateToFavorites(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  }

  void _navigateToCart(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    ).then((_) {
      _loadUserData();
    });
  }

  void _navigateToSignup(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade700,
                    Colors.red.shade400,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoggedIn) ...[
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.white,
                                backgroundImage: _profilePicture != null && _profilePicture!.isNotEmpty
                                    ? NetworkImage(_profilePicture!)
                                    : null,
                                child: _profilePicture == null || _profilePicture!.isEmpty
                                    ? Text(
                                        _userName![0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _userName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Login to continue',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildSectionTitle('MAIN'),
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () => _navigateToHome(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Overview',
                    onTap: () => _navigateToOverview(context),
                  ),
                  
                  const Divider(height: 24, thickness: 1),
                  
                  _buildSectionTitle('SELLING'),
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline,
                    title: 'Create Listing',
                    onTap: () => _navigateToCreateListing(context),
                    iconColor: Colors.green,
                    badge: 'New',
                  ),
                  _buildDrawerItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Listings',
                    onTap: () => _navigateToMyListings(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.check_circle_outline,
                    title: 'Sold Items',
                    onTap: () => _navigateToSoldItems(context),
                  ),
                  
                  const Divider(height: 24, thickness: 1),
                  
                  _buildSectionTitle('ACCOUNT'),
                  if (_isLoggedIn) ...[
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () => _navigateToProfile(context),
                    ),
                    _buildDrawerItem(
                      icon: Icons.favorite_outline,
                      title: 'Favorites',
                      onTap: () => _navigateToFavorites(context),
                    ),
                    _buildDrawerItem(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Cart',
                      onTap: () => _navigateToCart(context),
                    ),
                  ] else ...[
                    _buildDrawerItem(
                      icon: Icons.login_outlined,
                      title: 'Login',
                      onTap: () => _navigateToLogin(context),
                    ),
                    _buildDrawerItem(
                      icon: Icons.person_add_outlined,
                      title: 'Sign Up',
                      onTap: () => _navigateToSignup(context),
                    ),
                  ],
                  
                  const Divider(height: 24, thickness: 1),
                  
                  _buildSectionTitle('SUPPORT'),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () => _showComingSoon(context, 'Help Center'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.message_outlined,
                    title: 'Contact Us',
                    onTap: () => _showComingSoon(context, 'Contact Us'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () => _showComingSoon(context, 'About'),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  if (_isLoggedIn) ...[
                    const Divider(height: 24, thickness: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    String? badge,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.red).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.red,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}