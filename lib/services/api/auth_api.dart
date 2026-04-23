import 'api_client.dart';

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
        return {'success': true, 'data': data['data'] ?? {}};
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
      
    print('🔴 AUTH_API - Response status: ${response.statusCode}');  // ← ALSO ADD THIS
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': ApiClient.parseResponse(response)};
      }
      return {'success': false, 'error': 'Failed to send reset link'};
    } catch (e) {
      
    print('🔴 AUTH_API - Error: $e');  // ← AND THIS
      return {'success': false, 'error': e.toString()};
    }
  }
  
 
 static 
 Future<Map<String, dynamic>> setNewPassword({
  required String email,      // ← ADD THIS PARAMETER
  required String token,
  required String newPassword,
  required String confirmPassword,
}) async {
  try {
    final response = await ApiClient.post(
      '/api/v1/auth/set-new-password',
      body: {
        'email': email,        // ← ADD THIS FIELD
        'token': token,
        'password': newPassword,              // ← CHANGE from 'new_password'
        'password_confirmation': confirmPassword,  // ← CHANGE from 'confirm_password'
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
        return {'success': true, 'data': ApiClient.parseResponse(response)};
      }
      return {'success': false, 'error': 'Failed to fetch profile'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}