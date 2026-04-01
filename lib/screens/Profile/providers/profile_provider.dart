import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/product.dart';  // ← Fix this path
import '../../../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  List<Product> sellingItems = [];
  List<Product> soldItems = [];
  bool isLoading = true;
  
  String userName = '';
  String userEmail = '';
  String? userProfilePicture;
  String? authToken;
  String memberSince = '';
  double totalEarnings = 0.0;
  int totalFollowers = 0;
  int totalFollowing = 0;

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
    userProfilePicture = userData['profile_picture']?.toString();
    totalFollowers = userData['followers_count'] ?? 0;
    totalFollowing = userData['following_count'] ?? 0;
    notifyListeners();
  }

  Future<void> _refreshUserProfile() async {
    // Implementation...
  }

  Future<void> fetchUserProducts() async {
    if (authToken == null) return;
    
    final allProducts = await ApiService.getUserProducts(authToken!);
    
    sellingItems = allProducts.where((p) => !p.sold && p.active).toList();
    soldItems = allProducts.where((p) => p.sold || !p.active).toList();
    totalEarnings = soldItems.fold(0.0, (sum, p) => sum + p.price);
    
    notifyListeners();
  }

  Future<void> fetchUserStats() async {
    // Implementation...
  }

  Future<void> deleteProduct(Product product) async {
    final deleted = await ApiService.deleteProduct(productId: product.id.toString());
    if (deleted) {
      sellingItems.removeWhere((p) => p.id == product.id);
      soldItems.removeWhere((p) => p.id == product.id);
      notifyListeners();
    }
  }
}