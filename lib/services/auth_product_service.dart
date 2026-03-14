// lib/services/auth_product_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'auth_service.dart';

class AuthProductService {
  static String get baseUrl {
    const bool forceLocal = true;
    
    if (forceLocal) {
      if (Platform.isAndroid) {
        const bool isEmulator = true;
        if (isEmulator) {
          return 'http://10.0.2.2:80';
        } else {
          return 'https://untimid-nonobjectivistic-wade.ngrok-free.dev';
        }
      } else if (Platform.isIOS) {
        return 'http://localhost:80';
      } else {
        return 'http://localhost:80';
      }
    } else {
      return 'https://laravel-backend.onrender.com';
    }
  }

  static Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    
    if (!baseUrl.contains('ngrok')) {
      headers['Host'] = 'depop-backend.test';
    }
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // ============ PRODUCT MANAGEMENT ============

  /// 1. SEARCH USER PRODUCTS
  /// GET /api/v1/listing/auth/products/search
  static Future<List<Product>> searchProducts({
    String? query,
    String? status,
    String? categoryId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
  }) async {
    print('🔍 Searching user products with query: $query');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        print('❌ No auth token found');
        return [];
      }
      
      // Build query parameters
      String url = '$baseUrl/api/v1/listing/auth/products/search';
      List<String> params = [];
      
      if (query != null && query.isNotEmpty) {
        params.add('q=${Uri.encodeComponent(query)}');
      }
      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        params.add('category_id=$categoryId');
      }
      if (brandId != null && brandId.isNotEmpty) {
        params.add('brand_id=$brandId');
      }
      if (minPrice != null) {
        params.add('min_price=$minPrice');
      }
      if (maxPrice != null) {
        params.add('max_price=$maxPrice');
      }
      
      if (params.isNotEmpty) {
        url += '?' + params.join('&');
      }
      
      print('🌐 URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));
      
      print('📡 Search Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> productsJson = responseData['data'] ?? responseData['products'] ?? [];
        
        print('✅ Found ${productsJson.length} products matching search');
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - Token invalid');
      } else {
        print('❌ Search failed: ${response.statusCode}');
      }
      
      return [];
    } on TimeoutException {
      print('⏰ Search timeout');
      return [];
    } catch (e) {
      print('❌ Error searching products: $e');
      return [];
    }
  }

// In auth_product_service.dart, update the updateProduct method:

static Future<Map<String, dynamic>> updateProduct({
  required String productId,
  required Map<String, dynamic> productData,
}) async {
  print('📝 Updating product: $productId');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    
    // Ensure we're sending the right field names
    Map<String, dynamic> apiData = {
      'title': productData['title'],
      'description': productData['description'],
      'price': productData['price'],
      'quantity': productData['quantity'] ?? '1',
      'category_id': productData['category_id'],
      'condition_id': productData['condition_id'],
      'brand_id': productData['brand_id'],  // Changed from brand_name to brand_id
    };
    
    // Only add size if it exists
    if (productData['size'] != null && productData['size'].toString().isNotEmpty) {
      apiData['size'] = productData['size'];
    }
    
    print('📤 Sending to API: $apiData');
    
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/listing/auth/products/$productId'),
      headers: {
        ..._getHeaders(token),
        'Content-Type': 'application/json',
      },
      body: json.encode(apiData),
    ).timeout(const Duration(seconds: 15));

    print('📡 Update Product Status: ${response.statusCode}');
    print('📡 Update Product Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return {
        'success': true,
        'data': responseData['data'] ?? responseData,
        'message': responseData['message'] ?? 'Product updated successfully',
      };
    } else {
      String errorMsg = 'Update failed';
      try {
        final errorData = json.decode(response.body);
        errorMsg = errorData['message'] ?? errorData['error'] ?? 'Update failed';
      } catch (_) {}
      
      return {'success': false, 'error': errorMsg};
    }
  } on TimeoutException {
    return {'success': false, 'error': 'Connection timeout'};
  } catch (e) {
    print('❌ Error updating product: $e');
    return {'success': false, 'error': e.toString()};
  }
}

  /// 3. DELETE PRODUCT
  /// DELETE /api/v1/listing/auth/products/{id}
  static Future<bool> deleteProduct({
    required String productId,
  }) async {
    print('🗑️ Deleting product: $productId');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        print('❌ No auth token found');
        return false;
      }
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/listing/auth/products/$productId'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));
      
      print('📡 Delete Product Status: ${response.statusCode}');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } on TimeoutException {
      print('⏰ Delete timeout');
      return false;
    } catch (e) {
      print('❌ Error deleting product: $e');
      return false;
    }
  }

  /// 4. UPDATE PRODUCT PHOTOS
  /// POST /api/v1/listing/auth/products/{id}/photos
  static Future<Map<String, dynamic>> updateProductPhotos({
    required String productId,
    List<String> images = const [],
  }) async {
    print('📸 Updating photos for product: $productId with ${images.length} images');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/listing/auth/products/$productId/photos'),
      );
      
      request.headers.addAll(_getHeaders(token));
      
      // Add images
      for (int i = 0; i < images.length; i++) {
        var imageFile = File(images[i]);
        if (await imageFile.exists()) {
          var multipartFile = await http.MultipartFile.fromPath(
            'photos[]',  // Laravel expects 'photos[]' not 'images[]'
            imageFile.path,
          );
          request.files.add(multipartFile);
          print('📸 Added image ${i + 1}: ${imageFile.path}');
        }
      }
      
      if (request.files.isEmpty) {
        return {'success': false, 'error': 'No valid images to upload'};
      }
      
      print('🚀 Sending ${request.files.length} images...');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Update Photos Status: ${response.statusCode}');
      print('📡 Update Photos Response: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Photos updated successfully',
        };
      } else {
        String errorMsg = 'Failed to update photos';
        try {
          final errorData = json.decode(response.body);
          errorMsg = errorData['message'] ?? errorData['error'] ?? errorMsg;
        } catch (_) {}
        
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ Error updating photos: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 5. DELETE SINGLE PHOTO
  /// Add this if you need to delete individual photos
  static Future<bool> deleteProductPhoto({
    required String productId,
    required String photoId,
  }) async {
    print('🗑️ Deleting photo $photoId from product $productId');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) return false;
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/listing/auth/products/$productId/photos/$photoId'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting photo: $e');
      return false;
    }
  }

  /// 6. GET SINGLE PRODUCT (for editing)
  /// GET /api/v1/listing/auth/products/{id}
  static Future<Product?> getProductForEdit({
    required String productId,
  }) async {
    print('📦 Fetching product $productId for editing');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        print('❌ No auth token found');
        return null;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/listing/auth/products/$productId'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));
      
      print('📡 Get Product Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final productJson = responseData['data'] ?? responseData;
        return Product.fromJson(productJson);
      }
      
      return null;
    } catch (e) {
      print('❌ Error fetching product: $e');
      return null;
    }
  }

  /// 7. BULK DELETE PRODUCTS
  /// Optional: Delete multiple products at once
  static Future<Map<String, dynamic>> deleteMultipleProducts({
    required List<String> productIds,
  }) async {
    print('🗑️ Deleting ${productIds.length} products');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/listing/auth/products/bulk-delete'),
        headers: {
          ..._getHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode({'product_ids': productIds}),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Products deleted successfully',
        };
      } else {
        return {'success': false, 'error': 'Bulk delete failed'};
      }
    } catch (e) {
      print('❌ Error in bulk delete: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}