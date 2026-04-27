import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../widgets/navbar.dart';
import '../product/create_listing_screen.dart';
import '../product/favorites_screen.dart';
import '../auth/login.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../profile/widgets/edit_product_dialog.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  List<Product> sellingItems = [];
  List<Product> soldItems = [];
  bool _isLoading = true;
  String userName = '';
  String userEmail = '';
  String? userProfilePicture;
  double totalEarnings = 0.0;
  int totalFollowers = 0;
  int totalFollowing = 0;
  String memberSince = '';

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userDataJson = prefs.getString('user_data');

      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        final firstName = userData['first_name']?.toString() ?? '';
        final lastName = userData['last_name']?.toString() ?? '';
        final email = userData['email']?.toString() ?? '';
        final profilePicture = userData['profile_picture']?.toString();
        final createdAt = userData['created_at']?.toString() ?? '';

        userName = firstName.isNotEmpty && lastName.isNotEmpty 
            ? '$firstName $lastName' 
            : userData['username'] ?? 'User';
        userEmail = email;
        userProfilePicture = profilePicture;

        if (createdAt.isNotEmpty) {
          try {
            final date = DateTime.parse(createdAt);
            memberSince = DateFormat('MMM yyyy').format(date);
          } catch (e) {
            memberSince = createdAt.length >= 4 ? createdAt.substring(0, 4) : '';
          }
        }

        totalFollowers = userData['followers_count'] ?? 0;
        totalFollowing = userData['following_count'] ?? 0;
      }

      if (token != null) {
        final allProducts = await ApiService.getUserProducts(token);
        
        if (allProducts.isNotEmpty) {
          sellingItems = allProducts.where((p) => p.sold == false && p.active == true).toList();
          soldItems = allProducts.where((p) => p.sold == true || p.active == false).toList();
          totalEarnings = soldItems.fold(0.0, (sum, p) => sum + p.price);
        }
      }
    } catch (e) {
      print('❌ Error loading overview: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAuthAndNavigate(Widget destination) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null && token.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      _showLoginRequiredDialog();
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to be logged in to create a listing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: userProfilePicture != null && userProfilePicture!.isNotEmpty
                  ? NetworkImage(fixImageUrl(userProfilePicture!))
                  : null,
              child: userProfilePicture == null || userProfilePicture!.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Colors.grey)
                  : null,
            ),
          ),
        ],
      ),
      
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : RefreshIndicator(
              onRefresh: _loadOverviewData,
              color: Colors.red,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade700, Colors.red.shade400],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats Row (2 rows of 2)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(
                              icon: Icons.shopping_bag_outlined,
                              value: sellingItems.length.toString(),
                              label: 'Active',
                              color: Colors.blue,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              icon: Icons.check_circle_outlined,
                              value: soldItems.length.toString(),
                              label: 'Sold',
                              color: Colors.green,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(
                              icon: Icons.attach_money,
                              value: 'PKR ${totalEarnings.toStringAsFixed(0)}',
                              label: 'Earnings',
                              color: Colors.orange,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              icon: Icons.people_outline,
                              value: totalFollowers.toString(),
                              label: 'Followers',
                              color: Colors.purple,
                            )),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.add_circle_outline,
                            label: 'Create Listing',
                            color: Colors.green,
                            onTap: () => _checkAuthAndNavigate(const CreateListingScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.favorite_outline,
                            label: 'Favorites',
                            color: Colors.red,
                            onTap: () => _checkAuthAndNavigate(const FavoritesScreen()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                                // My Products
                    const Text(
                      'My Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (sellingItems.isEmpty && soldItems.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.storefront_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No products yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _checkAuthAndNavigate(const CreateListingScreen()),
                                icon: const Icon(Icons.add_circle_outline, size: 16),
                                label: const Text('Create Listing'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ...sellingItems.map((product) => _buildProductItem(product, isSold: false)),
                          ...soldItems.map((product) => _buildProductItem(product, isSold: true)),
                        ],
                      ),



                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(Product product, {required bool isSold}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 55,
              height: 55,
              color: Colors.grey[200],
              child: product.photoUrls.isNotEmpty
                  ? Image.network(
                      fixImageUrl(product.photoUrls.first),
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey[400], size: 30),
                    )
                  : Icon(Icons.image, color: Colors.grey[400], size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSold ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSold ? 'Sold' : 'Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSold ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'PKR ${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

   

   Widget _buildProductItem(Product product, {required bool isSold}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade100,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 60,
            height: 60,
            color: Colors.grey[200],
            child: product.photoUrls.isNotEmpty
                ? Image.network(
                    fixImageUrl(product.photoUrls.first),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey[400], size: 30),
                  )
                : Icon(Icons.image, color: Colors.grey[400], size: 30),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSold ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSold ? 'Sold' : 'Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSold ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PKR ${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Edit and Delete buttons
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
              onPressed: () => _showEditProductDialog(product),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmDeleteProduct(product),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    ),
  );
}


void _confirmDeleteProduct(Product product) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Product'),
      content: Text('Are you sure you want to delete "${product.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('CANCEL')
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null) {
              final success = await ApiService.deleteProduct(productId: product.id.toString());
              if (success) {
                _loadOverviewData(); // Refresh the list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete product'), backgroundColor: Colors.red),
                );
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('DELETE'),
        ),
      ],
    ),
  );
}

void _showEditProductDialog(Product product) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EditProductDialog(
      product: product,
      onProductUpdated: () => _loadOverviewData(),
    ),
  );
}
}