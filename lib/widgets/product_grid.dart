// lib/widgets/product_grid.dart - UPDATED
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_detail.dart';

class ProductGrid extends StatefulWidget {
  final String section;
  final bool isHorizontal;
  final String? customTitle;

  const ProductGrid({
    super.key,
    required this.section,
    this.isHorizontal = true,
    this.customTitle,
  });

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  late Future<List<Product>> _productsFuture;
  bool _showAllProducts = false;
  final ScrollController _productScrollController = ScrollController();
  final double _scrollAmount = 250.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

 void _loadProducts() {
  print('🚀 Loading ${widget.section} products from CACHE...');
  
  String apiGroup = _mapSectionToGroup(widget.section);
  
  // USE CACHE INSTEAD OF DIRECT API CALLS
  _productsFuture = ProductCache.getProducts().then((allProducts) {
    if (apiGroup.isNotEmpty) {
      // FILTER products by category group
      final filtered = allProducts.where((product) {
        final productGroup = product.categoryGroup?.toLowerCase() ?? '';
        final targetGroup = apiGroup.toLowerCase();
        
        // Handle plural/singular variations
        if (targetGroup == 'mens' && productGroup == 'men') return true;
        if (targetGroup == 'womens' && productGroup == 'women') return true;
        
        return productGroup == targetGroup;
      }).toList();
      
      print('✅ Found ${filtered.length} ${widget.section} products in cache');
      return filtered;
    } else {
      return allProducts;
    }
  });
  
  if (mounted) {
    setState(() {});
  }
}

String _mapSectionToGroup(String section) {
  switch (section.toLowerCase()) {
    case 'men':
      return 'mens';
    case 'women':
      return 'womens';
    case 'kids':
      return 'kids';  
    case 'wedding':
      return 'womens'; // ← CHANGE THIS to 'womens' instead of 'wedding'
    default:
      return '';
  }
}

  void _scrollProducts(int direction) {
    try {
      final currentOffset = _productScrollController.offset;
      final maxOffset = _productScrollController.position.maxScrollExtent;
      double newOffset = currentOffset + (direction * _scrollAmount);

      if (direction < 0 && newOffset < 0) newOffset = 0;
      if (direction > 0 && newOffset > maxOffset) newOffset = maxOffset;

      _productScrollController.animateTo(
        newOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      print('Scroll error: $e');
    }
  }

  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _productScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSection();
        }

        if (snapshot.hasError) {
          return _buildErrorSection(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptySection();
        }

        final allProducts = snapshot.data!;
        final productsToShow = _showAllProducts
            ? allProducts
            : allProducts.take(6).toList();
        final showArrows = widget.isHorizontal && !_showAllProducts;

        return _buildProductGrid(
          productsToShow,
          allProducts,
          showArrows,
        );
      },
    );
  }

  Widget _buildLoadingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(false),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Loading ${widget.section}...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(false),
          const SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 10),
                Text(
                  'Failed to load ${widget.section}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  error.length > 100 ? '${error.substring(0, 100)}...' : error,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadProducts,
                  child: Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(false),
          const SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 40),
                SizedBox(height: 10),
                Text(
                  'No ${widget.section} products',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    List<Product> productsToShow,
    List<Product> allProducts,
    bool showArrows,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(showArrows),
          const SizedBox(height: 10),
          widget.isHorizontal && !_showAllProducts
              ? _buildHorizontalLayout(productsToShow)
              : _buildVerticalGrid(productsToShow),
          if (allProducts.length > 6) _buildViewAllButton(allProducts.length),
        ],
      ),
    );
  }

  Widget _buildHeader(bool showArrows) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.customTitle ?? widget.section,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (showArrows)
              Row(
                children: [
                  _buildArrowButton(-1, Icons.arrow_back_ios_rounded),
                  _buildArrowButton(1, Icons.arrow_forward_ios_rounded),
                ],
              ),
          ],
        ),
      );

  Widget _buildArrowButton(int direction, IconData icon) => IconButton(
        onPressed: () => _scrollProducts(direction),
        icon: Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.red),
        ),
      );

  Widget _buildHorizontalLayout(List<Product> products) => SizedBox(
        height: 250,
        child: ListView.builder(
          controller: _productScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          itemBuilder: (context, index) => Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 16.0 : 8.0,
              right: index == products.length - 1 ? 16.0 : 8.0,
            ),
            child: _buildProductCard(products[index]),
          ),
        ),
      );

  Widget _buildVerticalGrid(List<Product> products) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildProductCard(products[index]),
        ),
      );

  Widget _buildProductCard(Product product) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen.fromProduct(
              product: product,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: widget.isHorizontal && !_showAllProducts
                  ? 150
                  : double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: _buildProductImage(product),
            ),
            const SizedBox(height: 8),
            
            SizedBox(
              width: widget.isHorizontal && !_showAllProducts ? 150 : null,
              child: Text(
                product.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            if (widget.isHorizontal && !_showAllProducts)
              Text(
                product.brandName ?? 'No Brand',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            else
              Text(
                product.brandName ?? 'No Brand',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            
            Text(
              'Rs.${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

Widget _buildProductImage(Product product) {
  if (product.photoUrls.isEmpty) {
    return _buildPlaceholderImage();
  }
  
  // Get the first photo URL directly (it's already a String)
  String imageUrl = product.photoUrls.first;
  
  if (imageUrl.isNotEmpty) {
    // Ensure URL has protocol
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      imageUrl = 'https://$imageUrl';
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
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
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      ),
    );
  } else {
    return _buildPlaceholderImage();
  }
}

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Center(
        child: Icon(Icons.photo, size: 40, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildViewAllButton(int totalProducts) {
    if (totalProducts > 6 && !_showAllProducts) {
      return Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAllProducts = true),
              child: const Text('View all →'),
            ),
          ),
        ],
      );
    } else if (_showAllProducts) {
      return Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAllProducts = false),
              child: const Text('Show less'),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}