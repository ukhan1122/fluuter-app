import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../services/auth_service.dart';

class OrderService {
  static const String baseUrl = 'http://10.0.2.2:80';

  static Map<String, String> get _headers {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'Host': 'depop-backend.test',
    };
  }

  static String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    final random = (1000 + (now.microsecond % 9000)).toString();
    return 'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$timestamp$random';
  }

  // Add item to cart
  static Future<bool> addToCart({
    required String token,
    required int productId,
    required int quantity,
  }) async {
    print('🛒 Adding to cart: Product $productId, Qty: $quantity');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/user/cart/items'), // This endpoint works!
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Host': 'depop-backend.test',
        },
        body: json.encode({
          'product_id': productId,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Added to cart');
        return true;
      } else {
        print('❌ Failed to add to cart: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error adding to cart: $e');
      return false;
    }
  }

// Get user's addresses and filter by current user
static Future<int?> getUserAddressId(String token) async {
  print('📍 Fetching user addresses');
  
  try {
    // First, get current user info to know the user ID
    final userResponse = await http.get(
      Uri.parse('$baseUrl/api/v1/auth/user'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
        'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 10));
    
    if (userResponse.statusCode != 200) {
      print('❌ Failed to get user info');
      return null;
    }
    
    final userData = json.decode(userResponse.body);
    final currentUserId = userData['data']?['id']?.toString() ?? 
                         userData['id']?.toString();
    
    print('👤 Current user ID: $currentUserId');
    
    // Now get addresses
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/user/address'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
        'Host': 'depop-backend.test',
      },
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Try different response formats
      List<dynamic> addresses = [];
      
      if (responseData.containsKey('data') && responseData['data'] is List) {
        addresses = responseData['data'] as List;
      } else if (responseData.containsKey('addresses') && responseData['addresses'] is List) {
        addresses = responseData['addresses'] as List;
      }
      
      // Filter addresses that belong to current user
      for (var address in addresses) {
        final addrUserId = address['user_id']?.toString();
        if (addrUserId == currentUserId) {
          print('✅ Found address ID ${address['id']} for current user');
          return address['id'];
        }
      }
      
      print('❌ No addresses found for current user');
    } else {
      print('❌ Address API returned: ${response.statusCode}');
    }
    return null;
  } catch (e) {
    print('❌ Error fetching addresses: $e');
    return null;
  }
}

  // Create a new address
  static Future<int?> createAddress({
    required String token,
    required String address,
    required String city,
    required String phone,
  }) async {
    print('📍 Creating new address');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/user/address'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Host': 'depop-backend.test',
        },
        body: json.encode({
          'address_line_1': address,
          'city': city,
          'phone': phone,
          'address_type': 'shipping',
          'is_default': true,
          'state_province_or_region': city,
          'country': 'Pakistan',
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Create Address Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Extract the address ID
        if (responseData.containsKey('data') && responseData['data'] != null) {
          return responseData['data']['id'];
        } else if (responseData.containsKey('id')) {
          return responseData['id'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Error creating address: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String phone,
    required String email,
    required String address,
    required String city,
    required double subtotal,
    required double deliveryCharge,
    required double total,
    required String paymentMethod,
    required String deliveryOption,
    required List<Map<String, dynamic>> items,
  }) async {
    print('📦 Creating new order via checkout...');

    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'Not authenticated',
          'message': 'Please login to place order',
        };
      }

      final orderNumber = _generateOrderNumber();

      // Get seller_id from first item
      int sellerId = 0;
      if (items.isNotEmpty) {
        sellerId = items.first['seller_id'] ?? 0;
        print('👤 Using seller_id: $sellerId');
      }

      // Add all items to cart
      for (var item in items) {
        final added = await addToCart(
          token: token,
          productId: item['product_id'],
          quantity: item['quantity'],
        );
        if (!added) {
          print('⚠️ Failed to add item to cart');
        }
      }

      // Get or create address
      int? addressId = await getUserAddressId(token);
      
      if (addressId == null) {
        print('📍 No address found, creating one...');
        addressId = await createAddress(
          token: token,
          address: address,
          city: city,
          phone: phone,
        );
      }

      if (addressId == null) {
        return {
          'success': false,
          'error': 'Address required',
          'message': 'Please add a delivery address in your profile',
        };
      }

      print('📍 Using address ID: $addressId');

      // Prepare checkout data
      final orderData = {
        'order_number': orderNumber,
        'customer_name': customerName,
        'phone': phone,
        'email': email,
        'shipping_address': address,
        'city': city,
        'subtotal': subtotal,
        'delivery_charge': deliveryCharge,
        'total': total,
        'payment_method': paymentMethod,
        'delivery_option': deliveryOption,
        'status': 'pending',
        'seller_id': sellerId,
        'delivery_address_id': addressId, // REAL address ID
        'cart_items': items.map((item) => {
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        }).toList(),
      };

      print('📤 Sending order data: ${json.encode(orderData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/cart/checkout/create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Host': 'depop-backend.test',
        },
        body: json.encode(orderData),
      ).timeout(const Duration(seconds: 15));

      print('📡 Checkout Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Order created successfully!');
        
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'order_number': orderNumber,
          'message': 'Order placed successfully',
        };
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('❌ Validation error: ${responseData['message']}');
        return {
          'success': false,
          'error': 'Validation failed',
          'message': responseData['message'] ?? 'Please check your order details',
          'errors': responseData['errors'] ?? {},
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': 'Failed to place order',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Connection timeout',
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      print('❌ Order creation exception: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'An error occurred while placing order',
      };
    }
  }
}