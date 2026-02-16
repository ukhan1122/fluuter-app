// lib/screens/home_screen.dart - OPTIMIZED
import 'package:flutter/material.dart';
import '../widgets/hero_slider.dart';
import '../widgets/category_tags.dart';
import '../widgets/product_grid.dart';
import '../widgets/navbar.dart';
import '../services/api_service.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;
  bool _isInitialLoad = true;
  bool _productsLoaded = false; // Track if products are loaded
  
  @override
  void initState() {
    super.initState();
    _preloadProducts();
  }
  
  void _preloadProducts() async {
    print('🚀 Preloading products at app startup...');
    
    try {
      // Load ALL products at once using ProductCache
      await ProductCache.getProducts(limit: 50);
      
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _productsLoaded = true;
        });
      }
      print('✅ Products preloaded successfully!');
    } catch (e) {
      print('❌ Error preloading products: $e');
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    }
  }

  void onCategorySelected(String? category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ['Men', 'Women', 'Kids', 'Wedding'];

    List<String> categoriesToShow = selectedCategory != null
        ? [selectedCategory!] // Show only selected category
        : allCategories; // Show all categories initially

    return Scaffold(
      appBar: const CustomNavbar(),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HeroSlider(),
            CategoryTags(onCategorySelected: onCategorySelected),
            
            // Show loading indicator only for first load
            if (_isInitialLoad)
              _buildInitialLoading()
            else if (!_productsLoaded)
              _buildErrorLoading()
            else
              // Show products grid - now using cached data!
              ...categoriesToShow.map((cat) => ProductGrid(
                section: cat,
                isHorizontal: selectedCategory == null, // True for all, false for single
              )).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInitialLoading() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 10),
          const Text('Loading products...'),
        ],
      ),
    );
  }
  
  Widget _buildErrorLoading() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          const Text('Failed to load products'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isInitialLoad = true;
              });
              _preloadProducts();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}