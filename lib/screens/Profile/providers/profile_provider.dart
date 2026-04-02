// lib/screens/profile/providers/profile_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_splash_app/models/product.dart';  // ← CHANGE THIS LINE
import '../../../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  List<Product> sellingItems = [];
  List<Product> soldItems = [];
  bool isLoading = true;
  
  String userName = '';
  String userEmail = '';
  String? userProfilePicture;
  String shopDescription = '';
  String? authToken;
  String memberSince = '';
  double totalEarnings = 0.0;
  int totalFollowers = 0;
  int totalFollowing = 0;

  // Helper method to fix image URLs for emulator
  String _fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    String filename = url.split('/').last;
    return 'http://10.0.2.2/api/get-image/$filename';
  }

  Future<void> loadUserData() async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
      
      if (authToken != null && authToken!.isNotEmpty) {
        await _loadFromCache();
        await _refreshUserProfile();
        await fetchUserProducts();
        await fetchUserStats();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString('user_data');
    
    if (userDataJson != null) {
      final userData = json.decode(userDataJson);
      _updateUserDataFromJson(userData);
    }
  }

  void _updateUserDataFromJson(Map<String, dynamic> userData) {
    userName = userData['first_name']?.toString() ?? 'User';
    userEmail = userData['email']?.toString() ?? 'No email';
    userProfilePicture = _fixImageUrl(userData['profile_picture']?.toString());
    shopDescription = userData['shop_description']?.toString() ?? userData['description']?.toString() ?? '';
    totalFollowers = userData['followers_count'] ?? 0;
    totalFollowing = userData['following_count'] ?? 0;
    notifyListeners();
  }

  Future<void> _refreshUserProfile() async {
    // Implementation...
  }

  Future<void> fetchUserProducts() async {
    if (authToken == null) return;
    
    try {
      final allProducts = await ApiService.getUserProducts(authToken!);
      
      sellingItems.clear();
      soldItems.clear();
      
      print('📦 Total products from API: ${allProducts.length}');
      
      for (var product in allProducts) {
        if (product.sold == true) {
          soldItems.add(product);
          print('✅ Added to SOLD: ${product.title}');
        } else {
          if (product.active == true) {
            sellingItems.add(product);
            print('✅ Added to SELLING: ${product.title}');
          }
        }
      }
      
      totalEarnings = soldItems.fold(0.0, (sum, item) => sum + item.price);
      
      print('📊 Selling: ${sellingItems.length}, Sold: ${soldItems.length}');
      print('📊 Total earnings: $totalEarnings');
      
      notifyListeners();
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> fetchUserStats() async {
    // Implementation...
  }

  Future<void> deleteProduct(Product product) async {
    try {
      final deleted = await ApiService.deleteProduct(productId: product.id.toString());
      if (deleted) {
        sellingItems.removeWhere((p) => p.id == product.id);
        soldItems.removeWhere((p) => p.id == product.id);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting product: $e');
    }
  }
}