import 'api_client.dart';

class UserApi {
  static Future<Map<String, dynamic>> getSellerProfile(String sellerId) async {
    try {
      final response = await ApiClient.get('/api/v1/users/$sellerId/profile');
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false, 'error': 'Failed to load profile'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getSellerRatings(String sellerId) async {
    try {
      final response = await ApiClient.get('/api/v1/users/$sellerId/ratings');
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'average': data['data']?['average_rating'] ?? 0.0,
          'count': data['data']?['total_ratings'] ?? 0,
        };
      }
      return {'success': false, 'average': 0.0, 'count': 0};
    } catch (e) {
      return {'success': false, 'average': 0.0, 'count': 0};
    }
  }
  
  static Future<List<Map<String, dynamic>>> getSellerReviews(String sellerId) async {
    try {
      final response = await ApiClient.get('/api/v1/users/$sellerId/reviews');
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        final reviews = data['data'] ?? data['reviews'] ?? [];
        return List<Map<String, dynamic>>.from(reviews);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<bool> followUser(String userId, String token) async {
    try {
      final response = await ApiClient.post('/api/v1/users/$userId/follow', token: token);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> unfollowUser(String userId, String token) async {
    try {
      final response = await ApiClient.delete('/api/v1/users/$userId/unfollow', token: token);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getMyFollowers(String token) async {
    try {
      final response = await ApiClient.get('/api/v1/users/followers', token: token);
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        final followers = data['data'] ?? data['followers'] ?? [];
        return List<Map<String, dynamic>>.from(followers);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getMyFollowing(String token) async {
    try {
      final response = await ApiClient.get('/api/v1/users/following', token: token);
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        final following = data['data'] ?? data['following'] ?? [];
        return List<Map<String, dynamic>>.from(following);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getUserAddresses(String token) async {
    try {
      final response = await ApiClient.get('/api/v1/user/addresses', token: token);
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        final addresses = data['data'] ?? [];
        return List<Map<String, dynamic>>.from(addresses);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getUserStats(String token) async {
    try {
      final response = await ApiClient.get('/api/v1/users/user/stats', token: token);
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }
}