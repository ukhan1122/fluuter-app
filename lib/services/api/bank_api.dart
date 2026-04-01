import 'api_client.dart';

class BankApi {
  // Get bank account details
  static Future<Map<String, dynamic>> getBankDetails(String token) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/user/bank/details/show',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'No bank account found'};
      } else {
        return {'success': false, 'error': 'Failed to fetch bank details'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Create/Update bank account details
  static Future<Map<String, dynamic>> createBankDetails({
    required String token,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    String? routingNumber,
    String? iban,
    String? swiftCode,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'account_title': accountHolderName,
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
      
      final response = await ApiClient.post(
        '/api/v1/user/bank/details/create',
        token: token,
        body: requestData,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': 'Bank account saved successfully',
        };
      } else {
        final errorData = ApiClient.parseResponse(response);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to save bank account',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get bank transactions
  static Future<Map<String, dynamic>> getBankTransactions({
    required String token,
    int limit = 20,
  }) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/user/bank/transactions?limit=$limit',
        token: token,
        timeout: const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = ApiClient.parseResponse(response);
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else {
        return {'success': false, 'error': 'Failed to fetch transactions'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}