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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Just run the app immediately
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // CHANGE TO MultiProvider
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()), 
        ChangeNotifierProvider(create: (_) => FollowProvider()), // ✅ ADD THIS LINE
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