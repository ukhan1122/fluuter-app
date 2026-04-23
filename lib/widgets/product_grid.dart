import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_detail.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
   List<Product> _allProducts = [];
  List<Product> _displayProducts = [];
  bool _isLoading = true;
  int _visibleCount = 6;  // Changed: start with 6 products
  bool _isLoadingMore = false;  // NEW: track loading state
  final ScrollController _productScrollController = ScrollController();
  final double _scrollAmount = 250.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  _productScrollController.addListener(_onHorizontalScrollEnd);
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    print('🚀 Loading ${widget.section} products from CACHE...');
    
    try {
      String apiGroup = _mapSectionToGroup(widget.section);
      
      final allProducts = await ProductCache.getProducts();
      
      final filtered = apiGroup.isNotEmpty 
          ? allProducts.where((product) {
              final productGroup = product.categoryGroup?.toLowerCase() ?? '';
              final targetGroup = apiGroup.toLowerCase();
              
              if (targetGroup == 'mens' && productGroup == 'men') return true;
              if (targetGroup == 'womens' && productGroup == 'women') return true;
              if (targetGroup == 'kids' && productGroup == 'kids') return true;
              
              return productGroup == targetGroup;
            }).toList()
          : allProducts;
      
      print('✅ Found ${filtered.length} ${widget.section} products');
      
      setState(() {
        _allProducts = filtered;
        _updateDisplayProducts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
   void _updateDisplayProducts() {
    setState(() {
      _displayProducts = _allProducts.take(_visibleCount).toList();
    });
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
        return 'womens';
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
  _productScrollController.removeListener(_onHorizontalScrollEnd);
  _productScrollController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    
  print('Building ${widget.section} - Display products: ${_displayProducts.length}, Visible count: $_visibleCount, Total: ${_allProducts.length}');
    if (_isLoading) {
      return _buildLoadingSection();
    }

    if (_errorMessage != null) {
      return _buildErrorSection(_errorMessage!);
    }

    if (_allProducts.isEmpty) {
      return _buildEmptySection();
    }
    final showArrows = widget.isHorizontal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
          ),
          
          const SizedBox(height: 10),
          widget.isHorizontal
              ? _buildHorizontalLayout(_displayProducts)
              : _buildVerticalGrid(_displayProducts),
          
             // Only show Load More button for vertical layout (when category is selected)
if (!widget.isHorizontal && _allProducts.length > _visibleCount)
  _buildLoadMoreButton(),
        ],
      ),
    );
  }


// Add this method to load more when scrolling horizontally
void _onHorizontalScrollEnd() {
  if (!widget.isHorizontal) return; // Only for horizontal
  if (_isLoadingMore) return;
  if (_visibleCount >= _allProducts.length) return;
  
  // Check if we're near the end of the scroll
  final position = _productScrollController.position;
  if (position.pixels >= position.maxScrollExtent - 100) {
    _loadMoreHorizontal();
  }
}

// Add this method to load more products for horizontal scroll
Future<void> _loadMoreHorizontal() async {
  if (_isLoadingMore) return;
  if (_visibleCount >= _allProducts.length) return;
  
  setState(() {
    _isLoadingMore = true;
  });
  
  await Future.delayed(const Duration(milliseconds: 300));
  
  setState(() {
    _visibleCount += 6;
    if (_visibleCount > _allProducts.length) {
      _visibleCount = _allProducts.length;
    }
    _displayProducts = _allProducts.take(_visibleCount).toList();
    _isLoadingMore = false;
  });
}
  Widget _buildLoadingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.customTitle ?? widget.section,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Loading products...'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.customTitle ?? widget.section,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  'Failed to load ${widget.section}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadProducts,
                  child: const Text('Try Again'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.customTitle ?? widget.section,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  '${widget.section} products are Coming',
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
      child: Stack(
        children: [
          ListView.builder(
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
          if (_isLoadingMore && widget.isHorizontal)
            Positioned(
              right: 16,
              top: 100,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
              ),
            ),
        ],
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
              width: widget.isHorizontal ? 150 : double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: _buildProductImage(product),
            ),
            const SizedBox(height: 8),
            
            SizedBox(
              width: widget.isHorizontal ? 150 : null,
              child: Text(
                product.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isHorizontal)
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
    
    String imageUrl = product.photoUrls.first;
    
    if (imageUrl.isNotEmpty) {
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        imageUrl = 'https://$imageUrl';
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
          errorWidget: (context, url, error) => _buildPlaceholderImage(),
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


 Widget _buildLoadMoreButton() {
  return Column(
    children: [
      const SizedBox(height: 10),
      Center(
        child: _isLoadingMore
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
              )
            : TextButton(
                onPressed: () async {
                  print('Load More clicked for ${widget.section}');
                  
                  setState(() {
                    _isLoadingMore = true;
                  });
                  
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  setState(() {
                    int newVisibleCount = _visibleCount + 6;
                    if (newVisibleCount > _allProducts.length) {
                      newVisibleCount = _allProducts.length;
                    }
                    _visibleCount = newVisibleCount;
                    _displayProducts = _allProducts.take(_visibleCount).toList();
                    _isLoadingMore = false;
                  });
                  
                  // Auto-scroll to show new products
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (_productScrollController.hasClients) {
                    _productScrollController.animateTo(
                      _productScrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: const Text('Load More →'),
              ),
        ),
      
    ],
  );
} 

} 