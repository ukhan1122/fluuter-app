// lib/providers/favorites_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Product> _favoriteItems = [];
  
  List<Product> get favoriteItems => _favoriteItems;
  
  int get totalFavorites => _favoriteItems.length;

  FavoritesProvider() {
    _loadFavorites();
  }

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString('favorites');
      
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favoriteItems = decoded.map((item) => Product.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> encoded = 
          _favoriteItems.map((item) => item.toJson()).toList();
      await prefs.setString('favorites', json.encode(encoded));
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Check if product is favorite
  bool isFavorite(String productId) {
    return _favoriteItems.any((item) => item.id.toString() == productId);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(Product product) async {
    final existingIndex = _favoriteItems.indexWhere(
      (item) => item.id.toString() == product.id.toString()
    );
    
    if (existingIndex >= 0) {
      // Remove from favorites
      _favoriteItems.removeAt(existingIndex);
    } else {
      // Add to favorites
      _favoriteItems.add(product);
    }
    
    await _saveFavorites();
    notifyListeners();
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    _favoriteItems.clear();
    await _saveFavorites();
    notifyListeners();
  }

  // Remove specific favorite
  Future<void> removeFavorite(String productId) async {
    _favoriteItems.removeWhere((item) => item.id.toString() == productId);
    await _saveFavorites();
    notifyListeners();
  }
}