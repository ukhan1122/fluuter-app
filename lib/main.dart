import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/home_screen.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';
import 'services/api_service.dart';
import 'screens/profile_screen.dart';
import 'screens/seller_profile_screen.dart';
import 'providers/follow_provider.dart';
import 'services/search_service.dart';
import 'providers/favorites_provider.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/set_new_password_screen.dart';
import 'screens/verify_otp_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeSearch();
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()), 
        ChangeNotifierProvider(create: (_) => FollowProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Closyyyy App',
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle seller profile route
          if (settings.name == '/seller-profile') {
            final args = settings.arguments as Map?;
            return MaterialPageRoute(
              builder: (context) => SellerProfileScreen(
                sellerId: args?['sellerId'] ?? '',
              ),
            );
          }
          
          // Handle set-new-password
          if (settings.name == '/set-new-password') {
            final args = settings.arguments as Map?;
            return MaterialPageRoute(
              builder: (context) => SetNewPasswordScreen(
                token: args?['token'] ?? '',
              ),
            );
          }
          
          // Handle verify-otp
          if (settings.name == '/verify-otp') {
            final args = settings.arguments as Map?;
            return MaterialPageRoute(
              builder: (context) => VerifyOTPScreen(
                phone: args?['phone'] ?? '',
              ),
            );
          }
          
          // Fallback for any other route
          print('Route not found: ${settings.name}');
          return MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          );
        },
      ),
    );
  }
}