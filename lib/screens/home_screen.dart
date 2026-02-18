// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../widgets/hero_slider.dart';
import '../widgets/category_tags.dart';
import '../widgets/product_grid.dart';
import '../widgets/navbar.dart';
import '../widgets/global_search_bar.dart'; // Use this

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;

  void onCategorySelected(String? category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ['Men', 'Women', 'Kids', 'Wedding'];

    List<String> categoriesToShow = selectedCategory != null
        ? [selectedCategory!]
        : allCategories;

    return Scaffold(
      appBar: const GlobalSearchBar(), // Use your global search bar
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HeroSlider(),
            CategoryTags(onCategorySelected: onCategorySelected),
            const SizedBox(height: 10),
            ...categoriesToShow.map((cat) => ProductGrid(
              section: cat,
              isHorizontal: selectedCategory == null,
            )).toList(),
          ],
        ),
      ),
    );
  }
}