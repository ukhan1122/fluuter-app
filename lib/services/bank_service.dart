// lib/services/bank_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';

class BankService {
  static String get baseUrl => AppConfig.baseUrl;

  static Map<String, String> _getHeaders(String? token) => AppConfig.getHeaders(token: token);

  /// 1. GET bank account details
  /// GET /api/v1/user/bank/details/show
  static Future<Map<String, dynamic>> getBankDetails() async {
    print('🏦 Fetching bank account details');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/user/bank/details/show'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      print('📡 Bank Details Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'No bank account found'};
      } else {
        return {'success': false, 'error': 'Failed to fetch bank details'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ Error fetching bank details: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 2. CREATE/UPDATE bank account details
  /// POST /api/v1/user/bank/details/create
  static Future<Map<String, dynamic>> createBankDetails({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    String? routingNumber,
    String? iban,
    String? swiftCode,
  }) async {
    print('🏦 Creating bank account for: $accountHolderName');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final Map<String, dynamic> requestData = {
        
      'account_title': accountHolderName,  // ✅ ADD THIS - matches backend field name
        'account_holder_name': accountHolderName,
        'bank_name': bankName,
        'account_number': accountNumber,
      };
      
      if (routingNumber != null && routingNumber.isNotEmpty) {
        requestData['routing_number'] = routingNumber;
      }
      if (iban != null && iban.isNotEmpty) {
        requestData['iban'] = iban;
      }
      if (swiftCode != null && swiftCode.isNotEmpty) {
        requestData['swift_code'] = swiftCode;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/user/bank/details/create'),
        headers: _getHeaders(token),
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 15));

      print('📡 Create Bank Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': 'Bank account saved successfully',
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to save bank account',
        };
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ Error creating bank details: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 3. GET bank transactions
  /// GET /api/v1/user/bank/transactions
  static Future<Map<String, dynamic>> getBankTransactions({int limit = 20}) async {
    print('🏦 Fetching bank transactions');
    
    try {
      final authService = AuthService();
      await authService.isLoggedIn();
      final token = authService.token;
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/user/bank/transactions?limit=$limit'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      print('📡 Transactions Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
        };
      } else {
        return {'success': false, 'error': 'Failed to fetch transactions'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Connection timeout'};
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}