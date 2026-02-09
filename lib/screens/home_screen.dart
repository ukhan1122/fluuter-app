// lib/screens/home_screen.dart - UPDATED
import 'package:flutter/material.dart';
import '../widgets/hero_slider.dart';
import '../widgets/category_tags.dart';
import '../widgets/product_grid.dart';
import '../widgets/navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;
  bool _isInitialLoad = true;
  
  @override
  void initState() {
    super.initState();
    _preloadProducts();
  }
  
  void _preloadProducts() async {
    print('🚀 Preloading products at app startup...');
    _isInitialLoad = false;
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
              _buildInitialLoading(),
            
            // KEY CHANGE HERE:
            // When showing ALL categories: use horizontal (isHorizontal: true)
            // When showing SINGLE category: use grid (isHorizontal: false)
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
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text('Loading products...'),
        ],
      ),
    );
  }
}