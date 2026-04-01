import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';

class ApiClient {
  static String get baseUrl => AppConfig.baseUrl;
  
  static Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
  
  // IMPORTANT: includeHost defaults to TRUE for emulator compatibility
  static Map<String, String> getHeaders({String? token, bool includeHost = true}) {
    final headers = Map<String, String>.from(_baseHeaders);
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // CRITICAL: Add Host header for local development
    if (includeHost && baseUrl.contains('10.0.2.2')) {
      headers['Host'] = 'depop-backend.test';
    }
    
    return headers;
  }
  
  static Map<String, String> getMultipartHeaders({String? token, bool includeHost = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // CRITICAL: Add Host header for local development
    if (includeHost && baseUrl.contains('10.0.2.2')) {
      headers['Host'] = 'depop-backend.test';
    }
    
    return headers;
  }
  
  // HTTP Methods
  static Future<http.Response> get(
    String endpoint, {
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = getHeaders(token: token);
    return http.get(url, headers: headers).timeout(timeout);
  }
  
  static Future<http.Response> post(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = getHeaders(token: token);
    return http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(timeout);
  }
  
  static Future<http.Response> put(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = getHeaders(token: token);
    return http.put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(timeout);
  }
  
  static Future<http.Response> delete(
    String endpoint, {
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = getHeaders(token: token);
    return http.delete(url, headers: headers).timeout(timeout);
  }
  
  static Future<http.Response> multipartPost(
    String endpoint, {
    String? token,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(getMultipartHeaders(token: token));
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);
    final streamedResponse = await request.send().timeout(timeout);
    return http.Response.fromStream(streamedResponse);
  }
  
  static Map<String, dynamic> parseResponse(http.Response response) {
    try {
      return json.decode(response.body);
    } catch (e) {
      return {'raw_response': response.body};
    }
  }
} 