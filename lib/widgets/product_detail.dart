import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/cart_screen.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'product_grid.dart';

class ProductDetailScreen extends StatefulWidget {
  // Original constructor
  final String title, brand, price, image, category;
  final Product product; // Add this to receive full product
  
  const ProductDetailScreen({
    super.key,
    required this.title,
    required this.brand,
    required this.price,
    required this.image,
    required this.category,
    required this.product, // Add this parameter
  });

  // Factory constructor that accepts Product object
  factory ProductDetailScreen.fromProduct({
    required Product product,
    Key? key,
  }) {
    return ProductDetailScreen(
      key: key,
      title: product.title,
      brand: product.brandName ?? 'No Brand',
      price: 'Rs.${product.price.toStringAsFixed(0)}',
      image: _getFirstImageUrl(product),
      category: product.categoryGroup ?? product.categoryName ?? 'General',
      product: product, // Pass the full product object
    );
  }

  // Helper to get first image URL
  static String _getFirstImageUrl(Product product) {
    if (product.photos.isEmpty) return 'assets/CLOTHES-HANGERS.png';
    
    final firstPhoto = product.photos.first;
    String? imageUrl;
    
    if (firstPhoto is Map<String, dynamic>) {
      imageUrl = firstPhoto['image_path']?.toString() ??
                 firstPhoto['url']?.toString() ??
                 firstPhoto['image']?.toString();
    } else if (firstPhoto is Map) {
      imageUrl = firstPhoto['image_path']?.toString();
    } else if (firstPhoto is String) {
      imageUrl = firstPhoto;
    }
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (!imageUrl.startsWith('http')) {
        imageUrl = 'https://$imageUrl';
      }
      return imageUrl;
    }
    return 'assets/CLOTHES-HANGERS.png';
  }

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<CartItem> cart = [];
  bool _showFullDesc = false;
  
  // Use the product description OR fallback to default
  String get _desc => widget.product.description.isNotEmpty 
      ? widget.product.description 
      : 'This premium quality product features excellent craftsmanship with attention to detail. Made from high-quality materials for durability and comfort. Perfect for both casual and formal occasions.';
  
  // Helper to get size details
  List<Map<String, String>> get _sizeDetails {
    final List<Map<String, String>> sizes = [];
    final size = widget.product.size;
    
    if (size != null) {
      if (size['chest'] != null) sizes.add({'label': 'Chest', 'value': '${size['chest']} inch'});
      if (size['waist'] != null) sizes.add({'label': 'Waist', 'value': '${size['waist']} inch'});
      if (size['hips'] != null) sizes.add({'label': 'Hips', 'value': '${size['hips']} inch'});
      if (size['inseam'] != null) sizes.add({'label': 'Inseam', 'value': '${size['inseam']} inch'});
      if (size['sleeve'] != null) sizes.add({'label': 'Sleeve', 'value': '${size['sleeve']} inch'});
      if (size['shoulder'] != null) sizes.add({'label': 'Shoulder', 'value': '${size['shoulder']} inch'});
      if (size['standard_size'] != null) sizes.add({'label': 'Size', 'value': '${size['standard_size']}'});
    }
    
    return sizes;
  }
  
  // Helper to get stock status
  String get _stockStatus {
    if (widget.product.sold) return 'Sold Out';
    if (widget.product.quantityLeft <= 0) return 'Out of Stock';
    if (widget.product.quantityLeft <= 5) return 'Only ${widget.product.quantityLeft} left in stock';
    return 'In Stock';
  }
  
  Color get _stockColor {
    if (widget.product.sold || widget.product.quantityLeft <= 0) return Colors.red;
    if (widget.product.quantityLeft <= 5) return Colors.orange;
    return Colors.green;
  }
  
  // Helper to get condition
  String get _conditionText => widget.product.conditionTitle ?? 'Good';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(widget.title, style: const TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FULL WIDTH IMAGE - No horizontal padding for image
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  _buildProductImage(),
                  Positioned(
                    top: 16, right: 16,
                    child: Column(
                      children: [
                        _iconBtn(Icons.favorite_border, Colors.red),
                        const SizedBox(height: 8),
                        _iconBtn(Icons.local_offer_outlined, Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Brand: ${widget.brand}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(widget.price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                  
                  // Stock status from product data
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.inventory_2_outlined, color: _stockColor, size: 18),
                    const SizedBox(width: 6),
                    Text(_stockStatus, style: TextStyle(fontSize: 15, color: _stockColor, fontWeight: FontWeight.w600)),
                  ]),
                  
                  // Location if available
                  if (widget.product.location != null || widget.product.city != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.location_on_outlined, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.product.city ?? ''}${widget.product.city != null && widget.product.location != null ? ', ' : ''}${widget.product.location ?? ''}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ]),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildDescriptionSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Condition from product data
                  _buildConditionSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Size details from product data
                  if (_sizeDetails.isNotEmpty) _buildSizeSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Buttons
                  _buildActionButtons(),
                  
                  const SizedBox(height: 24),
                  
                  // Seller information from product.user
                  if (widget.product.user.isNotEmpty) _buildSellerSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Related Products
                  ProductGrid(
                    section: widget.category, 
                    customTitle: 'You May Also Like',
                    isHorizontal: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build FULL WIDTH product image
  Widget _buildProductImage() {
    if (widget.image.startsWith('http')) {
      return Image.network(
        widget.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 400, // Fixed height for consistency
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 400,
            width: double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        widget.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 400,
      );
    }
  }
  
  Widget _buildPlaceholderImage() {
    return Container(
      height: 400,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.photo, size: 100, color: Colors.grey[400]),
      ),
    );
  }
  
  // Helper method for description - RESTORED with original logic
  Widget _buildDescriptionSection() {
    return _showFullDesc 
      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_desc, style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showFullDesc = false),
            child: Text('Show less', style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
          ),
        ])
      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_desc, 
            style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showFullDesc = true),
            child: Text('Read more', style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
          ),
        ]);
  }
  
  // Helper method for condition
  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Condition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(children: [
            Icon(Icons.verified, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Text(_conditionText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
          ]),
        ),
      ],
    );
  }
  
  // Helper method for size section
  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Size Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _sizeDetails.map((size) => _sizeChip(size['label']!, size['value']!)).toList(),
        ),
      ],
    );
  }
  
  // Helper method for seller section
  Widget _buildSellerSection() {
    final user = widget.product.user;
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final username = user['username'] ?? '';
    final profilePic = user['profile_picture'];
    final isVerified = user['is_verified'] == 1;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: profilePic != null ? NetworkImage(profilePic.toString()) : null,
            child: profilePic == null ? const Icon(Icons.person, size: 30) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                Icon(Icons.verified, color: Colors.blue, size: 16),
              ],
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.star, color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 4),
              const Text('4.5'),
              const SizedBox(width: 12),
              const Text('Active Seller'),
            ]),
          ])),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Visit Profile'),
          ),
        ]),
      ),
    );
  }
  
  // Helper method for action buttons
  Widget _buildActionButtons() {
    return Row(children: [
      _actionBtn(FontAwesomeIcons.shoppingBag, 'Add to Bag', Colors.red, () {
        // Add the product to cart
        final existingIndex = cart.indexWhere((item) => item.title == widget.title);
        setState(() {
          if (existingIndex >= 0) {
            cart[existingIndex].quantity++;
          } else {
            cart.add(CartItem(
              title: widget.title,
              image: widget.image,
              price: widget.price,
              quantity: 1,
            ));
          }
        });

        // Navigate to CartScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CartScreen(cartItems: cart),
          ),
        );
      }),
      const SizedBox(width: 8),
      _actionBtn(FontAwesomeIcons.tag, 'Make Offer', Colors.blue, () {}),
      const SizedBox(width: 8),
      _actionBtn(FontAwesomeIcons.whatsapp, 'WhatsApp', Colors.green, () {}),
    ]);
  }

  // Helper Methods
  Widget _iconBtn(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: IconButton(
        onPressed: () {}, 
        icon: Icon(icon, color: color, size: 24), 
        padding: const EdgeInsets.all(8)
      ),
    );
  }

  Widget _sizeChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, 
        borderRadius: BorderRadius.circular(8)
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}