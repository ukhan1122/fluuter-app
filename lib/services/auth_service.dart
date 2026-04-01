import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

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
      print('🔐 REAL Login attempt for: $login');
      
      final response = await ApiService.loginUser(
        login: login,
        password: password,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        _token = data['token'] ?? 
                data['access_token'] ?? 
                data['access'];
        
        if (_token != null) {
          print('✅ Token received: ${_token!.substring(0, 20)}...');
          
          await _saveTokenToPrefs(_token!);
          
          if (data['user'] != null) {
            _userData = data['user'];
            await _saveUserDataToPrefs(_userData!);
            print('✅ User data loaded: ${_userData!['username']}');
          }
          
          return {
            'success': true, 
            'token': _token, 
            'user': _userData,
            'message': 'Login successful'
          };
        }
      }
      
      final errorMsg = response['error'] ?? 'Login failed - no token received';
      print('❌ Login failed: $errorMsg');
      return {'success': false, 'error': errorMsg};
      
    } catch (e) {
      print('❌ Login exception: $e');
      return {'success': false, 'error': 'Connection error: $e'};
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
  
  // ✅ ADD THIS METHOD - Set New Password
  Future<Map<String, dynamic>> setNewPassword(String token, String newPassword, String confirmPassword) async {
    try {
      print('🔐 Setting new password');
      
      final response = await ApiService.setNewPassword(
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