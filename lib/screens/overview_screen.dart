// lib/screens/overview_screen.dart

import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../screens/create_listing_screen.dart';
import '../screens/favorites_screen.dart';

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

        // Get follower counts
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
            child: const Icon(Icons.arrow_back, color: Colors.black87),
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
              backgroundColor: Colors.white,
              backgroundImage: userProfilePicture != null && userProfilePicture!.isNotEmpty
                  ? NetworkImage(userProfilePicture!)
                  : null,
              child: userProfilePicture == null || userProfilePicture!.isEmpty
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                    )
                  : null,
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOverviewData,
              color: Colors.red,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          icon: Icons.shopping_bag_outlined,
                          value: sellingItems.length.toString(),
                          label: 'Active Listings',
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          icon: Icons.check_circle_outlined,
                          value: soldItems.length.toString(),
                          label: 'Sold Items',
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          icon: Icons.attach_money,
                          value: 'PKR ${totalEarnings.toStringAsFixed(0)}',
                          label: 'Total Earnings',
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          icon: Icons.people_outline,
                          value: totalFollowers.toString(),
                          label: 'Followers',
                          color: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CreateListingScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.favorite_outline,
                            label: 'Favorites',
                            color: Colors.red,
                            onTap: () {
                              Navigator.push(
                                context,
                             MaterialPageRoute(builder: (context) => FavoritesScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Recent Activity
                    const Text(
                      'Recent Activity',
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
                              Icon(Icons.history, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No recent activity',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      ...sellingItems.take(3).map((product) => _buildRecentItem(product, isSold: false)),
                      ...soldItems.take(2).map((product) => _buildRecentItem(product, isSold: true)),
                    ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(Product product, {required bool isSold}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: product.photoUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.photoUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.photoUrls.isEmpty
                ? Icon(Icons.image, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSold ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
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
                    const SizedBox(width: 8),
                    Text(
                      'PKR ${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
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
}