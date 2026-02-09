import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== Testing Laravel API Connection ===\n');
  
  final tests = [
    {
      'name': 'Direct domain (like PowerShell)',
      'url': 'http://depop-backend.test/api/v1/listing/public/products/show',
      'headers': <String, String>{},
    },
    {
      'name': 'Localhost',
      'url': 'http://localhost/api/v1/listing/public/products/show',
      'headers': <String, String>{'Host': 'depop-backend.test'},
    },
    {
      'name': '10.0.2.2 (Android emulator IP)',
      'url': 'http://10.0.2.2/api/v1/listing/public/products/show',
      'headers': <String, String>{'Host': 'depop-backend.test'},
    },
    {
      'name': '127.0.0.1',
      'url': 'http://127.0.0.1/api/v1/listing/public/products/show',
      'headers': <String, String>{'Host': 'depop-backend.test'},
    },
    {
      'name': '10.0.2.2:8000 (artisan serve)',
      'url': 'http://10.0.2.2:8000/api/v1/listing/public/products/show',
      'headers': <String, String>{},
    },
  ];

  bool foundWorking = false;
  
  for (var test in tests) {
    final url = test['url'] as String;
    final headers = test['headers'] as Map<String, String>;
    
    print('Testing: ${test['name']}');
    print('   URL: $url');
    
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      
      request.headers.add('Accept', 'application/json');
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      print('   Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(body);
        final dataList = jsonData['data'] as List;
        print('   SUCCESS!');
        print('   Products found: ${dataList.length}');
        
        if (dataList.isNotEmpty) {
          final firstProduct = dataList[0] as Map<String, dynamic>;
          print('   First product: ${firstProduct['title']}');
        }
        
        foundWorking = true;
        
        final baseUrl = url.replaceAll('/api/v1/listing/public/products/show', '');
        print('\nUSE THIS IN ApiService:');
        print('static const String baseUrl = "$baseUrl";');
        
        if (headers.containsKey('Host')) {
          print('// Add this Host header: ${headers['Host']}');
        }
        break;
      }
    } catch (e) {
      print('   Error: $e');
    }
    print('');
  }

  if (!foundWorking) {
    print('No connection worked. Try: php artisan serve --host=0.0.0.0 --port=8000');
  }
}