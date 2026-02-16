// lib/screens/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/create_listing_screen.dart';


    
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0; // 0 = Selling, 1 = Sold
  List<Product> sellingItems = [];
  List<Product> soldItems = [];
  bool _isLoading = true;
  String userName = '';
  String userEmail = '';
  String? userProfilePicture;
  String? authToken;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Test the CORRECT endpoint after a delay
    Future.delayed(Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        await ApiService.testBackendEndpoints(token);
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
      
      // Load user profile data
      final userDataJson = prefs.getString('user_data');
      if (userDataJson != null) {
        try {
          final Map<String, dynamic> userData = json.decode(userDataJson);
          print('📊 User data found: ${userData.keys}');
          
          final firstName = userData['first_name']?.toString() ?? '';
          final lastName = userData['last_name']?.toString() ?? '';
          final username = userData['username']?.toString() ?? '';
          final email = userData['email']?.toString() ?? '';
          final profilePicture = userData['profile_picture']?.toString();
          
          print('📊 First Name: $firstName');
          print('📊 Last Name: $lastName');
          print('📊 Username: $username');
          print('📊 Email: $email');
          
          setState(() {
            // Combine first and last name if available
            if (firstName.isNotEmpty && lastName.isNotEmpty) {
              userName = '$firstName $lastName';
            } else if (firstName.isNotEmpty) {
              userName = firstName;
            } else if (lastName.isNotEmpty) {
              userName = lastName;
            } else if (username.isNotEmpty) {
              userName = username;
            } else {
              userName = 'User';
            }
            
            userEmail = email.isNotEmpty ? email : 'No email';
            userProfilePicture = profilePicture;
          });
        } catch (e) {
          print('❌ Error parsing user data JSON: $e');
          setState(() {
            userName = 'Error loading data';
            userEmail = 'Please log in again';
          });
        }
      } else {
        print('❌ No user data found in shared preferences');
        setState(() {
          userName = 'Not logged in';
          userEmail = 'Please log in';
        });
      }

      // Fetch products using the CORRECT endpoint
      if (authToken != null && authToken!.isNotEmpty) {
        print('🔑 Token available, fetching user products...');
        
        try {
          // Use the new method that calls the correct endpoint
          final allProducts = await ApiService.getUserProducts(authToken!);
          
          if (allProducts.isNotEmpty) {
            print('✅ Found ${allProducts.length} total user products');
            
            // Filter active vs sold products
            final activeProducts = allProducts.where((product) {
              return product.sold == false && product.active == true;
            }).toList();
            
            final soldProducts = allProducts.where((product) {
              return product.sold == true || product.active == false;
            }).toList();
            
            setState(() {
              sellingItems = activeProducts;
              soldItems = soldProducts;
            });
            
            print('📈 Stats: ${sellingItems.length} selling, ${soldItems.length} sold');
          } else {
            print('ℹ️ No products found for this user');
            setState(() {
              sellingItems = [];
              soldItems = [];
            });
          }
        } catch (e) {
          print('❌ Error fetching products: $e');
          setState(() {
            sellingItems = [];
            soldItems = [];
          });
        }
      } else {
        print('🔒 No token available');
        setState(() {
          sellingItems = [];
          soldItems = [];
        });
      }
    } catch (e) {
      print('❌ Error in _loadUserData: $e');
      setState(() {
        userName = 'Error loading data';
        userEmail = 'Please try again';
        sellingItems = [];
        soldItems = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              ),
              child: Image.asset('assets/logo.png', height: 40),
            ),
          ],
        ),
        actions: [
          if (authToken != null && userProfilePicture != null && userProfilePicture!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(userProfilePicture!),
                backgroundColor: Colors.grey[200],
              ),
            )
          else if (authToken != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.red,
                child: userName.isNotEmpty && userName.length >= 1
                    ? Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: _isLoading
            ? _buildLoading()
            : Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(),
                  
                  // Tabs for Selling/Sold
                  _buildTabBar(),
                  
                  // Products area - takes remaining space
                  Expanded(
                    child: _selectedTab == 0
                        ? _buildSellingItems()
                        : _buildSoldItems(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading your profile...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          userProfilePicture != null && userProfilePicture!.isNotEmpty
              ? CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(userProfilePicture!),
                  backgroundColor: Colors.blue[100],
                  onBackgroundImageError: (exception, stackTrace) {
                    print('❌ Error loading profile picture: $exception');
                  },
                )
              : CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blue[800],
                  ),
                ),
          const SizedBox(height: 16),

          // User Name
          Text(
            userName.isNotEmpty ? userName : 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Email
          if (userEmail.isNotEmpty && userEmail != 'No email')
            Text(
              userEmail,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 8),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Selling', sellingItems.length.toString()),
              _buildStat('Sold', soldItems.length.toString()),
              _buildStat('Rating', authToken != null ? '⭐' : '-'),
            ],
          ),

          // Show connection status
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                authToken != null ? Icons.check_circle : Icons.warning,
                size: 14,
                color: authToken != null ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                authToken != null ? 'Signed In' : 'Not Signed In',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.blue : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Currently Selling',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 0 ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.green : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Sold History',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 1 ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellingItems() {
    if (sellingItems.isEmpty) {
      return Center(
        child: _buildEmptyState(
          icon: Icons.store,
          message: 'No items currently selling',
          actionText: 'Start Selling',
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateListingScreen()),
            );
          },
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sellingItems.length,
      itemBuilder: (context, index) {
        return _buildProductItem(sellingItems[index], isSold: false);
      },
    );
  }

  Widget _buildSoldItems() {
    if (soldItems.isEmpty) {
      return Center(
        child: _buildEmptyState(
          icon: Icons.check_circle_outline,
          message: 'No sold items yet',
          actionText: 'Start Selling',
          onAction: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sell item feature coming soon!'),
              ),
            );
          },
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: soldItems.length,
      itemBuilder: (context, index) {
        return _buildProductItem(soldItems[index], isSold: true);
      },
    );
  }

  Widget _buildProductItem(Product product, {bool isSold = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: product.photoUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                       product.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: Colors.grey,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag,
                      size: 40,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSold ? Colors.green[700] : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (product.categoryName != null && product.categoryName!.isNotEmpty)
                    Text(
                      product.categoryName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSold ? Colors.green[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSold ? Colors.green : Colors.blue,
                  width: 1,
                ),
              ),
              child: Text(
                isSold ? 'SOLD' : 'SELLING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSold ? Colors.green : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}