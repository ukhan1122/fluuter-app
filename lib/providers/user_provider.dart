// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProvider with ChangeNotifier {
  String? _profilePicture;
  String? _userName;
  bool _isLoggedIn = false;
  String? _token;

  String? get profilePicture => _profilePicture;
  String? get userName => _userName;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userDataJson = prefs.getString('user_data');
    
    _isLoggedIn = _token != null && _token!.isNotEmpty;
    
    if (userDataJson != null) {
      try {
        final Map<String, dynamic> userData = json.decode(userDataJson);
        _profilePicture = userData['profile_picture']?.toString();
        final firstName = userData['first_name']?.toString() ?? '';
        final lastName = userData['last_name']?.toString() ?? '';
        _userName = '$firstName $lastName'.trim();
        if (_userName!.isEmpty) {
          _userName = userData['username']?.toString();
        }
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }
    
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
    _profilePicture = null;
    _userName = null;
    _isLoggedIn = false;
    _token = null;
    
    notifyListeners();
  }
}