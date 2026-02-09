import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ADD THIS IMPORT
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/home_screen.dart';
import 'providers/user_provider.dart';
import 'services/api_service.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test API before anything else
  ApiService.testMinimalRequest().then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( // WRAP WITH THIS
      create: (context) => UserProvider(),
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