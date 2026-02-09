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
        login: login,      // Changed from email to login
        password: password,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Extract token from response
        _token = data['token'] ?? 
                data['access_token'] ?? 
                data['access'];
        
        if (_token != null) {
          print('✅ Token received: ${_token!.substring(0, 20)}...');
          
          // Save token
          await _saveTokenToPrefs(_token!);
          
          // Extract user data from response
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
      
      // If we reach here, login failed
      final errorMsg = response['error'] ?? 'Login failed - no token received';
      print('❌ Login failed: $errorMsg');
      return {'success': false, 'error': errorMsg};
      
    } catch (e) {
      print('❌ Login exception: $e');
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
        // Save phone for OTP verification
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