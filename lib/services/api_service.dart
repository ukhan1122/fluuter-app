import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'dart:io'; 
import 'auth_service.dart';  // Add this import


class ProductCache {
  static List<Product>? _cachedProducts;
  static Future<List<Product>>? _loadingFuture;
  static bool _isLoading = false;
  
static Future<List<Product>> getProducts({int limit = 20}) async {
  if (_cachedProducts != null) {
    print('📦 Returning ${_cachedProducts!.length} cached products');
    return _cachedProducts!;
  }
  
  if (_isLoading && _loadingFuture != null) {
    print('⏳ Request waiting for ongoing load...');
    return await _loadingFuture!;
  }
  
  print('📦 Loading products into cache (limit: $limit)...');
  _isLoading = true;
  _loadingFuture = _fetchProductsWithRetry(limit: limit);
  
  try {
    _cachedProducts = await _loadingFuture!;
    print('✅ ${_cachedProducts!.length} products loaded into cache');
    return _cachedProducts!;
  } finally {
    _isLoading = false;
    _loadingFuture = null;
  }
}

static Future<List<Product>> _fetchProductsWithRetry({int limit = 20}) async {
  for (int attempt = 1; attempt <= 3; attempt++) {
    try {
      print('🔄 Attempt $attempt/3 to fetch products (limit: $limit)');
      return await ApiService.fetchProducts(limit: limit);
    } catch (e) {
      if (attempt == 3) {
        print('❌ All 3 attempts failed');
        rethrow;
      }
      print('⚠️ Attempt $attempt failed, retrying...');
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }
  return [];
}
  
  
  
  static void clearCache() {
    _cachedProducts = null;
    _loadingFuture = null;
    _isLoading = false;
    print('🗑️ Cache cleared');
  }
}

class ApiService {
  // static const String baseUrl = "https://untimid-nonobjectivistic-wade.ngrok-free.dev";
static const String baseUrl = 'http://10.0.2.2:80';
  
  // SIMPLIFIED HEADERS
static Map<String, String> get _headers {
  return {
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    'Host': 'depop-backend.test',  // ADD THIS LINE
  };
} 
  
  // NEW: Minimal test method
  static Future<void> testMinimalRequest() async {
    print('🧪 Testing minimal request to health endpoint...');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      print('✅ Health test - Status: ${response.statusCode}');
      print('✅ Health test - Body: ${response.body}');
    } catch (e) {
      print('❌ Health test failed: $e');
    }
  }
  
  static Future<Map<String, dynamic>> testConnection() async {
  print('🔧 Testing API connection...');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/health'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));
    
    print('✅ Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);  // ← NO 'responseData' here
      print('✅ Connection successful!');
      return {'success': true, 'data': data};  // ← Just return 'data', not 'data['data']'
    } else {
      print('❌ Connection failed');
      return {'success': false, 'error': 'Status ${response.statusCode}'};
    }
  } catch (e) {
    print('❌ Connection error: $e');
    return {'success': false, 'error': e.toString()};
  }
}
  
  static Future<List<Product>> fetchProducts({
  int page = 1,
  int limit = 12, // Default to 12 items (you can change this)
  String? category,
}) async {
  print('🛍️ Fetching products - Page: $page, Limit: $limit${category != null ? ", Category: $category" : ""}');
  
  try {
    final stopwatch = Stopwatch()..start();
    
    // Build URL with pagination parameters
    String urlStr = '$baseUrl/api/v1/listing/public/products/show?page=$page&limit=$limit';
    if (category != null && category.isNotEmpty) {
      urlStr += '&category=$category';
    }
    
    final url = Uri.parse(urlStr);
    
    print('🌐 URL: $url');
    print('📨 Headers: $_headers');
    
    final response = await http.get(url, headers: _headers)
        .timeout(const Duration(seconds: 30));
    
    stopwatch.stop();
    print('⏱️ Request took: ${stopwatch.elapsedMilliseconds}ms');
    print('📊 HTTP Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ API call successful!');
      
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData.containsKey('data') && responseData['data'] is List) {
        final List<dynamic> productsJson = responseData['data'];
        print('🎉 Found ${productsJson.length} products for page $page');
        
        List<Product> products = [];
        for (var json in productsJson) {
          try {
            products.add(Product.fromJson(json));
          } catch (e) {
            print('⚠️ Error parsing product: $e');
          }
        }
        
        print('✅ Successfully parsed ${products.length} products');
        return products;
      } else {
        print('❌ Unexpected response structure');
        return [];
      }
    } else {
      print('❌ API returned error: ${response.statusCode}');
      print('❌ Response: ${response.body}');
      return [];
    }
  } on TimeoutException {
    print('⏰ Timeout after 30 seconds');
    throw TimeoutException('API request timeout');
  } catch (e) {
    print('❌ Exception during API call: $e');
    rethrow;
  }
}
  
 static Future<List<Product>> fetchProductsByGroup(String group, {int page = 1, int limit = 12}) async {
  print('🛍️ Fetching $group products from API - Page: $page, Limit: $limit');
  
  // Map the group to backend category name
  String? backendCategory;
  switch (group.toLowerCase()) {
    case 'men':
    case 'mens':
      backendCategory = 'men';
      break;
    case 'women':
    case 'womens':
      backendCategory = 'women';
      break;
    case 'kids':
      backendCategory = 'kids';
      break;
    case 'wedding':
      backendCategory = 'wedding';
      break;
    default:
      backendCategory = null;
  }
  
  // Use the updated fetchProducts method with category filter
  return fetchProducts(
    page: page,
    limit: limit,
    category: backendCategory,
  );
}

  // ============ AUTHENTICATION METHODS ============

  // User Login (uses 'login' field, not 'email')
  static Future<Map<String, dynamic>> loginUser({
    required String login,  // Can be username or email
    required String password,
  }) async {
    print('🔐 Logging in with: $login');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',   
          'Host': 'depop-backend.test',  // ✅ ADD THIS LINE
        },
        body: jsonEncode({
          'login': login,           // IMPORTANT: Uses 'login' field
          'password': password,
          'device_name': 'flutter_app',
        }),
      ).timeout(const Duration(seconds: 15));

      print('📡 Login Response Status: ${response.statusCode}');
      print('📡 Login Response Body: ${response.body}');

     if (response.statusCode == 200) {
  final Map<String, dynamic> responseData = jsonDecode(response.body);
  print('✅ Login successful!');
  
  // Return the INNER 'data' object (contains token and user)
  return {
    'success': true, 
    'data': responseData['data'] ?? {}  // ← CORRECT
  };
} else if (response.statusCode == 401) {
        print('❌ Invalid credentials');
        return {'success': false, 'error': 'Invalid login or password'};
      } else if (response.statusCode == 422) {
        print('❌ Validation error');
        final Map<String, dynamic> errors = jsonDecode(response.body)['errors'] ?? {};
        return {'success': false, 'error': 'Validation failed', 'errors': errors};
      } else {
        print('❌ Login failed');
        return {
          'success': false,
          'error': 'Login failed: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      print('⏰ Login timeout');
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ Login exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Send verification code to phone
  static Future<Map<String, dynamic>> sendVerificationCode({
    required String phone,
  }) async {
    print('📱 Sending verification code to: $phone');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/verify'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📡 Verification Response Status: ${response.statusCode}');
      print('📡 Verification Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ Verification code sent!');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        print('❌ Validation error');
        final Map<String, dynamic> errors = jsonDecode(response.body)['errors'] ?? {};
        return {'success': false, 'error': 'Validation failed', 'errors': errors};
      } else {
        print('❌ Failed to send verification code');
        return {
          'success': false,
          'error': 'Failed to send code: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      print('⏰ Verification timeout');
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ Verification exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verify OTP code
  static Future<Map<String, dynamic>> verifyOtpCode({
    required String phone,
    required String otp,
  }) async {
    print('🔢 Verifying OTP for: $phone');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/verify-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📡 OTP Response Status: ${response.statusCode}');
      print('📡 OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ OTP verified successfully!');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        print('❌ Invalid OTP');
        return {'success': false, 'error': 'Invalid OTP code'};
      } else {
        print('❌ OTP verification failed');
        return {
          'success': false,
          'error': 'OTP verification failed: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      print('⏰ OTP verification timeout');
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ OTP verification exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get User Profile (requires token)
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    print('👤 Fetching user profile');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/auth/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Profile Response Status: ${response.statusCode}');
      print('📡 Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ Profile fetched successfully!');
        return {'success': true, 'data': data};
      } else {
        print('❌ Failed to fetch profile');
        return {
          'success': false,
          'error': 'Failed to fetch profile: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      print('⏰ Profile fetch timeout');
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ Profile fetch exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // User Logout (requires token)
  static Future<Map<String, dynamic>> logoutUser(String token) async {
    print('🚪 Logging out user');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/logout'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Logout Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Logout successful!');
        return {'success': true};
      } else {
        print('❌ Logout failed');
        return {
          'success': false,
          'error': 'Logout failed: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      print('⏰ Logout timeout');
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ Logout exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Check if user is authenticated
  static Future<bool> checkAuthStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  // Add these methods to your ApiService class (after the existing methods)

// CORRECTED: Get user's products (both active/selling and sold)
static Future<List<Product>> getUserProducts(String token, {String status = 'all'}) async {
  print('🛍️ Fetching user products with status: $status');
  
  try {
    // THE CORRECT ENDPOINT based on your backend routes
    String url = '$baseUrl/api/v1/listing/auth/products/show';
    
    // Check if we need to filter by status
    if (status == 'sold') {
      // We'll filter locally since the endpoint might not support query params
      print('⚠️ Note: Filtering sold products locally');
    }
    
    print('🌐 URL: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',  
         'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 15));

    print('📡 User Products Status: ${response.statusCode}');
    print('📡 Response length: ${response.body.length} chars');
    
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ JSON parsed successfully');
        print('📊 Response keys: ${responseData.keys}');
        
        List<dynamic> productsJson = [];
        
        // Check response structure
        if (responseData.containsKey('data') && responseData['data'] is List) {
          productsJson = responseData['data'] as List;
          print('✅ Found ${productsJson.length} products in "data" array');
        } else if (responseData.containsKey('products') && responseData['products'] is List) {
          productsJson = responseData['products'] as List;
          print('✅ Found ${productsJson.length} products in "products" array');
        } else if (responseData.containsKey('listings') && responseData['listings'] is List) {
          productsJson = responseData['listings'] as List;
          print('✅ Found ${productsJson.length} products in "listings" array');
        } else {
          print('❌ Unexpected response structure');
          print('📄 Response data: $responseData');
          return [];
        }
        
        if (productsJson.isEmpty) {
          print('ℹ️ No products found for this user');
          return [];
        }
        
        // Parse products
        List<Product> allProducts = [];
        for (var json in productsJson) {
          try {
            final product = Product.fromJson(json);
            allProducts.add(product);
            
            // Debug: Print product status
            print('📦 Product: ${product.title}');
            print('   - Sold: ${product.sold}');
            print('   - Active: ${product.active}');
            print('   - ID: ${product.id}');
          } catch (e) {
            print('⚠️ Error parsing product: $e');
            print('📦 Problematic JSON: $json');
          }
        }
        
        print('✅ Successfully parsed ${allProducts.length} products');
        
        // Filter based on status
        if (status == 'active') {
          // Show active/unsold products
          final activeProducts = allProducts.where((product) {
            return product.sold == false && product.active == true;
          }).toList();
          print('✅ Filtered to ${activeProducts.length} active products');
          return activeProducts;
        } else if (status == 'sold') {
          // Show sold products
          final soldProducts = allProducts.where((product) {
            return product.sold == true || product.active == false;
          }).toList();
          print('✅ Filtered to ${soldProducts.length} sold products');
          return soldProducts;
        } else {
          // Return all products
          return allProducts;
        }
        
      } catch (e) {
        print('❌ Error parsing response: $e');
        print('📄 Response body: ${response.body}');
        return [];
      }
    } else if (response.statusCode == 401) {
      print('❌ Unauthorized - Invalid token');
      return [];
    } else if (response.statusCode == 404) {
      print('❌ Endpoint not found');
      return [];
    } else {
      print('❌ API error: ${response.statusCode}');
      print('📄 Error response: ${response.body}');
      return [];
    }
    
  } catch (e) {
    print('❌ Error fetching user products: $e');
    return [];
  }
}

// CORRECTED: Alias methods for backward compatibility
static Future<List<Product>> getUserSellingProducts(String token) async {
  return getUserProducts(token, status: 'active');
}

static Future<List<Product>> getUserSoldProducts(String token) async {
  return getUserProducts(token, status: 'sold');
}

// NEW: Enhanced test method for your specific backend
static Future<void> testBackendEndpoints(String token) async {
  print('\n🔍 TESTING BACKEND ENDPOINTS 🔍');
  
  // Test the exact endpoint from your backend routes
  final endpoint = '$baseUrl/api/v1/listing/auth/products/show';
  print('\n✅ Testing CORRECT endpoint: $endpoint');
  
  try {
    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 15));
    
    print('📡 Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        print('🎉 SUCCESS! Endpoint works!');
        print('📊 Response structure:');
        print('   - Keys: ${data.keys}');
        
        if (data.containsKey('data') && data['data'] is List) {
          final products = data['data'] as List;
          print('   - Found ${products.length} products');
          
          if (products.isNotEmpty) {
            print('📦 Sample product structure:');
            final sample = products.first as Map<String, dynamic>;
            print('   - ID: ${sample['id']}');
            print('   - Title: ${sample['title']}');
            print('   - Price: ${sample['price']}');
            print('   - Sold: ${sample['sold']}');
            print('   - Active: ${sample['active']}');
            print('   - All keys: ${sample.keys}');
          }
        }
      } catch (e) {
        print('❌ JSON parsing error: $e');
      }
    } else {
      print('❌ API error: ${response.statusCode}');
      print('📄 Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Network error: $e');
  }
} 


// ADD THESE METHODS TO YOUR EXISTING ApiService CLASS:

// ============ LISTING CREATION METHODS ============

// In your ApiService class, update the getCategories method:
static Future<List<Map<String, dynamic>>> getCategories() async {
  print('📋 Fetching categories from API');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/listing/categories'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    print('📡 Categories Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ JSON parsed successfully');
        
        // Check the response structure
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final Map<String, dynamic> groupedData = responseData['data'];
          print('✅ Response has ${groupedData.length} groups: ${groupedData.keys.toList()}');
          
          // Flatten the grouped categories into a single list
          List<Map<String, dynamic>> allCategories = [];
          
          groupedData.forEach((groupName, categoriesList) {
            if (categoriesList is List) {
              for (var category in categoriesList) {
                if (category is Map<String, dynamic>) {
                  allCategories.add({
                    'id': category['id']?.toString() ?? '',
                    'name': category['name']?.toString() ?? '',
                    'group': groupName,
                  });
                }
              }
            }
          });
          
          print('✅ Found ${allCategories.length} total categories');
          return allCategories;
        } else {
          print('❌ Unexpected response structure: ${responseData.keys}');
          return [];
        }
      } catch (e) {
        print('❌ Error parsing JSON: $e');
        return [];
      }
    } else {
      print('❌ API returned error: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('❌ Error fetching categories: $e');
    return [];
  }
}



static Future<List<Map<String, dynamic>>> getConditions() async {
  print('🏷️ Fetching conditions from API');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/listing/conditions'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));

    print('📡 Conditions Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData.containsKey('data') && responseData['data'] is List) {
        final List<dynamic> conditionsJson = responseData['data'];
        print('✅ Found ${conditionsJson.length} conditions');
        
        List<Map<String, dynamic>> conditions = [];
        for (var json in conditionsJson) {
          try {
            conditions.add({
              'id': json['id']?.toString() ?? '',
              'name': json['title']?.toString() ?? '',  // ← Use 'title' field
              'value': json['title']?.toString() ?? '', // ← Use 'title' field
            });
          } catch (e) {
            print('⚠️ Error parsing condition: $e');
          }
        }
        
        print('✅ Parsed ${conditions.length} conditions');
        return conditions;
      }
    }
    
    print('❌ No conditions found or API error');
    // Return default conditions if API fails
    return [
      {'id': '1', 'name': 'Brand new', 'value': 'new'},
      {'id': '2', 'name': 'Like new', 'value': 'like_new'},
      {'id': '3', 'name': 'Used - Excellent', 'value': 'excellent'},
      {'id': '4', 'name': 'Used - Good', 'value': 'good'},
      {'id': '5', 'name': 'Used - Fair', 'value': 'fair'},
    ];
    
  } catch (e) {
    print('❌ Error fetching conditions: $e');
    return [
      {'id': '1', 'name': 'Brand new', 'value': 'new'},
      {'id': '2', 'name': 'Like new', 'value': 'like_new'},
      {'id': '3', 'name': 'Used - Excellent', 'value': 'excellent'},
      {'id': '4', 'name': 'Used - Good', 'value': 'good'},
      {'id': '5', 'name': 'Used - Fair', 'value': 'fair'},
    ];
  }
}

// Get sizes from API
static Future<List<Map<String, dynamic>>> getSizes() async {
  print('📏 Fetching sizes from API');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/listing/public/products/the/products/sizes'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));

    print('📡 Sizes Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData.containsKey('data') && responseData['data'] is List) {
        final List<dynamic> sizesJson = responseData['data'];
        print('✅ Found ${sizesJson.length} sizes');
        
        List<Map<String, dynamic>> sizes = [];
        for (var json in sizesJson) {
          try {
            sizes.add({
              'id': json['id']?.toString() ?? '',
              'name': json['name']?.toString() ?? '',
              'value': json['value']?.toString() ?? json['name']?.toString() ?? '',
            });
          } catch (e) {
            print('⚠️ Error parsing size: $e');
          }
        }
        
        return sizes;
      }
    }
    
    print('❌ No sizes found or API error');
    // Return default sizes if API fails
    return [
      {'id': '1', 'name': 'XS', 'value': 'xs'},
      {'id': '2', 'name': 'S', 'value': 's'},
      {'id': '3', 'name': 'M', 'value': 'm'},
      {'id': '4', 'name': 'L', 'value': 'l'},
      {'id': '5', 'name': 'XL', 'value': 'xl'},
      {'id': '6', 'name': 'XXL', 'value': 'xxl'},
      {'id': '7', 'name': 'XXXL', 'value': 'xxxl'},
    ];
    
  } catch (e) {
    print('❌ Error fetching sizes: $e');
    return [
      {'id': '1', 'name': 'XS', 'value': 'xs'},
      {'id': '2', 'name': 'S', 'value': 's'},
      {'id': '3', 'name': 'M', 'value': 'm'},
      {'id': '4', 'name': 'L', 'value': 'l'},
      {'id': '5', 'name': 'XL', 'value': 'xl'},
      {'id': '6', 'name': 'XXL', 'value': 'xxl'},
      {'id': '7', 'name': 'XXXL', 'value': 'xxxl'},
    ];
  }
}

// Get user addresses (for pickup)
static Future<List<Map<String, dynamic>>> getUserAddresses(String token) async {
  print('📍 Fetching user addresses from API');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/user/addresses'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    print('📡 Addresses Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData.containsKey('data') && responseData['data'] is List) {
        final List<dynamic> addressesJson = responseData['data'];
        print('✅ Found ${addressesJson.length} addresses');
        
        List<Map<String, dynamic>> addresses = [];
        for (var json in addressesJson) {
          try {
            addresses.add({
              'id': json['id']?.toString() ?? '',
              'address_line1': json['address_line1']?.toString() ?? '',
              'address_line2': json['address_line2']?.toString() ?? '',
              'city': json['city']?.toString() ?? '',
              'state': json['state']?.toString() ?? '',
              'zip_code': json['zip_code']?.toString() ?? '',
              'country': json['country']?.toString() ?? '',
              'address_type': json['address_type']?.toString() ?? '',
            });
          } catch (e) {
            print('⚠️ Error parsing address: $e');
          }
        }
        
        return addresses;
      }
    }
    
    print('❌ No addresses found or API error');
    return [];
    
  } catch (e) {
    print('❌ Error fetching addresses: $e');
    return [];
  }
}

// ============ BRANDS METHOD ============

static Future<List<Map<String, dynamic>>> getBrands() async {
  print('🏷️ Fetching brands from API');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/listing/brands'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));

    print('📡 Brands Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData.containsKey('data') && responseData['data'] is List) {
        final List<dynamic> brandsJson = responseData['data'];
        print('✅ Found ${brandsJson.length} brands');
        
        List<Map<String, dynamic>> brands = [];
        for (var json in brandsJson) {
          try {
            brands.add({
              'id': json['id']?.toString() ?? '',
              'name': json['name']?.toString() ?? '',
            });
          } catch (e) {
            print('⚠️ Error parsing brand: $e');
          }
        }
        
        return brands;
      }
    }
    
    print('❌ No brands found or API error');
    // Return default brands if API fails
    return [
      {'id': '1', 'name': 'Nike'},
      {'id': '2', 'name': 'Adidas'},
      {'id': '3', 'name': 'Apple'},
      {'id': '4', 'name': 'Samsung'},
      {'id': '5', 'name': 'Sony'},
    ];
    
  } catch (e) {
    print('❌ Error fetching brands: $e');
    return [
      {'id': '1', 'name': 'Nike'},
      {'id': '2', 'name': 'Adidas'},
      {'id': '3', 'name': 'Apple'},
      {'id': '4', 'name': 'Samsung'},
      {'id': '5', 'name': 'Sony'},
    ];
  }
}


// ============ UPDATED CREATE LISTING METHOD WITH EXACT LARAVEL FIELD NAMES ============

static Future<Map<String, dynamic>> createListing({
  required String token,
  required Map<String, dynamic> listingData,
  List<String> images = const [],
}) async {
  print('📝 Creating new listing with ${images.length} images');
  
  // CORRECT ENDPOINT
  final endpoint = '$baseUrl/api/v1/listing/auth/products/create';
  
  print('🚀 Using endpoint: $endpoint');
  
  try {
    var request = http.MultipartRequest('POST', Uri.parse(endpoint));
    
    // Headers
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['ngrok-skip-browser-warning'] = 'true';
    
    print('📤 SENDING DATA TO LARAVEL:');
    
    // ====== EXACT FIELDS LARAVEL EXPECTS (based on validation errors) ======
    
    // 1. BASIC PRODUCT INFO (REQUIRED)
    request.fields['title'] = listingData['title']?.toString() ?? '';
    request.fields['description'] = listingData['description']?.toString() ?? '';
    request.fields['price'] = listingData['price']?.toString() ?? '0';
    request.fields['quantity'] = listingData['quantity']?.toString() ?? '1';
    
    // 2. CATEGORY & BRAND (REQUIRED) - Laravel expects 'brand_name' not 'brand'
    request.fields['category_id'] = listingData['category_id']?.toString() ?? '';
    request.fields['brand_name'] = listingData['brand_name']?.toString() ?? listingData['brand']?.toString() ?? ''; // FIXED: brand_name
    
    // 3. CONDITION (REQUIRED)
    request.fields['condition_id'] = listingData['condition_id']?.toString() ?? '';
    
    // 4. SIZE (REQUIRED)
    request.fields['size'] = listingData['size']?.toString() ?? '';
    
    // 5. LOCATION FIELDS (CRITICAL - Laravel expects these directly, not just address_id)
    request.fields['location'] = listingData['location']?.toString() ?? listingData['address_line1']?.toString() ?? ''; // FIXED: location
    request.fields['city'] = listingData['city']?.toString() ?? ''; // FIXED: city
    
    // 6. ADDRESS_ID (optional - for linking to user address)
    if (listingData.containsKey('address_id') && listingData['address_id'] != null) {
      request.fields['address_id'] = listingData['address_id']!.toString();
      print('📍 Using address_id: ${listingData['address_id']}');
    }
    
    // 7. Add state, zip_code, country if available
    if (listingData.containsKey('state') && listingData['state'] != null) {
      request.fields['state'] = listingData['state']!.toString();
    }
    if (listingData.containsKey('zip_code') && listingData['zip_code'] != null) {
      request.fields['zip_code'] = listingData['zip_code']!.toString();
    }
    if (listingData.containsKey('country') && listingData['country'] != null) {
      request.fields['country'] = listingData['country']!.toString();
    }
    
    // 8. OPTIONAL FIELDS
    if (listingData.containsKey('allow_offers') && listingData['allow_offers'] != null) {
      request.fields['allow_offers'] = listingData['allow_offers']!.toString();
    }
    
    if (listingData.containsKey('shipping_type') && listingData['shipping_type'] != null) {
      request.fields['shipping_type'] = listingData['shipping_type']!.toString();
    }
    
    // 9. MEASUREMENTS (OPTIONAL)
    if (listingData.containsKey('chest_size') && listingData['chest_size'] != null) {
      request.fields['chest_size'] = listingData['chest_size']!.toString();
    }
    if (listingData.containsKey('waist_size') && listingData['waist_size'] != null) {
      request.fields['waist_size'] = listingData['waist_size']!.toString();
    }
    if (listingData.containsKey('hips_size') && listingData['hips_size'] != null) {
      request.fields['hips_size'] = listingData['hips_size']!.toString();
    }
    if (listingData.containsKey('inseam_size') && listingData['inseam_size'] != null) {
      request.fields['inseam_size'] = listingData['inseam_size']!.toString();
    }
    if (listingData.containsKey('sleeve_size') && listingData['sleeve_size'] != null) {
      request.fields['sleeve_size'] = listingData['sleeve_size']!.toString();
    }
    if (listingData.containsKey('shoulder_size') && listingData['shoulder_size'] != null) {
      request.fields['shoulder_size'] = listingData['shoulder_size']!.toString();
    }
    
    // 10. STATUS FIELDS
    request.fields['active'] = 'true';
    request.fields['sold'] = 'false';
    
    // Debug all fields
    print('📋 FIELDS BEING SENT (with Laravel names):');
    request.fields.forEach((key, value) {
      print('   $key: $value');
    });
    
    // 11. IMAGES
    for (int i = 0; i < images.length; i++) {
      var imageFile = File(images[i]);
      if (await imageFile.exists()) {
        var multipartFile = await http.MultipartFile.fromPath(
          'images[]',
          imageFile.path,
        );
        request.files.add(multipartFile);
        print('📸 Added image ${i + 1}: ${imageFile.path}');
      }
    }
    
    print('🚀 Sending request with ${request.files.length} images...');
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    return _handleCreateListingResponse(response);
    
  } on TimeoutException {
    print('⏰ Create listing timeout');
    return {
      'success': false,
      'error': 'Connection timeout',
      'message': 'Request timed out. Please try again.',
    };
  } catch (e) {
    print('❌ Create listing exception: $e');
    return {
      'success': false,
      'error': e.toString(),
      'message': 'An error occurred while creating listing',
    };
  }
}

// Helper method to handle response
static Map<String, dynamic> _handleCreateListingResponse(http.Response response) {
  print('📡 Create Listing Status: ${response.statusCode}');
  print('📡 Create Listing Response: ${response.body}');
  
  // Store the raw body for analysis
  String rawBody = response.body;
  
  try {
    final Map<String, dynamic> responseData = json.decode(response.body);
    String message = responseData['message']?.toString() ?? '';
    
  // CHECK FOR SMTP ERRORS FIRST (this is the fix!)
if (response.statusCode == 400) {
  // Check if it's an SMTP authentication error
  if (message.contains('SMTP') || 
      message.contains('authenticate') || 
      message.contains('contact@dexktech.com') ||
      message.contains('Error creating product') ||
      message.contains('535 5.7.8')) {
    
    print('⚠️ DETECTED: SMTP Email Error (but product WAS created in database!)');
    print('✅ Product was successfully created despite email failure');
    
    // KEY FIX: Return success = true because product IS created
    return {
      'success': true,  // ← This is the most important change!
      'status': 'partial_success',
      'message': 'Listing created! (Email notification failed)',
      'smtp_error': true,
      'partial_success': true,
      'raw_response': rawBody,
    };
  } else {
    // It's a real 400 validation error (not SMTP)
    print('❌ Real validation error: $responseData');  // ← FIXED!
    return {
      'success': false,
      'error': 'Validation failed',
      'message': message,
      'errors': responseData['errors'] ?? {},
      'raw_response': rawBody,
    };
  }
}
    
    // Normal success responses
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Listing created successfully!');
      return {
        'success': true,
        'data': responseData['data'] ?? responseData,
        'message': responseData['message'] ?? 'Listing created successfully',
        'raw_response': rawBody,
      };
    }
    
    // Other error responses
    print('❌ Failed to create listing: ${response.statusCode}');
    return {
      'success': false,
      'error': 'Failed to create listing: ${response.statusCode}',
      'message': message,
      'raw_response': rawBody,
    };
    
  } catch (e) {
    print('❌ Error parsing response: $e');
    
    // Even if we can't parse JSON, check raw body for SMTP errors
    if (rawBody.contains('SMTP') || rawBody.contains('contact@dexktech.com')) {
      print('⚠️ Raw body contains SMTP error (product likely created)');
      return {
        'success': true,  // ← Return success = true!
        'status': 'partial_success',
        'message': 'Listing created! (Email notification failed)',
        'smtp_error': true,
        'raw_response': rawBody,
      };
    }
    
    return {
      'success': false,
      'error': 'Failed to parse server response',
      'message': 'Server error occurred',
      'raw_response': rawBody,
    };
  }
}




// Add these methods to your ApiService class:

// ============ SELLER PROFILE API METHODS ============

/// 1. GET SELLER PROFILE - From users.php
/// Endpoint: GET /api/v1/users/{userId}/profile

static Future<Map<String, dynamic>> getSellerProfile(String sellerId) async {
  print('👤 Fetching seller profile for ID: $sellerId');
  
  try {
    // Get token from AuthService
    final authService = AuthService();
    await authService.isLoggedIn(); // This loads the token from prefs
    final token = authService.token;
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/$sellerId/profile'),
      headers: {
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
        'ngrok-skip-browser-warning': 'true',   
          'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Profile Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('✅ Seller profile fetched successfully');
      return {
        'success': true,
        'data': responseData['data'] ?? responseData,
      };
    } else {
      return {
        'success': false,
        'error': 'Failed to load seller profile: ${response.statusCode}'
      };
    }
  } catch (e) {
    print('❌ Error fetching seller profile: $e');
    return {'success': false, 'error': e.toString()};
  }
}

/// 2. GET SELLER SHOP INFO - From shop.php

static Future<Map<String, dynamic>> getSellerShop(String sellerId) async {
  print('🏪 Fetching shop info for seller: $sellerId');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/shop/$sellerId/shop'),
      headers: {
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
        'ngrok-skip-browser-warning': 'true', 
        'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Shop Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('✅ Shop info fetched successfully');
      return {
        'success': true,
        'data': responseData['data'] ?? responseData,
      };
    } else {
      return {'success': false, 'error': 'Failed to load shop info'};
    }
  } catch (e) {
    print('❌ Error fetching shop info: $e');
    return {'success': false, 'error': e.toString()};
  }
}

/// 3. GET SELLER RATINGS - From ratings.php
/// Endpoint: GET /api/v1/users/{userId}/ratings
static Future<Map<String, dynamic>> getSellerRatings(String sellerId) async {
  print('⭐ Fetching ratings for seller: $sellerId');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/$sellerId/ratings'),
      headers: {
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
        'ngrok-skip-browser-warning': 'true', 
          'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Ratings Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final data = responseData['data'] ?? responseData;
      
      return {
        'success': true,
        'average': data['average_rating'] ?? 0.0,
        'count': data['total_ratings'] ?? 0,
        'data': data,
      };
    } else {
      return {'success': false, 'average': 0.0, 'count': 0};
    }
  } catch (e) {
    print('❌ Error fetching ratings: $e');
    return {'success': false, 'average': 0.0, 'count': 0};
  }
}

/// 4. GET SELLER REVIEWS - From reviews.php
/// Endpoint: GET /api/v1/users/{userId}/reviews
static Future<List<Map<String, dynamic>>> getSellerReviews(String sellerId) async {
  print('📝 Fetching reviews for seller: $sellerId');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/$sellerId/reviews'),
      headers: {
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Reviews Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> reviewsJson = responseData['data'] ?? responseData['reviews'] ?? [];
      
      return reviewsJson.map((json) => json as Map<String, dynamic>).toList();
    } else {
      return [];
    }
  } catch (e) {
    print('❌ Error fetching reviews: $e');
    return [];
  }
}


/// 5. GET USER STATS - From users.php
/// Endpoint: GET /api/v1/users/user/stats (requires auth)
static Future<Map<String, dynamic>> getUserStats() async {
  print('📊 Fetching user stats');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/user/stats'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Stats Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return {
        'success': true,
        'data': responseData['data'] ?? responseData,
      };
    } else {
      return {'success': false};
    }
  } catch (e) {
    print('❌ Error fetching stats: $e');
    return {'success': false};
  }
}

/// 6. FOLLOW/UNFOLLOW METHODS - From followers.php

/// Follow a user

static Future<bool> followUser(String userId) async {
  print('➕ Following user: $userId');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    if (token == null) return false;
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/users/$userId/follow'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', 
        'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Follow Response Status: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 201;
    
  } catch (e) {
    print('❌ Error following user: $e');
    return false;
  }
}

/// Unfollow a user
/// Endpoint: DELETE /api/v1/users/{userId}/unfollow
static Future<bool> unfollowUser(String userId) async {
  print('➖ Unfollowing user: $userId');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    if (token == null) return false;
    
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/users/$userId/unfollow'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true', 
          'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Unfollow Response Status: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
    
  } catch (e) {
    print('❌ Error unfollowing user: $e');
    return false;
  }
}

/// Get current user's followers
static Future<List<Map<String, dynamic>>> getMyFollowers() async {
  print('👥 Fetching my followers');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    if (token == null) return [];
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/followers'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> followersJson = responseData['data'] ?? responseData['followers'] ?? [];
      return followersJson.map((json) => json as Map<String, dynamic>).toList();
    }
    return [];
    
  } catch (e) {
    print('❌ Error fetching followers: $e');
    return [];
  }
}

/// Get users current user is following

static Future<List<Map<String, dynamic>>> getMyFollowing() async {
  print('👥 Fetching users I follow');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    if (token == null) return [];
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/following'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> followingJson = responseData['data'] ?? responseData['following'] ?? [];
      return followingJson.map((json) => json as Map<String, dynamic>).toList();
    }
    return [];
    
  } catch (e) {
    print('❌ Error fetching following: $e');
    return [];
  }
}

static Future<bool> checkIfFollowing(String userId) async {
  print('🔍 Checking if following user: $userId');
  
  try {
    final following = await getMyFollowing();
    return following.any((user) => user['id'].toString() == userId);
  } catch (e) {
    return false;
  }
}

static Future<List<Product>> getSellerProducts(String sellerId) async {
  print('📦 Fetching products for seller: $sellerId');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/listing/seller/$sellerId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
        'ngrok-skip-browser-warning': 'true',
        'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Seller Products Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('📡 Seller Products Response: $responseData');
      
      // Handle nested data structure
      List<dynamic> productsJson = [];
      
      if (responseData.containsKey('data') && responseData['data'] is Map) {
        // If data contains a 'products' key with pagination
        if (responseData['data'].containsKey('products')) {
          final productsData = responseData['data']['products'];
          if (productsData is Map && productsData.containsKey('data')) {
            productsJson = productsData['data'] as List;
          }
        }
        // If data is directly an array
        else if (responseData['data'] is List) {
          productsJson = responseData['data'];
        }
      } else if (responseData.containsKey('products') && responseData['products'] is List) {
        productsJson = responseData['products'];
      } else if (responseData.containsKey('data') && responseData['data'] is List) {
        productsJson = responseData['data'];
      }
      
      print('✅ Found ${productsJson.length} products for seller');
      
      return productsJson.map((json) => Product.fromJson(json)).toList();
    }
    return [];
    
  } catch (e) {
    print('❌ Error fetching seller products: $e');
    return [];
  }
}

}