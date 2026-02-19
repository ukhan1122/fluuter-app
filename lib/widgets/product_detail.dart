import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/cart_screen.dart';
import '../models/cart_item.dart';
import '../models/product.dart' as model;  // ✅ WITH ALIAS
import 'product_grid.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../screens/seller_profile_screen.dart'; // This also has a Product class
import 'package:url_launcher/url_launcher.dart';  // ✅ ADD THIS IMPORT
import '../services/api_service.dart';
import '../providers/favorites_provider.dart'; 

class ProductDetailScreen extends StatefulWidget {
  final String title, brand, price, category;
    final model.Product product;  // ✅ CHANGED TO model.Product
  
  const ProductDetailScreen({
    super.key,
    required this.title,
    required this.brand,
    required this.price,
    required this.category,
    required this.product,
  });

  factory ProductDetailScreen.fromProduct({
     required model.Product product, 
    Key? key,
  }) {
    return ProductDetailScreen(
      key: key,
      title: product.title,
      brand: product.brandName ?? 'No Brand',
      price: 'Rs.${product.price.toStringAsFixed(0)}',
      category: product.categoryGroup ?? product.categoryName ?? 'General',
      product: product,
    );
  }

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _showFullDesc = false;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  
  String get _desc => widget.product.description.isNotEmpty 
      ? widget.product.description 
      : 'Premium quality product with excellent craftsmanship.';
  
  List<Map<String, String>> get _sizeDetails {
    final List<Map<String, String>> sizes = [];
    final size = widget.product.size;
    
    if (size != null) {
      if (size['chest'] != null) sizes.add({'label': 'Chest', 'value': '${size['chest']}"'});
      if (size['waist'] != null) sizes.add({'label': 'Waist', 'value': '${size['waist']}"'});
      if (size['length'] != null) sizes.add({'label': 'Length', 'value': '${size['length']}"'});
      if (size['standard_size'] != null) sizes.add({'label': 'Size', 'value': size['standard_size']});
    }
    return sizes;
  }
  
  String get _stockStatus {
    if (widget.product.sold) return 'Sold Out';
    if (widget.product.quantityLeft <= 0) return 'Out of Stock';
    if (widget.product.quantityLeft <= 5) return 'Only ${widget.product.quantityLeft} left';
    return 'In Stock';
  }
  
  Color get _stockColor {
    if (widget.product.sold || widget.product.quantityLeft <= 0) return Colors.red;
    if (widget.product.quantityLeft <= 5) return Colors.orange;
    return Colors.green;
  }
  
  String get _conditionText => widget.product.conditionTitle ?? 'Good';
  
  Color get _conditionColor {
    final condition = _conditionText.toLowerCase();
    if (condition.contains('new') || condition.contains('excellent')) return Colors.green;
    if (condition.contains('like new')) return Colors.teal;
    if (condition.contains('good')) return Colors.blue;
    if (condition.contains('fair')) return Colors.orange;
    if (condition.contains('used')) return Colors.purple;
    return Colors.grey;
  }

  List<String> get _imageUrls {
    return widget.product.photoUrls.map((url) {
      if (url.isNotEmpty && !url.startsWith('http')) {
        return 'https://$url';
      }
      return url;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.title, 
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageGallery(),
                  
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductHeader(),
                        
                        const SizedBox(height: 16),
                        
                        _buildStatusTags(),
                        
                        if (widget.product.location != null || widget.product.city != null) ...[
                          const SizedBox(height: 16),
                          _buildLocation(),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        _buildDescription(),
                        
                        const SizedBox(height: 24),
                        
                        _buildCondition(),
                        
                        if (_sizeDetails.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSizeSection(),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        if (widget.product.user.isNotEmpty) _buildSellerSection(),
                        
                        const SizedBox(height: 32),
                        
                        ProductGrid(
                          section: widget.category, 
                          customTitle: 'You May Also Like',
                          isHorizontal: false,
                        ),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildImageGallery() {
    final images = _imageUrls;
    final hasMultipleImages = images.length > 1;
    
    return Column(
      children: [
        // Main Image with GestureDetector for full screen
        GestureDetector(
          onTap: hasMultipleImages ? () => _showFullScreenGallery(context) : null,
          child: Container(
            height: 380,
            width: double.infinity,
            color: Colors.grey[100],
            child: Stack(
              children: [
                // Main Image - Now updates when _currentImageIndex changes
                if (images.isNotEmpty)
                  Image.network(
                    images[_currentImageIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  )
                else
                  _buildPlaceholderImage(),
                
                // Image Counter
                if (hasMultipleImages)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                
               // In the _ProductDetailScreenState class, replace the _isFavorite boolean with:

// Remove this line:
// bool _isFavorite = false;

// Add this in the build method where the heart icon is:
Positioned(
  top: 16,
  left: 16,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.isFavorite(
          widget.product.id.toString()
        );
        
        return IconButton(
          onPressed: () {
            favoritesProvider.toggleFavorite(widget.product);
            
            // Show feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isFavorite 
                      ? 'Removed from favorites' 
                      : 'Added to favorites'
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: isFavorite ? Colors.grey : Colors.red,
              ),
            );
          }, 
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey[600],
            size: 24,
          ), 
          padding: const EdgeInsets.all(8),
        );
      },
    ),
  ),
),
              ],
            ),
          ),
        ),
        
        // Thumbnails - FIXED: Now updates main image when tapped
        if (hasMultipleImages) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index; // This updates the main image
                    });
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? Colors.red
                            : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
  
  void _showFullScreenGallery(BuildContext context) {
    final images = _imageUrls;
    if (images.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: _currentImageIndex),
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text('Failed to load image', style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No Image Available',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title, 
                style: const TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'by ', 
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    widget.brand, 
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.price, 
                style: const TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'incl. taxes',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _stockColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _stockColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.product.sold ? Icons.block : Icons.inventory_2_outlined,
                color: _stockColor,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _stockStatus,
                style: TextStyle(
                  fontSize: 12,
                  color: _stockColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _conditionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _conditionColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified, 
                color: _conditionColor, 
                size: 14
              ),
              const SizedBox(width: 6),
              Text(
                _conditionText,
                style: TextStyle(
                  fontSize: 12,
                  color: _conditionColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLocation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.product.city ?? ''}${widget.product.city != null && widget.product.location != null ? ', ' : ''}${widget.product.location ?? ''}',
              style: TextStyle(
                fontSize: 13, 
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Verified',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description', 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _desc, 
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.grey[800], 
                  height: 1.5,
                ),
                maxLines: _showFullDesc ? null : 3,
                overflow: _showFullDesc ? null : TextOverflow.ellipsis,
              ),
              if (_desc.length > 100)
                GestureDetector(
                  onTap: () => setState(() => _showFullDesc = !_showFullDesc),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _showFullDesc ? 'Show less' : 'Read more',
                      style: const TextStyle(
                        fontSize: 14, 
                        color: Colors.red, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCondition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Condition', 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _conditionColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _conditionColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_outlined,
                  color: _conditionColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _conditionText, 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        color: _conditionColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Product condition as described by seller',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Measurements', 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sizeDetails.map((size) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                '${size['label']}: ${size['value']}',
                style: const TextStyle(fontSize: 12),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
  

// Add this method to fetch complete seller data
Future<Map<String, dynamic>> _fetchSellerData(String sellerId) async {
  try {
    print('📡 Fetching seller data for product detail: $sellerId');
    final profileResult = await ApiService.getSellerProfile(sellerId);
    
    if (profileResult['success'] == true) {
      final profileData = profileResult['data'];
      
      // Also fetch ratings to get the count
      final ratingsResult = await ApiService.getSellerRatings(sellerId);
      
      double rating = 0.0;
      int reviewCount = 0;
      
      if (ratingsResult['success'] == true) {
        // Extract rating from nested data
        if (ratingsResult['average'] != null && ratingsResult['average'] > 0) {
          rating = ratingsResult['average'].toDouble();
        } else if (ratingsResult['data'] != null) {
          final data = ratingsResult['data'];
          if (data is Map && data.containsKey('average')) {
            rating = (data['average'] is num) ? data['average'].toDouble() : 0.0;
          }
        }
        
        // Get review count
        if (ratingsResult['count'] != null && ratingsResult['count'] > 0) {
          reviewCount = ratingsResult['count'];
        } else if (ratingsResult['data'] != null) {
          final data = ratingsResult['data'];
          if (data is Map && data.containsKey('ratings') && data['ratings'] is List) {
            reviewCount = (data['ratings'] as List).length;
          }
        }
      }
      
      // Create enhanced user data with ratings
      Map<String, dynamic> enhancedUser = Map<String, dynamic>.from(profileData);
      enhancedUser['rating'] = rating;
      enhancedUser['average_rating'] = rating;
      enhancedUser['reviews_count'] = reviewCount;
      
      print('✅ Enhanced seller data: rating=$rating, reviews=$reviewCount');
      return enhancedUser;
    }
  } catch (e) {
    print('❌ Error fetching seller data: $e');
  }
  
  return {};
}

Widget _buildSellerSection() {
  final userId = widget.product.user['id']?.toString() ?? '0';
  
  return FutureBuilder<Map<String, dynamic>>(
    future: _fetchSellerData(userId),
    builder: (context, snapshot) {
      // Use enhanced data if available, otherwise fall back to product user data
      final Map<String, dynamic> user = snapshot.hasData && snapshot.data!.isNotEmpty
          ? snapshot.data!
          : widget.product.user;
      
      // Rest of your existing _buildSellerSection code using 'user' instead of 'widget.product.user'
      final firstName = user['first_name'] ?? '';
      final lastName = user['last_name'] ?? '';
      final username = user['username'] ?? '';
      final profilePic = user['profile_picture'];
      final isVerified = user['is_verified'] == 1;
      
      // Get contact information
      final String email = user['email'] ?? '';
      final String phone = user['phone'] ?? user['phone_number'] ?? '';
      final String whatsapp = user['whatsapp'] ?? user['whatsapp_number'] ?? phone;
      
      // Extract rating and reviews - now from enhanced data
      double rating = 0.0;
      int totalReviews = 0;
      
      if (user['average_rating'] != null) {
        rating = (user['average_rating'] is num) 
            ? (user['average_rating'] as num).toDouble() 
            : double.tryParse(user['average_rating'].toString()) ?? 0.0;
      } else if (user['rating'] != null) {
        rating = (user['rating'] is num) 
            ? (user['rating'] as num).toDouble() 
            : double.tryParse(user['rating'].toString()) ?? 0.0;
      }
      
      if (user['reviews_count'] != null) {
        totalReviews = (user['reviews_count'] is int) 
            ? user['reviews_count'] 
            : int.tryParse(user['reviews_count'].toString()) ?? 0;
      }
      
      final int totalSales = user['products_count'] ?? user['total_products'] ?? 0;
      
      // Parse join date
      String memberSince = 'Recently';
      if (user['created_at'] != null) {
        try {
          final date = DateTime.parse(user['created_at']);
          final now = DateTime.now();
          final difference = now.difference(date);
          
          if (difference.inDays < 30) {
            memberSince = '${difference.inDays} days ago';
          } else if (difference.inDays < 365) {
            memberSince = '${(difference.inDays / 30).floor()} months ago';
          } else {
            memberSince = '${(difference.inDays / 365).floor()} years ago';
          }
        } catch (e) {
          memberSince = user['created_at']?.toString() ?? 'Recently';
        }
      }
      
      // Return your existing UI using these variables
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seller Information', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Seller Avatar with Verification Badge
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: profilePic != null ? NetworkImage(profilePic.toString()) : null,
                            backgroundColor: Colors.grey[200],
                            child: profilePic == null 
                                ? const Icon(Icons.person, size: 28, color: Colors.grey) 
                                : null,
                          ),
                          if (isVerified)
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
                      
                      // Seller Name and Rating
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$firstName $lastName'.trim().isNotEmpty 
                                  ? '$firstName $lastName'.trim() 
                                  : username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  if (index < rating.floor()) {
                                    return const Icon(Icons.star, color: Colors.amber, size: 14);
                                  } else if (index < rating) {
                                    return const Icon(Icons.star_half, color: Colors.amber, size: 14);
                                  } else {
                                    return const Icon(Icons.star_border, color: Colors.amber, size: 14);
                                  }
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  '($totalReviews)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  '$totalSales sales',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  memberSince,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Visit Shop Button
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerProfileScreen(
                                  sellerId: userId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(80, 36),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Visit Shop',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Contact Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactButton(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          color: Colors.blue,
                          onTap: () {
                            if (email.isNotEmpty) {
                              _launchEmail(email);
                            } else {
                              _showNoContactInfo('Email');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildContactButton(
                          icon: FontAwesomeIcons.whatsapp,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () {
                            if (whatsapp.isNotEmpty) {
                              _launchWhatsApp(whatsapp);
                            } else {
                              _showNoContactInfo('WhatsApp');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildContactButton(
                          icon: Icons.phone_outlined,
                          label: 'Call',
                          color: Colors.green,
                          onTap: () {
                            if (phone.isNotEmpty) {
                              _launchPhoneDialer(phone);
                            } else {
                              _showNoContactInfo('Phone');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
  
// Add these helper methods inside _ProductDetailScreenState class

/// Launch email app
void _launchEmail(String email) async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: email,
    query: 'subject=Inquiry about your product&body=Hello, I am interested in your product...',
  );
  
  try {
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showError('Could not launch email app');
    }
  } catch (e) {
    _showError('Error launching email: $e');
  }
}

/// Launch WhatsApp
void _launchWhatsApp(String phoneNumber) async {
  // Remove any non-digit characters
  String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
  
  // For WhatsApp, we need the country code
  // If number doesn't start with country code, you might need to add it
  // For Pakistan, it would be '92' without the '+'
  
  final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
  
  try {
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // Try alternative WhatsApp intent for Android
      final Uri whatsappIntent = Uri.parse('whatsapp://send?phone=$cleanNumber');
      if (await canLaunchUrl(whatsappIntent)) {
        await launchUrl(whatsappIntent);
      } else {
        _showError('WhatsApp is not installed');
      }
    }
  } catch (e) {
    _showError('Error launching WhatsApp: $e');
  }
}

/// Launch phone dialer
void _launchPhoneDialer(String phoneNumber) async {
  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  
  try {
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showError('Could not launch phone dialer');
    }
  } catch (e) {
    _showError('Error launching dialer: $e');
  }
}

/// Show error message
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Show no contact info message
void _showNoContactInfo(String contactType) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$contactType information not available for this seller'),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 2),
    ),
  );
}


  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildActionButtons() {
  final bool isOutOfStock = widget.product.sold || widget.product.quantityLeft <= 0;
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey[200]!)),
    ),
    child: Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Column(
          children: [
            ElevatedButton(
              onPressed: isOutOfStock 
                  ? null  // Disable button if out of stock
                  : () {
                      final images = _imageUrls;
                      
                      cartProvider.addToCart(CartItem(
                        productId: widget.product.id,
                        sellerId: widget.product.userId,
                        title: widget.title,
                        image: images.isNotEmpty ? images.first : '',
                        price: widget.price,
                        quantity: 1,
                      ));
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Added to cart',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const CartScreen()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'VIEW',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          backgroundColor: Colors.white,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutOfStock ? Colors.grey : Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                isOutOfStock ? 'Out of Stock' : 'Add to Bag',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            
            if (cartProvider.totalQuantity > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_cart, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'View Cart',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${cartProvider.totalQuantity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

}