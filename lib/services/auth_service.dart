import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../config.dart';  // ← ADD THIS LINE for AppConfig
import 'package:http/http.dart' as http;  // ← ADD THIS LINE
import 'dart:math' show min;  // Add this at the top with other imports

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  Map<String, dynamic>? _userData;

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;

Future<Map<String, dynamic>> login(String login, String password) async {
  try {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/v1/auth/login'),
      headers: AppConfig.getHeaders(),
     body: json.encode({
  'login': login,  // ✅ Correct - use 'login' field
  'password': password,
}),
    );
    
    print('🔐 Login response status: ${response.statusCode}');
    print('🔐 Login response body: ${response.body}');
    
    final data = json.decode(response.body);
    
    // Check for successful login (200 OK)
    if (response.statusCode == 200) {
      // Extract token from response
      String? token;
      if (data['token'] != null) {
        token = data['token'];
      } else if (data['access_token'] != null) {
        token = data['access_token'];
      } else if (data['data'] != null && data['data']['token'] != null) {
        token = data['data']['token'];
      }
      
      // Save token and user data
      if (token != null) {
        _token = token;
        await _saveTokenToPrefs(token);
        
        // Extract user data
        Map<String, dynamic> userData = {};
        if (data['user'] != null) {
          userData = data['user'];
        } else if (data['data'] != null && data['data']['user'] != null) {
          userData = data['data']['user'];
        }
        
        if (userData.isNotEmpty) {
          _userData = userData;
          await _saveUserDataToPrefs(userData);
        }
        
        print('✅ Login successful! Token saved: ${token.substring(0, min(20, token.length))}...');
        
        return {
          'success': true,
          'data': data,
          'token': token,
          'user': userData,
        };
      } else {
        print('⚠️ No token found in response');
        return {
          'success': true,  // Still success, but no token
          'data': data,
        };
      }
    } else {
      // Handle error responses
      String errorMessage = data['message'] ?? 'Login failed';
      if (data['errors'] != null) {
        final errors = data['errors'] as Map;
        if (errors['email'] != null) {
          errorMessage = errors['email'][0];
        } else if (errors['password'] != null) {
          errorMessage = errors['password'][0];
        }
      }
      
      print('❌ Login failed: $errorMessage');
      
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': errorMessage,
        'errors': data['errors'],
        'error': data['error'],
      };
    }
  } catch (e) {
    print('❌ Login error: $e');
    return {
      'success': false,
      'statusCode': 500,
      'error': e.toString(),
      'message': 'Network error. Please check your connection.',
    };
  }
}


  // ✅ ADD THIS METHOD - Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🔐 Forgot password request for: $email');
      
      final response = await ApiService.forgotPassword(email: email);
      
      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Password reset link sent to your email'
        };
      }
      
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to send reset link'
      };
    } catch (e) {
      print('❌ Forgot password error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  
  Future<Map<String, dynamic>> setNewPassword({
  required String email,
  required String token,
  required String newPassword,
  required String confirmPassword,
}) async {
  try {
    print('🔐 Setting new password for email: $email');
    
    final response = await ApiService.setNewPassword(
      email: email,
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    
    if (response['success'] == true) {
      return {
        'success': true,
        'message': 'Password updated successfully'
      };
    }
    
    return {
      'success': false,
      'error': response['error'] ?? 'Failed to update password'
    };
  } catch (e) {
    print('❌ Set new password error: $e');
    return {'success': false, 'error': 'Connection error: $e'};
  }
}
  
  // ✅ ADD THIS METHOD - Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String phone, String otp) async {
    try {
      print('🔐 Verifying OTP for: $phone');
      
      final response = await ApiService.verifyOTP(
        phone: phone,
        otp: otp,
      );
      
      if (response['success'] == true) {
        final data = response['data'];
        
        // Store token if returned
        if (data != null) {
          final token = data['token'] ?? data['access_token'];
          if (token != null) {
            _token = token;
            await _saveTokenToPrefs(token);
            
            if (data['user'] != null) {
              _userData = data['user'];
              await _saveUserDataToPrefs(_userData!);
            }
          }
        }
        
        // Clear pending phone
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_phone');
        
        return {
          'success': true,
          'data': data,
          'message': 'Phone verified successfully'
        };
      }
      
      return {
        'success': false,
        'error': response['error'] ?? 'Invalid OTP code'
      };
    } catch (e) {
      print('❌ Verify OTP error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<void> _saveTokenToPrefs(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('💾 Token saved to shared preferences');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  Future<void> _saveUserDataToPrefs(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
      print('💾 User data saved');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        _token = token;
        final userDataJson = prefs.getString('user_data');
        if (userDataJson != null) {
          _userData = jsonDecode(userDataJson);
        }
        print('✅ User is logged in with token');
        return true;
      }
      print('❌ No token found - user not logged in');
      return false;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        print('🚪 REAL Logout with token');
        await ApiService.logoutUser(_token!);
      }
    } catch (e) {
      print('⚠️ Logout API error: $e');
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('user_data');
        
        _token = null;
        _userData = null;
        
        print('✅ Logout completed - data cleared');
      } catch (e) {
        print('❌ Error clearing data: $e');
      }
    }
  }

  Future<Map<String, dynamic>> sendVerificationCode(String phone) async {
    try {
      print('📱 REAL Send verification code to: $phone');
      
      final response = await ApiService.sendVerificationCode(phone: phone);
      
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_phone', phone);
        
        return {
          'success': true, 
          'data': response['data'],
          'message': 'Verification code sent'
        };
      }
      
      return {
        'success': false, 
        'error': response['error'] ?? 'Failed to send code'
      };
    } catch (e) {
      print('❌ Send code error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}