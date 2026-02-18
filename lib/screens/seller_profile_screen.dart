// lib/screens/seller_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/follow_provider.dart';
import '../models/product.dart' as product_model;
import 'dart:async';

// Models
class Seller {
  final String id;
  final String name;
  final String avatarUrl;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int productCount;
  final String joinedDate;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String? shopName;
  final String? location;
  
  Seller({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.productCount,
    required this.joinedDate,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.shopName,
    this.location,
  });



factory Seller.fromJson(Map<String, dynamic> json) {
  print('🔄 Parsing Seller JSON: $json'); // DEBUG LINE
  
  // Parse date
  String joinedDate = 'Recently';
  if (json['created_at'] != null) {
    try {
      final date = DateTime.parse(json['created_at']);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays < 30) {
        joinedDate = '${difference.inDays} days ago';
      } else if (difference.inDays < 365) {
        joinedDate = '${(difference.inDays / 30).floor()} months ago';
      } else {
        joinedDate = '${(difference.inDays / 365).floor()} years ago';
      }
    } catch (e) {
      joinedDate = json['created_at']?.toString() ?? 'Recently';
    }
  }

  // Extract values with multiple possible keys
  final id = json['id']?.toString() ?? 
              json['user_id']?.toString() ?? 
              json['userId']?.toString() ?? '';
              
  // FIX: Use username if first_name/last_name not available
  final firstName = json['first_name'] ?? '';
  final lastName = json['last_name'] ?? '';
  final username = json['username'] ?? 'Unknown';
  
  final name = '$firstName $lastName'.trim().isNotEmpty 
      ? '$firstName $lastName'.trim() 
      : username;
               
  final avatarUrl = json['avatar'] ?? 
                    json['profile_picture'] ?? 
                    json['profile_image'] ?? 
                    json['avatar_url'] ?? 
                    'https://via.placeholder.com/150';
                    
  final bio = json['bio'] ?? 
              json['description'] ?? 
              json['about'] ?? 
              'No bio available';
              
  // Handle followers count - could be int or string
  dynamic followersRaw = json['followers_count'] ?? 
                         json['total_followers'] ?? 
                         json['followers'] ?? 
                         0;
  final followersCount = followersRaw is String 
      ? int.tryParse(followersRaw) ?? 0 
      : followersRaw is int ? followersRaw : 0;
                         
  // Handle following count
  dynamic followingRaw = json['following_count'] ?? 
                         json['total_following'] ?? 
                         json['following'] ?? 
                         0;
  final followingCount = followingRaw is String 
      ? int.tryParse(followingRaw) ?? 0 
      : followingRaw is int ? followingRaw : 0;
                         
  // Handle product count
  dynamic productsRaw = json['products_count'] ?? 
                        json['total_products'] ?? 
                        json['products'] ?? 
                        0;
  final productCount = productsRaw is String 
      ? int.tryParse(productsRaw) ?? 0 
      : productsRaw is int ? productsRaw : 0;
                       
  // Handle rating
  dynamic ratingRaw = json['rating'] ?? 
                      json['average_rating'] ?? 
                      json['avg_rating'] ?? 
                      0.0;
  final rating = ratingRaw is String 
      ? double.tryParse(ratingRaw) ?? 0.0 
      : ratingRaw is double ? ratingRaw 
      : ratingRaw is int ? ratingRaw.toDouble() 
      : 0.0;
                  
  // Handle review count
  dynamic reviewsRaw = json['reviews_count'] ?? 
                       json['total_reviews'] ?? 
                       json['reviews'] ?? 
                       0;
  final reviewCount = reviewsRaw is String 
      ? int.tryParse(reviewsRaw) ?? 0 
      : reviewsRaw is int ? reviewsRaw : 0;
                      
  final isVerified = json['is_verified'] == 1 || 
                     json['verified'] == true || 
                     json['verified'] == 1;
                     
  // Extract shop name from nested shop object if available
 // In the shop name section of Seller.fromJson, update:

// Extract shop name from nested shop object if available
String? shopName;
if (json['shop'] != null && json['shop'] is Map) {
  // Try to get shop name from various possible fields
  shopName = json['shop']['name'] ?? 
             json['shop']['shop_name'] ?? 
             json['shop']['title'] ?? 
             json['shop']['description'] ??  // Add this line
             null;
}

// Also check if there's a direct description field (from your shop data)
if (shopName == null && json['description'] != null) {
  shopName = json['description'];
}

shopName ??= json['shop_name'] ?? json['store_name'] ?? null;
                   
  final location = json['location'] ?? 
                   json['city'] ?? 
                   json['address'] ?? 
                   null;

  print('✅ Parsed values:');
  print('  - id: $id');
  print('  - name: $name');
  print('  - followers: $followersCount');
  print('  - products: $productCount');
  print('  - rating: $rating');
  print('  - shopName: $shopName');
  print('  - location: $location');

  return Seller(
    id: id,
    name: name,
    avatarUrl: avatarUrl,
    bio: bio,
    followersCount: followersCount,
    followingCount: followingCount,
    productCount: productCount,
    joinedDate: joinedDate,
    rating: rating,
    reviewCount: reviewCount,
    isVerified: isVerified,
    shopName: shopName,
    location: location,
  );
}
}

// Main Seller Profile Screen
class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String? initialSellerName;
  final String? initialSellerImage;
  
  const SellerProfileScreen({
    Key? key,
    required this.sellerId,
    this.initialSellerName,
    this.initialSellerImage,
  }) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> with SingleTickerProviderStateMixin {
  Seller? _seller;
  List<product_model.Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingProducts = true;
  String? _errorMessage;
  String _selectedTab = 'products'; // 'products' or 'about'
  late TabController _tabController;
  
  // Local state for fallback if provider is missing
  bool _localIsFollowing = false;
  int _localFollowersCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadSellerData();
    _loadSellerProducts();  // ← This calls the method below
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTab = _tabController.index == 0 ? 'products' : 'about';
      });
    }
  }

  // ============ ADD THIS MISSING METHOD ============
  Future<void> _loadSellerProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      // First try to get products from the shop endpoint (which we know has them)
      print('📦 Attempting to get products from shop endpoint...');
      final shopResult = await ApiService.getSellerShop(widget.sellerId);
      
      if (shopResult['success'] == true && shopResult['data'] != null) {
        final shopData = shopResult['data'];
        List<product_model.Product> extractedProducts = [];
        
        // Extract products from the nested structure
        if (shopData is Map) {
          // Check if products are in shopData['products']['data']
          if (shopData.containsKey('products')) {
            final productsData = shopData['products'];
            if (productsData is Map && productsData.containsKey('data')) {
              final productsList = productsData['data'] as List;
              print('📦 Found ${productsList.length} products in shop data');
              
              for (var productJson in productsList) {
                try {
                  final product = product_model.Product.fromJson(productJson);
                  extractedProducts.add(product);
                } catch (e) {
                  print('⚠️ Error parsing product: $e');
                }
              }
            }
          }
        }
        
        if (extractedProducts.isNotEmpty) {
          setState(() {
            _products = extractedProducts;
            _isLoadingProducts = false;
          });
          print('✅ Loaded ${extractedProducts.length} products from shop data');
          return;
        }
      }
      
      // Fallback to the regular seller products endpoint
      print('📦 Falling back to seller products endpoint...');
      final products = await ApiService.getSellerProducts(widget.sellerId);
      
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
      
      print('✅ Loaded ${products.length} products from seller endpoint');
      
    } catch (e) {
      print('❌ Error loading seller products: $e');
      setState(() {
        _products = [];
        _isLoadingProducts = false;
      });
    }
  }

  // ============ YOUR EXISTING _loadSellerData METHOD ============
  Future<void> _loadSellerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch seller profile
      print('📡 Fetching seller profile for ID: ${widget.sellerId}');
      final profileResult = await ApiService.getSellerProfile(widget.sellerId);
      
      print('📡 Profile Result: $profileResult');
      
      if (profileResult['success'] == true) {
        final profileData = profileResult['data'];
        print('📡 Profile Data: $profileData');
        
        // Fetch seller ratings
        print('📡 Fetching ratings...');
        final ratingsResult = await ApiService.getSellerRatings(widget.sellerId);
        print('📡 Ratings Result: $ratingsResult');
        
        // FIX: Extract rating from nested data if top-level average is 0
        double actualRating = ratingsResult['average'] ?? 0.0;
        int actualReviewCount = ratingsResult['count'] ?? 0;
        
        // Check if there's a nested average in the data
        if (actualRating == 0.0 && ratingsResult['data'] != null) {
          final data = ratingsResult['data'];
          if (data is Map) {
            if (data.containsKey('average') && data['average'] != null) {
              actualRating = (data['average'] is num) ? data['average'].toDouble() : 0.0;
            }
            if (data.containsKey('ratings') && data['ratings'] is List) {
              actualReviewCount = (data['ratings'] as List).length;
            }
          }
        }
        
        // Fetch seller shop info
        print('📡 Fetching shop info...');
        Map<String, dynamic> shopData = {};
        try {
          final shopResult = await ApiService.getSellerShop(widget.sellerId);
          print('📡 Shop Result: $shopResult');
          if (shopResult['success'] == true) {
            final shopResultData = shopResult['data'];
            if (shopResultData is Map) {
              if (shopResultData.containsKey('shop')) {
                shopData = shopResultData['shop'] is Map 
                    ? Map<String, dynamic>.from(shopResultData['shop']) 
                    : {};
              } else {
                shopData = Map<String, dynamic>.from(shopResultData);
              }
            }
          }
        } catch (e) {
          print('⚠️ Shop info not available: $e');
        }

        // CRITICAL FIX: Create cleaned profile data without the incorrect rating field
        Map<String, dynamic> cleanedProfileData = {};
        if (profileData is Map) {
          cleanedProfileData = Map<String, dynamic>.from(profileData);
          // Remove the rating field if it exists (it's 0.0 and incorrect)
          cleanedProfileData.remove('rating');
          print('🧹 Removed rating field from profile data');
        }
        
        final combinedData = {
          ...cleanedProfileData,
          ...shopData,
          // Now add the correct rating
          'rating': profileData is Map && profileData.containsKey('average_rating') 
              ? profileData['average_rating']  // Use average_rating from original
              : actualRating,
          'reviews_count': actualReviewCount,
        };
        
        print('📡 Combined Data: $combinedData');

        setState(() {
          _seller = Seller.fromJson(Map<String, dynamic>.from(combinedData));
          _localFollowersCount = _seller?.followersCount ?? 0;
          _isLoading = false;
        });
        
        print('✅ Seller created: ${_seller?.name}');
        print('✅ Followers: ${_seller?.followersCount}');
        print('✅ Products: ${_seller?.productCount}');
        print('⭐ FINAL RATING: ${_seller?.rating}');
        print('⭐ REVIEW COUNT: ${_seller?.reviewCount}');

        // Initialize follow provider if available
        try {
          final followProvider = Provider.of<FollowProvider>(context, listen: false);
          final isFollowing = await ApiService.checkIfFollowing(widget.sellerId);
          followProvider.initializeSeller(
            widget.sellerId,
            _seller?.followersCount ?? 0,
            isFollowing,
          );
        } catch (e) {
          print('⚠️ FollowProvider not available, using local state');
        }
      } else {
        setState(() {
          _errorMessage = profileResult['error'] ?? 'Failed to load seller profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  // ============ YOUR EXISTING _handleFollowToggle METHOD ============
  Future<void> _handleFollowToggle() async {
    // Try using provider first
    try {
      final followProvider = Provider.of<FollowProvider>(context, listen: false);
      final isFollowing = followProvider.isFollowing(widget.sellerId);
      
      // Call API
      bool success;
      if (isFollowing) {
        success = await ApiService.unfollowUser(widget.sellerId);
      } else {
        success = await ApiService.followUser(widget.sellerId);
      }
      
      if (success) {
        followProvider.toggleFollow(widget.sellerId);
        
        // Update local followers count
        setState(() {
          _localFollowersCount = isFollowing 
              ? _localFollowersCount - 1 
              : _localFollowersCount + 1;
        });
        
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFollowing 
                  ? 'Unfollowed ${_seller?.name ?? 'seller'}'
                  : 'Following ${_seller?.name ?? 'seller'}',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update follow status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fallback to local state if provider fails
      setState(() {
        _localIsFollowing = !_localIsFollowing;
        _localFollowersCount = _localIsFollowing 
            ? _localFollowersCount + 1 
            : _localFollowersCount - 1;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localIsFollowing 
                ? 'Following ${_seller?.name ?? 'seller'} (offline mode)'
                : 'Unfollowed ${_seller?.name ?? 'seller'} (offline mode)',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // ============ REST OF YOUR METHODS (build, _buildStatColumn, etc.) ============
  @override
  Widget build(BuildContext context) {
    // Your existing build method...
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 16),
              Text('Loading seller profile...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _seller == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Seller not found',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadSellerData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_seller!.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share seller profile
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // More options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar with verification badge
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(_seller!.avatarUrl),
                          onBackgroundImageError: (_, __) {
                            // Don't set state here, just let it show the fallback
                          },
                          backgroundColor: Colors.grey[200],
                          child: _seller!.avatarUrl.isEmpty || _seller!.avatarUrl == 'https://via.placeholder.com/150'
                              ? const Icon(Icons.person, size: 40, color: Colors.grey)
                              : null, // If image loads successfully, no child needed
                        ),
                        if (_seller!.isVerified)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Follow Stats
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(
                            'Products',
                            _seller!.productCount.toString(),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to followers list
                            },
                            child: _buildStatColumn(
                              'Followers',
                              _getFollowersCount().toString(),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to following list
                            },
                            child: _buildStatColumn(
                              'Following',
                              _seller!.followingCount.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Seller Info
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _seller!.shopName ?? _seller!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _seller!.rating > 0 ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _seller!.rating > 0 ? Icons.star : Icons.star_border,
                                  color: _seller!.rating > 0 ? Colors.amber : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                if (_seller!.rating > 0) ...[
                                  Text(
                                    _seller!.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ' (${_seller!.reviewCount})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'No ratings yet',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _seller!.bio,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Joined ${_seller!.joinedDate}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (_seller!.location != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _seller!.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Follow Button
                _buildFollowButton(),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.red,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'About'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Products Tab
                _isLoadingProducts
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : _products.isEmpty
                        ? _buildEmptyProducts()
                        : _buildProductsGrid(),
                
                // About Tab
                _buildAboutSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
    );
  }

  int _getFollowersCount() {
    try {
      final followProvider = Provider.of<FollowProvider>(context, listen: false);
      return followProvider.getFollowersCount(widget.sellerId);
    } catch (e) {
      return _localFollowersCount;
    }
  }

  bool _isFollowing() {
    try {
      final followProvider = Provider.of<FollowProvider>(context, listen: false);
      return followProvider.isFollowing(widget.sellerId);
    } catch (e) {
      return _localIsFollowing;
    }
  }

  Widget _buildFollowButton() {
    return Consumer<FollowProvider>(
      builder: (context, followProvider, child) {
        final isFollowing = _isFollowing();
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleFollowToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey[300] : Colors.red,
              foregroundColor: isFollowing ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyProducts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(product_model.Product product) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details
        Navigator.pop(context);
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          height: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      product.photoUrls.isNotEmpty 
                          ? product.photoUrls.first 
                          : 'https://via.placeholder.com/300x200',
                    ),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
                child: product.photoUrls.isEmpty 
                    ? Center(
                        child: Icon(Icons.broken_image, color: Colors.grey[400]),
                      )
                    : null,
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (product.conditionTitle != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.conditionTitle!,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.green[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Seller',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              _seller!.bio,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Seller Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.shop, 'Shop Name', _seller!.shopName ?? _seller!.name),
                _buildInfoRow(Icons.person, 'Seller Name', _seller!.name),
                if (_seller!.location != null)
                  _buildInfoRow(Icons.location_on, 'Location', _seller!.location!),
                _buildInfoRow(Icons.calendar_today, 'Member Since', _seller!.joinedDate),
                _buildInfoRow(
                  Icons.star, 
                  'Rating', 
                  _seller!.rating > 0 
                      ? '${_seller!.rating.toStringAsFixed(1)} (${_seller!.reviewCount} reviews)'
                      : 'No ratings yet',
                ),
                _buildInfoRow(Icons.inventory, 'Total Products', _seller!.productCount.toString()),
                _buildInfoRow(Icons.people, 'Total Followers', _getFollowersCount().toString()),
                _buildInfoRow(Icons.person_add, 'Following', _seller!.followingCount.toString()),
                if (_seller!.isVerified)
                  _buildInfoRow(Icons.verified, 'Verified Seller', 'Yes', iconColor: Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}