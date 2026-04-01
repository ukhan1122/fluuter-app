import 'api_client.dart';
import '../../models/offer.dart';

class OfferApi {
  // Get received offers (offers made on your products)
  static Future<List<Offer>> getReceivedOffers(String token) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/listing/products/offers/received',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        List<dynamic> offersJson = [];
        
        // Handle nested response structure
        if (data.containsKey('data') && data['data'] is Map) {
          final dataMap = data['data'] as Map;
          if (dataMap.containsKey('original') && dataMap['original'] is List) {
            offersJson = dataMap['original'] as List;
          }
        } else if (data.containsKey('data') && data['data'] is List) {
          offersJson = data['data'] as List;
        }
        
        return offersJson.map((json) => Offer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching received offers: $e');
      return [];
    }
  }
  
  // Get sent offers (offers you've made)
  static Future<List<Offer>> getSentOffers(String token) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/listing/products/offers/sent',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        List<dynamic> offersJson = data['data'] ?? [];
        return offersJson.map((json) => Offer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching sent offers: $e');
      return [];
    }
  }
  
  // Get conversation for a specific product
  static Future<List<Offer>> getConversation({
    required String token,
    required int productId,
    required int buyerId,
    required int sellerId,
  }) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/listing/products/offers/conversations?product_id=$productId&buyer_id=$buyerId&seller_id=$sellerId',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        List<dynamic> offersJson = [];
        
        if (data.containsKey('data')) {
          if (data['data'] is List) {
            offersJson = data['data'] as List;
          } else if (data['data'] is Map) {
            final dataMap = data['data'] as Map;
            if (dataMap.containsKey('offers') && dataMap['offers'] is List) {
              offersJson = dataMap['offers'] as List;
            } else if (dataMap.containsKey('conversation') && dataMap['conversation'] is List) {
              offersJson = dataMap['conversation'] as List;
            }
          }
        }
        
        return offersJson.map((json) => Offer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching conversation: $e');
      return [];
    }
  }
  
  // Create a new offer
  static Future<Map<String, dynamic>> createOffer({
    required String token,
    required int productId,
    required double offerPrice,
    String? message,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/listing/products/offers/create',
        token: token,
        body: {
          'product_id': productId,
          'offer_price': offerPrice,
          if (message != null) 'message': message,
        },
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': 'Offer created successfully',
        };
      }
      return {
        'success': false,
        'error': 'Failed to create offer: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Update offer price (counter offer)
  static Future<Map<String, dynamic>> updateOfferPrice({
    required String token,
    required int offerId,
    required double newPrice,
    required int productId,
    String? message,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/listing/products/offers/update/$offerId',
        token: token,
        body: {
          'offer_price': newPrice,
          'product_id': productId,
          if (message != null) 'message': message,
        },
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': 'Offer updated successfully',
        };
      }
      return {'success': false, 'error': 'Failed to update offer'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Accept an offer
  static Future<Map<String, dynamic>> acceptOffer({
    required String token,
    required int offerId,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/listing/products/offers/$offerId/accept',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': 'Offer accepted successfully',
        };
      }
      return {'success': false, 'error': 'Failed to accept offer'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Reject an offer
  static Future<Map<String, dynamic>> rejectOffer({
    required String token,
    required int offerId,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/listing/products/offers/$offerId/reject',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Offer rejected successfully'};
      }
      return {'success': false, 'error': 'Failed to reject offer'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Send a counter offer
  static Future<Map<String, dynamic>> counterOffer({
    required String token,
    required int offerId,
    required double price,
    String? message,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/listing/products/offers/$offerId/counter-offer',
        token: token,
        body: {
          'price': price,
          if (message != null) 'message': message,
        },
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': 'Counter offer sent successfully',
        };
      }
      return {'success': false, 'error': 'Failed to send counter offer'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}