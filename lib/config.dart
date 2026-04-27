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

  
  static String get baseUrl {
    if (forceLocal) {
      if (Platform.isAndroid) {
        const bool isEmulator = true; 
        
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

  /// Check if we need to add the Host header (only for local development)
  static bool get needsHostHeader {
    // Only add Host header for local development
    return !forceLocal || 
           (baseUrl.contains('10.0.2.2') || 
            baseUrl.contains('localhost') || 
            baseUrl.contains('depop-backend.test'));
  }

  /// Get headers with optional token - WORKS FOR ALL ENVIRONMENTS
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    
    // ✅ Automatically add Host header only when needed
    if (needsHostHeader && !baseUrl.contains('railway.app') && !baseUrl.contains('ngrok')) {
      headers['Host'] = 'depop-backend.test';
      print('📝 Adding Host header for local development');
    }
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  /// For multipart requests (file uploads) - WORKS FOR ALL ENVIRONMENTS
  static Map<String, String> getMultipartHeaders({String? token}) {
    final headers = {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    
    // ✅ Automatically add Host header only when needed
    if (needsHostHeader && !baseUrl.contains('railway.app') && !baseUrl.contains('ngrok')) {
      headers['Host'] = 'depop-backend.test';
      print('📝 Adding Host header for local development (multipart)');
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