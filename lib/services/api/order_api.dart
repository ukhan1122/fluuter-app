import 'api_client.dart';

class OrderApi {
  // Add item to cart
  static Future<bool> addToCart({
    required String token,
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/user/cart/items',
        token: token,
        body: {
          'product_id': productId,
          'quantity': quantity,
        },
        timeout: const Duration(seconds: 10),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error adding to cart: $e');
      return false;
    }
  }
  
  // Get user addresses
  static Future<List<Map<String, dynamic>>> getUserAddresses(String token) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/user/address',
        token: token,
        timeout: const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        List<dynamic> addresses = [];
        
        if (data.containsKey('data') && data['data'] is List) {
          addresses = data['data'] as List;
        } else if (data.containsKey('addresses') && data['addresses'] is List) {
          addresses = data['addresses'] as List;
        }
        
        return addresses.map((a) => a as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching addresses: $e');
      return [];
    }
  }
  
  // Create a new address
  static Future<Map<String, dynamic>> createAddress({
    required String token,
    required String address,
    required String city,
    required String phone,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/user/address',
        token: token,
        body: {
          'address_line_1': address,
          'city': city,
          'phone': phone,
          'address_type': 'shipping',
          'is_default': true,
          'state_province_or_region': city,
          'country': 'Pakistan',
        },
        timeout: const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiClient.parseResponse(response);
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false, 'error': 'Failed to create address'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Create order from checkout
  static Future<Map<String, dynamic>> createOrder({
    required String token,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/cart/checkout/create',
        token: token,
        body: orderData,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': 'Order placed successfully',
        };
      } else if (response.statusCode == 422) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': false,
          'error': 'Validation failed',
          'message': data['message'] ?? 'Please check your order details',
          'errors': data['errors'] ?? {},
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': 'Failed to place order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'An error occurred while placing order',
      };
    }
  }
  
  // Get current user ID (for address filtering)
  static Future<int?> getCurrentUserId(String token) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/auth/user',
        token: token,
        timeout: const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        final userId = data['data']?['id'] ?? data['id'];
        return userId is int ? userId : int.tryParse(userId.toString());
      }
      return null;
    } catch (e) {
      print('❌ Error getting user ID: $e');
      return null;
    }
  }
}