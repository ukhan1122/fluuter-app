  // lib/services/api_service.dart
  // FACADE - Delegates to modular APIs while maintaining backward compatibility

  import 'dart:async';
  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import '../models/product.dart';
  import '../models/offer.dart';  // ← ADD THIS
  import 'dart:io';
  import 'auth_service.dart';
  import '../config.dart';
  import '../models/product.dart';

  // Import modular APIs
  import 'api/api_client.dart';
  import 'api/auth_api.dart';
  import 'api/product_api.dart';
  import 'api/user_api.dart';
  import 'api/offer_api.dart';    // ← ADD THIS
  import 'api/order_api.dart';     // ← ADD THIS
  import 'api/bank_api.dart';      // ← ADD THIS

  // ============ PRODUCT CACHE CLASS ============
  class ProductCache {
    static List<Product>? _cachedProducts;
    static Future<List<Product>>? _loadingFuture;
    static bool _isLoading = false;


    static String fixImageUrl(String url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('depop-backend.test')) {
      return url.replaceAll('depop-backend.test', '10.0.2.2');
    }
    if (url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

    static Future<List<Product>> getProducts({int limit = 20}) async {
      if (_cachedProducts != null) {
        return _cachedProducts!;
      }
      
      if (_isLoading && _loadingFuture != null) {
        return await _loadingFuture!;
      }
      
      _isLoading = true;
      _loadingFuture = _fetchProductsWithRetry(limit: limit);
      
      try {
        _cachedProducts = await _loadingFuture!;
        return _cachedProducts!;
      } finally {
        _isLoading = false;
        _loadingFuture = null;
      }
    }

    static Future<List<Product>> _fetchProductsWithRetry({int limit = 20}) async {
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          return await ApiService.fetchProducts(limit: limit);
        } catch (e) {
          if (attempt == 3) rethrow;
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
      return [];
    }
    
    static void clearCache() {
      _cachedProducts = null;
      _loadingFuture = null;
      _isLoading = false;
    }
  }

  // ============ API SERVICE FACADE ============
  class ApiService {
    static String get baseUrl => AppConfig.baseUrl;
    
    static Map<String, String> get _headers => AppConfig.getHeaders();
    
    static Map<String, String> _headersWithToken(String? token) {
      return AppConfig.getHeaders(token: token);
    }
    
    // ============ HEALTH & TEST METHODS ============
    static Future<void> testMinimalRequest() async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/health'),
          headers: _headers,
        ).timeout(Duration(seconds: 10));
        print('✅ Health test - Status: ${response.statusCode}');
      } catch (e) {
        print('❌ Health test failed: $e');
      }
    }
    
    static Future<Map<String, dynamic>> testConnection() async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/health'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          return {'success': true, 'data': json.decode(response.body)};
        }
        return {'success': false, 'error': 'Status ${response.statusCode}'};
      } catch (e) {
        return {'success': false, 'error': e.toString()};
      }
    }
    
    // ============ PRODUCT METHODS ============
    static Future<List<Product>> fetchProducts({
      int page = 1,
      int limit = 12,
      String? category,
    }) async {
      return await ProductApi.fetchProducts(page: page, limit: limit, category: category);
    }
    
    static Future<List<Product>> fetchProductsByGroup(
      String group, {
      int page = 1,
      int limit = 12,
    }) async {
      String? backendCategory;
      switch (group.toLowerCase()) {
        case 'men': case 'mens':
          backendCategory = 'men';
          break;
        case 'women': case 'womens':
          backendCategory = 'women';
          break;
        case 'kids':
          backendCategory = 'kids';
          break;
        case 'wedding':
          backendCategory = 'wedding';
          break;
      }
      return fetchProducts(page: page, limit: limit, category: backendCategory);
    }
    
    static Future<List<Product>> getUserProducts(String token, {String status = 'all'}) async {
      return await ProductApi.getUserProducts(token: token, status: status);
    }
    
    static Future<List<Product>> getUserSellingProducts(String token) async {
      return getUserProducts(token, status: 'active');
    }
    
    static Future<List<Product>> getUserSoldProducts(String token) async {
      return getUserProducts(token, status: 'sold');
    }
    
    static Future<Map<String, dynamic>> createListing({
      required String token,
      required Map<String, dynamic> listingData,
      List<String> images = const [],
    }) async {
      return await ProductApi.createListing(token: token, listingData: listingData, images: images);
    }
    
    static Future<List<Map<String, dynamic>>> getCategories() async {
      return await ProductApi.getCategories();
    }
    
    static Future<List<Map<String, dynamic>>> getConditions() async {
      return await ProductApi.getConditions();
    }
    
    static Future<List<Map<String, dynamic>>> getSizes() async {
      return await ProductApi.getSizes();
    }
    
    static Future<List<Map<String, dynamic>>> getBrands() async {
      return await ProductApi.getBrands();
    }
    
    static Future<List<Product>> getSellerProducts(String sellerId) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      return await ProductApi.getSellerProducts(sellerId: sellerId, token: token);
    }
    
    // ============ AUTHENTICATION METHODS ============
    static Future<Map<String, dynamic>> loginUser({
      required String login,
      required String password,
    }) async {
      return await AuthApi.login(login: login, password: password);
    }
    
    static Future<Map<String, dynamic>> sendVerificationCode({required String phone}) async {
      return await AuthApi.sendVerificationCode(phone: phone);
    }
    
    static Future<Map<String, dynamic>> verifyOtpCode({
      required String phone,
      required String otp,
    }) async {
      return await AuthApi.verifyOtp(phone: phone, otp: otp);
    }
    
    static Future<Map<String, dynamic>> forgotPassword({required String email}) async {
      return await AuthApi.forgotPassword(email: email);
    }
    
    static Future<Map<String, dynamic>> setNewPassword({
      required String token,
      required String newPassword,
      required String confirmPassword,
    }) async {
      return await AuthApi.setNewPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    }
    
    static Future<Map<String, dynamic>> logoutUser(String token) async {
      return await AuthApi.logout(token);
    }
    
    static Future<Map<String, dynamic>> getUserProfile(String token) async {
      return await AuthApi.getUserProfile(token);
    }
    
    static Future<bool> checkAuthStatus(String token) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/health'),
          headers: AppConfig.getHeaders(token: token),
        ).timeout(const Duration(seconds: 10));
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    }
    
    static Future<void> testBackendEndpoints(String token) async {
      final endpoint = '$baseUrl/api/v1/listing/auth/products/show';
      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: _headersWithToken(token),
        ).timeout(const Duration(seconds: 15));
        print('📡 Status: ${response.statusCode}');
      } catch (e) {
        print('❌ Network error: $e');
      }
    }
    
    // ============ USER PROFILE METHODS ============
    static Future<Map<String, dynamic>> getSellerProfile(String sellerId) async {
      return await UserApi.getSellerProfile(sellerId);
    }
    
    static Future<Map<String, dynamic>> getSellerShop(String sellerId) async {
      try {
        final authService = AuthService();
        await authService.isLoggedIn();
        final token = authService.token;
        final response = await http.get(
          Uri.parse('$baseUrl/api/v1/shop/$sellerId/shop'),
          headers: _headersWithToken(token),
        ).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          return {'success': true, 'data': json.decode(response.body)['data'] ?? json.decode(response.body)};
        }
        return {'success': false, 'error': 'Failed to load shop info'};
      } catch (e) {
        return {'success': false, 'error': e.toString()};
      }
    }
    
    static Future<Map<String, dynamic>> getSellerRatings(String sellerId) async {
      return await UserApi.getSellerRatings(sellerId);
    }
    
    static Future<List<Map<String, dynamic>>> getSellerReviews(String sellerId) async {
      return await UserApi.getSellerReviews(sellerId);
    }
    
    static Future<Map<String, dynamic>> getUserStats() async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await UserApi.getUserStats(token);
    }
    
    static Future<bool> followUser(String userId) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return false;
      return await UserApi.followUser(userId, token);
    }
    
    static Future<bool> unfollowUser(String userId) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return false;
      return await UserApi.unfollowUser(userId, token);
    }
    
    static Future<List<Map<String, dynamic>>> getMyFollowers() async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return [];
      return await UserApi.getMyFollowers(token);
    }
    
    static Future<List<Map<String, dynamic>>> getMyFollowing() async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return [];
      return await UserApi.getMyFollowing(token);
    }
    
    static Future<bool> checkIfFollowing(String userId) async {
      try {
        final following = await getMyFollowing();
        return following.any((user) => user['id'].toString() == userId);
      } catch (e) {
        return false;
      }
    }
    

    
    static Future<Map<String, dynamic>> verifyOTP({
      required String phone,
      required String otp,
    }) async {
      return await AuthApi.verifyOtp(phone: phone, otp: otp);
    }


    // ============ GUEST CART METHODS ============
static Future<bool> addToGuestCart({
  required String guestId,
  required int productId,
  required int quantity,
}) async {
  try {
    final url = Uri.parse('$baseUrl/api/v1/user/cart/items/guest');
    
    print('📡 Adding to guest cart: $url');
    print('📦 Guest cart payload: guest_id=$guestId, product_id=$productId, quantity=$quantity');
    
    final response = await http.post(
      url,
      headers: AppConfig.getHeaders(),
      body: jsonEncode({
        'guest_id': guestId,
        'product_id': productId,
        'quantity': quantity,
      }),
    ).timeout(const Duration(seconds: 15));
    
    print('📡 Add to guest cart response: ${response.statusCode}');
    print('📡 Response body: ${response.body}');
    
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print('❌ Error adding to guest cart: $e');
    return false;
  }
}
    
    // ============ OFFER METHODS ============
    static Future<List<Offer>> getReceivedOffers() async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return [];
      return await OfferApi.getReceivedOffers(token);
    }
    
    static Future<List<Offer>> getSentOffers() async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return [];
      return await OfferApi.getSentOffers(token);
    }
    
    static Future<List<Offer>> getOfferConversation({
      required int productId,
      required int buyerId,
      required int sellerId,
    }) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return [];
      return await OfferApi.getConversation(
        token: token,
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
      );
    }
    
    static Future<Map<String, dynamic>> createOffer({
      required int productId,
      required double offerPrice,
      String? message,
    }) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await OfferApi.createOffer(
        token: token,
        productId: productId,
        offerPrice: offerPrice,
        message: message,
      );
    }
    
    static Future<Map<String, dynamic>> updateOfferPrice({
      required int offerId,
      required double newPrice,
      required int productId,
      String? message,
    }) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await OfferApi.updateOfferPrice(
        token: token,
        offerId: offerId,
        newPrice: newPrice,
        productId: productId,
        message: message,
      );
    }
    
    static Future<Map<String, dynamic>> acceptOffer(int offerId) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await OfferApi.acceptOffer(token: token, offerId: offerId);
    }
    
    static Future<Map<String, dynamic>> rejectOffer(int offerId) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await OfferApi.rejectOffer(token: token, offerId: offerId);
    }
    
    static Future<Map<String, dynamic>> counterOffer({
      required int offerId,
      required double price,
      String? message,
    }) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await OfferApi.counterOffer(
        token: token,
        offerId: offerId,
        price: price,
        message: message,
      );
    }
    // ============ ORDER METHODS ============
  static Future<bool> addToCart({
    required int productId,
    required int quantity,
  }) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    if (token == null) return false;
    return await OrderApi.addToCart(
      token: token,
      productId: productId,
      quantity: quantity,
    );
  }

  static Future<List<Map<String, dynamic>>> getUserAddresses(String token) async {
    return await OrderApi.getUserAddresses(token);
  }
static Future<Map<String, dynamic>> createAddress({
  required String address,
  required String city,
  required String phone,
}) async {
  final authService = AuthService();
  await authService.isLoggedIn();
  final token = authService.token;
  
  // For guest users, create address without token
  // The backend should handle guest addresses differently
  try {
    final url = Uri.parse('$baseUrl/api/v1/addresses');
    
    final Map<String, dynamic> addressData = {
      'address': address,
      'city': city,
      'phone': phone,
    };
    
    final response = await http.post(
      url,
      headers: token != null 
          ? AppConfig.getHeaders(token: token)
          : {'Content-Type': 'application/json'},
      body: jsonEncode(addressData),
    ).timeout(const Duration(seconds: 15));
    
    print('📡 Address Response: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return {
        'success': true,
        'data': responseData['data'] ?? {'id': responseData['id'] ?? responseData},
      };
    }
    return {'success': false, 'error': 'Failed to create address'};
  } catch (e) {
    print('❌ Error creating address: $e');
    return {'success': false, 'error': e.toString()};
  }
}

  static Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> orderData,
  }) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    if (token == null) return {'success': false, 'error': 'Not authenticated'};
    return await OrderApi.createOrder(token: token, orderData: orderData);
  }



  // ============ ADD THIS NEW METHOD FOR GUEST CHECKOUT ============
 static Future<Map<String, dynamic>> createGuestOrder(Map<String, dynamic> guestPayload) async {
  try {
    final url = Uri.parse('$baseUrl/api/v1/cart/checkout/create/guest');
    
    print('📡 Calling guest checkout endpoint: $url');
    print('📦 Guest payload: ${jsonEncode(guestPayload)}');
    
    final response = await http.post(
      url,
      headers: AppConfig.getHeaders(),  // ← USE THIS to include Host header
      body: jsonEncode(guestPayload),
    ).timeout(const Duration(seconds: 30));
      
      print('📡 Guest Order Response Status: ${response.statusCode}');
      print('📡 Guest Order Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Order placed successfully',
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? errorData['error'] ?? 'Failed to place order',
          'message': errorData['message'] ?? 'Failed to place order',
        };
      }
    } catch (e) {
      print('❌ Error creating guest order: $e');
      return {'success': false, 'error': e.toString(), 'message': 'Network error'};
    }
  }
  // ============ END OF GUEST CHECKOUT METHOD ============

  static Future<int?> getCurrentUserId() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    if (token == null) return null;
    return await OrderApi.getCurrentUserId(token);
  }
    
    // ============ BANK METHODS ============
    static Future<Map<String, dynamic>> getBankDetails() async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await BankApi.getBankDetails(token);
    }
    
    static Future<Map<String, dynamic>> createBankDetails({
      required String accountHolderName,
      required String bankName,
      required String accountNumber,
      String? routingNumber,
      String? iban,
      String? swiftCode,
    }) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await BankApi.createBankDetails(
        token: token,
        accountHolderName: accountHolderName,
        bankName: bankName,
        accountNumber: accountNumber,
        routingNumber: routingNumber,
        iban: iban,
        swiftCode: swiftCode,
      );
    }
    
    static Future<Map<String, dynamic>> getBankTransactions({int limit = 20}) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return {'success': false, 'error': 'Not authenticated'};
      return await BankApi.getBankTransactions(token: token, limit: limit);
    }

      // Add this to PRODUCT METHODS section
    static Future<bool> deleteProduct({
      required String productId,
    }) async {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      if (token == null) return false;
      return await ProductApi.deleteProduct(productId: productId, token: token);
    }
  }