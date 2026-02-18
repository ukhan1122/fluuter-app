// lib/services/search_service.dart

import '../models/product.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  static List<Product> _allProducts = [];
  static String _currentSearchQuery = '';
  static bool _isSearching = false;

  static void initialize(List<Product> products) {
    _allProducts = products;
    print('🔍 Search Service initialized with ${products.length} products');
    if (products.isNotEmpty) {
      print('🔍 Sample product: ${products.first.title}');
    }
  }

  static List<Product> search(String query) {
    _currentSearchQuery = query.toLowerCase().trim();
    print('🔍 Searching for: "$_currentSearchQuery"');
    print('🔍 Total products in search index: ${_allProducts.length}');
    
    if (_currentSearchQuery.isEmpty) {
      print('🔍 Empty query, returning empty list');
      return [];
    }
    
    final results = _allProducts.where((product) {
      final title = product.title.toLowerCase();
      final brand = product.brandName?.toLowerCase() ?? '';
      final description = product.description.toLowerCase();
      final category = product.categoryName?.toLowerCase() ?? '';
      
      final matches = title.contains(_currentSearchQuery) ||
             brand.contains(_currentSearchQuery) ||
             description.contains(_currentSearchQuery) ||
             category.contains(_currentSearchQuery);
             
      if (matches) {
        print('🔍 MATCH: ${product.title}');
      }
      
      return matches;
    }).toList();
    
    print('🔍 Found ${results.length} results for "$_currentSearchQuery"');
    return results;
  }

  static void clearSearch() {
    _currentSearchQuery = '';
    _isSearching = false;
  }

  static bool get isSearching => _isSearching;
  static set isSearching(bool value) => _isSearching = value;
  
  static String get currentQuery => _currentSearchQuery;
}