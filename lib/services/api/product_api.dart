import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../../models/product.dart';

class ProductApi {
  static Future<List<Product>> fetchProducts({
    int page = 1,
    int limit = 12,
    String? category,
  }) async {
    try {
      String url = '/api/v1/listing/public/products/show?page=$page&limit=$limit';
      if (category != null && category.isNotEmpty) url += '&category=$category';
      
      final response = await ApiClient.get(url, timeout: const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        if (data.containsKey('data') && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => Product.fromJson(json))
              .where((p) => !p.sold && p.quantityLeft > 0)
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Product>> getUserProducts({
    required String token,
    String status = 'all',
  }) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/listing/auth/products/show',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        List<dynamic> productsJson = data['data'] is List ? data['data'] : [];
        
        final allProducts = productsJson.map((json) => Product.fromJson(json)).toList();
        
        if (status == 'active') {
          return allProducts.where((p) => !p.sold && p.active).toList();
        } else if (status == 'sold') {
          return allProducts.where((p) => p.sold || !p.active).toList();
        }
        return allProducts;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  



static Future<Map<String, dynamic>> createListing({
  required String token,
  required Map<String, dynamic> listingData,
  List<String> images = const [],
}) async {
  try {
    // ✅ VALIDATION
    print('📸 Images received: ${images.length}');
    if (images.isEmpty) {
      return {
        'success': false, 
        'error': 'Please select at least 2 images'
      };
    }
    
    if (images.length < 2) {
      return {
        'success': false, 
        'error': 'Please select ${2 - images.length} more image(s) (${images.length}/2)'
      };
    }
    
    final fields = Map<String, String>.from(
      listingData.map((key, value) => MapEntry(key, value.toString()))
    );
    fields['active'] = 'true';
    fields['sold'] = 'false';
    
    final files = <http.MultipartFile>[];
    for (final imagePath in images) {
      final file = File(imagePath);
      if (await file.exists()) {
        files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }
    }
    
    final response = await ApiClient.multipartPost(
      '/api/v1/listing/auth/products/create',
      token: token,
      fields: fields,
      files: files,
    );
    
    print('📥 Response status code: ${response.statusCode}');
    print('📥 Full response body: ${response.body}');
    
    if (response.statusCode == 400 && response.body.contains('SMTP')) {
      return {'success': true, 'smtp_error': true, 'message': 'Listing created (email failed)'};
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': ApiClient.parseResponse(response)};
    }
    
    // ✅ Parse and return the actual validation errors
    try {
      final errorData = ApiClient.parseResponse(response);
      
      // Check if there are validation errors
      if (errorData.containsKey('errors') && errorData['errors'] is Map) {
        final Map<String, dynamic> errors = errorData['errors'];
        
        // Build a user-friendly error message
        StringBuffer errorMessage = StringBuffer();
        
        if (errors.containsKey('location')) {
          errorMessage.writeln('• Location: ${errors['location'][0]}');
        }
        if (errors.containsKey('size')) {
          errorMessage.writeln('• Size: ${errors['size'][0]}');
        }
        if (errors.containsKey('title')) {
          errorMessage.writeln('• Title: ${errors['title'][0]}');
        }
        if (errors.containsKey('price')) {
          errorMessage.writeln('• Price: ${errors['price'][0]}');
        }
        if (errors.containsKey('images')) {
          errorMessage.writeln('• Images: ${errors['images'][0]}');
        }
        
        // If we have specific field errors, return them
        if (errorMessage.isNotEmpty) {
          return {
            'success': false, 
            'error': errorMessage.toString().trim(),
            'validationErrors': errors
          };
        }
      }
      
      // Return the main message if no specific fields
      return {
        'success': false, 
        'error': errorData['message'] ?? errorData['error'] ?? 'Failed to create listing'
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to create listing: ${response.body}'};
    }
  } catch (e) {
    print('❌ Exception: $e');
    return {'success': false, 'error': e.toString()};
  }
}


  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await ApiClient.get('/api/v1/listing/categories');
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        if (data.containsKey('data') && data['data'] is Map) {
          final categories = <Map<String, dynamic>>[];
          (data['data'] as Map).forEach((group, list) {
            if (list is List) {
              for (var cat in list) {
                categories.add({
                  'id': cat['id'].toString(),
                  'name': cat['name'].toString(),
                  'group': group,
                });
              }
            }
          });
          return categories;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getConditions() async {
    try {
      final response = await ApiClient.get('/api/v1/listing/conditions');
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        if (data.containsKey('data') && data['data'] is List) {
          return (data['data'] as List).map((c) => {
            'id': c['id'].toString(),
            'name': c['title']?.toString() ?? '',
            'value': c['title']?.toString() ?? '',
          }).toList();
        }
      }
      return [
        {'id': '1', 'name': 'Brand new', 'value': 'new'},
        {'id': '2', 'name': 'Like new', 'value': 'like_new'},
        {'id': '3', 'name': 'Used - Excellent', 'value': 'excellent'},
        {'id': '4', 'name': 'Used - Good', 'value': 'good'},
        {'id': '5', 'name': 'Used - Fair', 'value': 'fair'},
      ];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      final response = await ApiClient.get('/api/v1/listing/brands');
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        if (data.containsKey('data') && data['data'] is List) {
          return (data['data'] as List).map((b) => {
            'id': b['id'].toString(),
            'name': b['name'].toString(),
          }).toList();
        }
      }
      return [
        {'id': '1', 'name': 'Nike'},
        {'id': '2', 'name': 'Adidas'},
        {'id': '3', 'name': 'Apple'},
      ];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getSizes() async {
    try {
      final response = await ApiClient.get('/api/v1/listing/public/products/the/products/sizes');
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        if (data.containsKey('data') && data['data'] is List) {
          return (data['data'] as List).map((s) => {
            'id': s['id'].toString(),
            'name': s['name'].toString(),
            'value': s['value']?.toString() ?? s['name'].toString(),
          }).toList();
        }
      }
      return [
        {'id': '1', 'name': 'XS', 'value': 'xs'},
        {'id': '2', 'name': 'S', 'value': 's'},
        {'id': '3', 'name': 'M', 'value': 'm'},
        {'id': '4', 'name': 'L', 'value': 'l'},
        {'id': '5', 'name': 'XL', 'value': 'xl'},
      ];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Product>> getSellerProducts({
    required String sellerId,
    String? token,
  }) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/listing/seller/$sellerId',
        token: token,
      );
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        List<dynamic> productsJson = [];

        if (data.containsKey('data') && data['data'] is Map) {
          final productsData = data['data']['products'];
          if (productsData is Map && productsData.containsKey('data')) {
            productsJson = productsData['data'];
          }
        } else if (data.containsKey('data') && data['data'] is List) {
          productsJson = data['data'];
        } else if (data.containsKey('products') && data['products'] is List) {
          productsJson = data['products'];
        }

        return productsJson.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching seller products: $e');
      return [];
    }
  }

  // ✅ ADD THIS METHOD - DELETE PRODUCT
  static Future<bool> deleteProduct({
    required String productId,
    required String token,
  }) async {
    try {
      print('🗑️ Deleting product: $productId');
      final response = await ApiClient.delete(
        '/api/v1/listing/auth/products/$productId',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      print('📡 Delete Product Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting product: $e');
      return false;
    }
  }
}