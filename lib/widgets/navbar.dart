import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screens/login.dart';
import '../screens/signup.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

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
        IconButton(
          onPressed: () {},
          icon: const FaIcon(FontAwesomeIcons.cartShopping, color: Colors.red),
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

  void _navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _navigateToHome(context),
                  child: Image.asset('assets/logo.png', height: 60),
                ),
                const SizedBox(height: 10),
                if (_isLoggedIn && _userName != null && _userName!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      ).then((_) {
                        _loadUserData();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Hi, $_userName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _drawerItem(FontAwesomeIcons.house, 'Home', () => _navigateToHome(context)),
          if (_isLoggedIn)
            _drawerItem(FontAwesomeIcons.user, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) {
                _loadUserData();
              });
            })
          else
            _drawerItem(FontAwesomeIcons.signInAlt, 'Login', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ).then((_) {
                _loadUserData();
              });
            }),
          if (!_isLoggedIn)
            _drawerItem(FontAwesomeIcons.userPlus, 'Sign Up', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              );
            }),
          if (_isLoggedIn)
            _drawerItem(FontAwesomeIcons.rightFromBracket, 'Logout', () => _logout(context)),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: FaIcon(icon, color: Colors.red),
    title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    hoverColor: Colors.red.shade50,
    onTap: onTap,
  );

  void _navigateToHome(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
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
}