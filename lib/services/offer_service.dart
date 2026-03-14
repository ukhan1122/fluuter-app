// lib/services/offer_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/offer.dart';
import '../models/product.dart';
import 'auth_service.dart';
import '../config.dart';  // Add this import

class OfferService {
 static String get baseUrl => AppConfig.baseUrl;

static Map<String, String> _getHeaders(String? token) => AppConfig.getHeaders(token: token);

  // ============ OFFER ENDPOINTS ============

 /// 1. GET received offers (for products you're selling)
/// GET /api/v1/listing/products/offers/received
static Future<List<Offer>> getReceivedOffers() async {
  print('📦 Fetching received offers');
  
  try {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.token;
    
    if (token == null) {
      print('❌ No auth token found');
      return [];
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/listing/products/offers/received'),
      headers: _getHeaders(token),
    ).timeout(const Duration(seconds: 15));

    print('📡 Received Offers Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Navigate through the nested structure
      List<dynamic> offersJson = [];
      
      if (responseData.containsKey('data') && responseData['data'] is Map) {
        final dataMap = responseData['data'] as Map;
        if (dataMap.containsKey('original') && dataMap['original'] is List) {
          offersJson = dataMap['original'] as List;
        }
      }
      
      print('✅ Found ${offersJson.length} received offers');
      return offersJson.map((json) => Offer.fromJson(json)).toList();
    }
    
    return [];
  } on TimeoutException {
    print('⏰ Timeout fetching received offers');
    return [];
  } catch (e) {
    print('❌ Error fetching received offers: $e');
    return [];
  }
}

  /// 2. GET offer conversations
  /// GET /api/v1/listing/products/offers/conversations
  static Future<List<Offer>> getOfferConversations() async {
    print('💬 Fetching offer conversations');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/listing/products/offers/conversations'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> offersJson = responseData['data'] ?? [];
        return offersJson.map((json) => Offer.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error fetching conversations: $e');
      return [];
    }
  }

  /// 3. POST update offer price
  /// POST /api/v1/listing/products/offers/update/{offerId}
  static Future<Map<String, dynamic>> updateOfferPrice({
    required int offerId,
    required double newPrice,
    required int productId,
    String? message,
  }) async {
    print('💰 Updating offer $offerId price to $newPrice');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final Map<String, dynamic> requestData = {
        'offer_price': newPrice,  // Backend expects 'offer_price'
        'product_id': productId,
      };
      
      if (message != null) {
        requestData['message'] = message;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/listing/products/offers/update/$offerId'),
        headers: _getHeaders(token),
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 15));

      print('📡 Update Offer Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Offer updated successfully',
        };
      } else {
        return {'success': false, 'error': 'Failed to update offer: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Error updating offer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 4. POST accept offer
  /// POST /api/v1/listing/products/offers/{offerId}/accept
  static Future<Map<String, dynamic>> acceptOffer(int offerId) async {
    print('✅ Accepting offer $offerId');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/listing/products/offers/$offerId/accept'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': 'Offer accepted successfully',
        };
      } else {
        return {'success': false, 'error': 'Failed to accept offer'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 5. POST reject offer
  /// POST /api/v1/listing/products/offers/{offerId}/reject
  static Future<Map<String, dynamic>> rejectOffer(int offerId) async {
    print('❌ Rejecting offer $offerId');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/listing/products/offers/$offerId/reject'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Offer rejected successfully'};
      } else {
        return {'success': false, 'error': 'Failed to reject offer'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 6. POST counter offer
  /// POST /api/v1/listing/products/offers/{offerId}/counter-offer
  static Future<Map<String, dynamic>> counterOffer({
    required int offerId,
    required double price,
    String? message,
  }) async {
    print('🔄 Countering offer $offerId with price $price');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final Map<String, dynamic> requestData = {
        'price': price,  // Backend expects 'price' for counter offer
      };
      
      if (message != null) {
        requestData['message'] = message;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/listing/products/offers/$offerId/counter-offer'),
        headers: _getHeaders(token),
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 15));

      print('📡 Counter Offer Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': 'Counter offer sent successfully',
        };
      } else {
        return {'success': false, 'error': 'Failed to send counter offer'};
      }
    } catch (e) {
      print('❌ Error sending counter offer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 7. GET sent offers (offers you've made)
  /// GET /api/v1/listing/products/offers/sent
  static Future<List<Offer>> getSentOffers() async {
    print('📤 Fetching sent offers');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/listing/products/offers/sent'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> offersJson = responseData['data'] ?? [];
        return offersJson.map((json) => Offer.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error fetching sent offers: $e');
      return [];
    }
  }

  /// 8. POST create offer
  /// POST /api/v1/listing/products/offers/create
  static Future<Map<String, dynamic>> createOffer({
    required int productId,
    required double offerPrice,
    String? message,
  }) async {
    print('🆕 Creating offer for product $productId');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final Map<String, dynamic> requestData = {
        'product_id': productId,
        'offer_price': offerPrice,
      };
      
      if (message != null) {
        requestData['message'] = message;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/listing/products/offers/create'),
        headers: _getHeaders(token),
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': 'Offer created successfully',
        };
      } else {
        return {'success': false, 'error': 'Failed to create offer'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}