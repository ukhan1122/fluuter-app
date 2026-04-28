import 'api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/auth/login',
        body: {'login': login, 'password': password, 'device_name': 'flutter_app'},
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        final userData = Map<String, dynamic>.from(data['data']['user'] ?? {});
        final token = data['data']['token'];
        
        print('🔐 Login successful, fetching user profile to get ID...');
        
        // Fetch full user profile to get the ID
        if (token != null && token.isNotEmpty) {
          try {
            // Use ApiClient.baseUrl directly
            final baseUrl = ApiClient.baseUrl;
            final url = Uri.parse('$baseUrl/api/v1/auth/user');
            
            print('📡 Fetching user profile from: $url');
            
            final profileResponse = await http.get(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true',
              },
            ).timeout(const Duration(seconds: 10));
            
            print('📡 Profile response status: ${profileResponse.statusCode}');
            
            if (profileResponse.statusCode == 200) {
              final profileData = json.decode(profileResponse.body);
              print('📦 Profile response structure: ${profileData.keys}');
              
              // Extract user from response - try different structures
              Map<String, dynamic> fullUserData = {};
              if (profileData['data'] != null && profileData['data']['user'] != null) {
                fullUserData = profileData['data']['user'];
              } else if (profileData['user'] != null) {
                fullUserData = profileData['user'];
              } else if (profileData['data'] != null) {
                fullUserData = profileData['data'];
              } else {
                fullUserData = profileData;
              }
              
              print('📦 Full user data keys: ${fullUserData.keys}');
              
              // Add the ID to user data
              if (fullUserData.containsKey('id')) {
                userData['id'] = fullUserData['id'];
                userData['user_id'] = fullUserData['id'];
                print('✅ Retrieved user ID from profile: ${fullUserData['id']}');
              } else {
                print('⚠️ Profile response does not contain id field');
                print('📦 Available keys: ${fullUserData.keys}');
                // Also print the entire profile data for debugging
                print('📦 Full profile data: $profileData');
              }
            } else {
              print('⚠️ Could not fetch user profile: ${profileResponse.statusCode}');
              print('📡 Response body: ${profileResponse.body}');
            }
          } catch (e) {
            print('⚠️ Error fetching user profile: $e');
          }
        }
        
        print('📦 Final user data being saved: $userData');
        print('📦 User data keys: ${userData.keys}');
        
        return {
          'success': true, 
          'data': {
            'user': userData,
            'token': token,
          }
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Invalid login or password'};
      } else if (response.statusCode == 422) {
        final errors = ApiClient.parseResponse(response)['errors'] ?? {};
        return {'success': false, 'error': 'Validation failed', 'errors': errors};
      }
      return {'success': false, 'error': 'Login failed: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> sendVerificationCode({required String phone}) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/auth/verify',
        body: {'phone': phone},
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': ApiClient.parseResponse(response)};
      }
      return {'success': false, 'error': 'Failed to send code'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/auth/verify-otp',
        body: {'phone': phone, 'otp': otp},
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': ApiClient.parseResponse(response)};
      }
      return {'success': false, 'error': 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    print('🔴 AUTH_API - Forgot password called with email: $email');
    try {
      final response = await ApiClient.post(
        '/api/v1/auth/forgot-password',
        body: {'email': email},
      );
      
      print('🔴 AUTH_API - Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': ApiClient.parseResponse(response)};
      }
      return {'success': false, 'error': 'Failed to send reset link'};
    } catch (e) {
      print('🔴 AUTH_API - Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> setNewPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/auth/set-new-password',
        body: {
          'email': email,
          'token': token,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': ApiClient.parseResponse(response)};
      }
      return {'success': false, 'error': 'Failed to set password'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await ApiClient.post('/api/v1/auth/logout', token: token);
      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await ApiClient.get('/api/v1/auth/user', token: token);
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to fetch profile'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}