// lib/config.dart

import 'dart:io' show Platform;

class AppConfig {
  // FOR LOCAL DEVELOPMENT
  static const bool forceLocal = true;
  
  // Emulator URL
  static const String emulatorUrl = 'http://10.0.2.2';
  
  // Real phone - use your ngrok URL
  static const String ngrokUrl = 'https://untimid-nonobjectivistic-wade.ngrok-free.dev';
  
  // Production URL
  static const String productionUrl = 'https://larvel-production.up.railway.app';
  
  // Custom domain for iOS simulator/desktop
  static const String customDomain = 'http://depop-backend.test';

  /// Get the base URL based on platform and environment
  static String get baseUrl {
    if (forceLocal) {
      if (Platform.isAndroid) {
        const bool isEmulator = true; // Set to false for real phone
        
        if (isEmulator) {
          print('📱 Using emulator URL: $emulatorUrl');
          return emulatorUrl;
        } else {
          print('📱 Using ngrok URL for phone: $ngrokUrl');
          return ngrokUrl;
        }
      } else if (Platform.isIOS) {
        // iOS simulator can use custom domain
        print('📱 Using custom domain for iOS: $customDomain');
        return customDomain;
      } else {
        // Desktop (Windows/Mac/Linux)
        print('💻 Using custom domain for desktop: $customDomain');
        return customDomain;
      }
    } else {
      print('🌍 Using production URL: $productionUrl');
      return productionUrl;
    }
  }

  /// Get headers with optional token and Host header
  static Map<String, String> getHeaders({String? token, bool includeHost = true}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    
    // Add Host header for local development when not using ngrok
    if (includeHost && !baseUrl.contains('ngrok') && baseUrl.contains('10.0.2.2')) {
      headers['Host'] = 'depop-backend.test';
      print('📝 Using Host header for local connection');
    }
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  /// For multipart requests (file uploads)
  static Map<String, String> getMultipartHeaders({String? token, bool includeHost = true}) {
    final headers = {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    
    // Add Host header for local development when not using ngrok
    if (includeHost && !baseUrl.contains('ngrok') && baseUrl.contains('10.0.2.2')) {
      headers['Host'] = 'depop-backend.test';
    }
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  /// Check if we're in debug mode
  static bool get isDebugMode {
    bool inDebug = false;
    assert(inDebug = true);
    return inDebug;
  }
}