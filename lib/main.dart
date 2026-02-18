import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/home_screen.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart'; // IMPORT CartProvider
import 'services/api_service.dart';
import 'screens/profile_screen.dart';
import 'screens/seller_profile_screen.dart';
import 'providers/follow_provider.dart';  // ✅ MAKE SURE THIS IMPORT EXISTS
import 'services/search_service.dart'; // ✅ ADD THIS IMPORT
import 'providers/favorites_provider.dart'; // Add this import

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
    _initializeSearch();
  // Just run the app immediately
  runApp(const MyApp());
}
Future<void> _initializeSearch() async {
  print('🔍 Initializing search service from main...');
  try {
    final products = await ProductCache.getProducts(limit: 50);
    print('📦 Loaded ${products.length} products for search');
    
    if (products.isNotEmpty) {
      SearchService.initialize(products);
      print('✅ Search service initialized with ${products.length} products');
    } else {
      print('⚠️ No products loaded for search');
    }
  } catch (e) {
    print('❌ Failed to initialize search: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // CHANGE TO MultiProvider
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()), 
        ChangeNotifierProvider(create: (_) => FollowProvider()),
    ChangeNotifierProvider(create: (_) => FavoritesProvider()), // Add this
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Closyyyy App',
        home: const HomeScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}