import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _signupRecognizer = TapGestureRecognizer();
  final _forgotPasswordRecognizer = TapGestureRecognizer();
  final loginController = TextEditingController();
  final passwordController = TextEditingController();
  bool isButtonEnabled = false;
  bool isLoginValid = true;
  bool isPasswordValid = true;
  String loginErrorText = '';
  String passwordErrorText = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _signupRecognizer.onTap = () => Navigator.pushNamed(context, '/signup');
    _forgotPasswordRecognizer.onTap = () => Navigator.pushNamed(context, '/forgot-password');
    loginController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final login = loginController.text.trim();
    final password = passwordController.text.trim();
    
    final validLogin = login.isNotEmpty && login.length >= 3;
    final validPassword = password.isNotEmpty && password.length >= 3;
    
    setState(() {
      isLoginValid = validLogin;
      isPasswordValid = validPassword;
      
      loginErrorText = login.isNotEmpty && !validLogin 
          ? 'Username/Email must be at least 3 characters' 
          : '';
      passwordErrorText = password.isNotEmpty && !validPassword 
          ? 'Password must be at least 3 characters' 
          : '';
      
      isButtonEnabled = validLogin && validPassword;
    });
  }

 Future<void> _performLogin() async {
  if (!isButtonEnabled || _isLoading) return;
  
  setState(() => _isLoading = true);
  
  try {
    final login = loginController.text.trim();
    final password = passwordController.text.trim();
    
    
    print('🔐 Attempting login with: $login');
    final authService = AuthService();
    final result = await authService.login(login, password);
    
    print('📦 Login result: $result');
    
    if (mounted) setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      
      print('✅ Login successful! Navigating to home...');
      if (mounted) {
        
        final isLoggedIn = await authService.isLoggedIn();
        print('📱 Is logged in after login: $isLoggedIn');
        Navigator.pushReplacementNamed(context, '/home');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back! Login successful.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Handle 400 error and other errors professionally
      if (mounted) {
        String errorMessage = '';
        
        // Check if it's a 400 error with validation messages
        if (result['statusCode'] == 400) {
          if (result['errors'] != null) {
            // Laravel validation errors
            final errors = result['errors'] as Map;
            if (errors['email'] != null) {
              errorMessage = errors['email'][0];
            } else if (errors['password'] != null) {
              errorMessage = errors['password'][0];
            } else if (errors['login'] != null) {
              errorMessage = errors['login'][0];
            } else {
              errorMessage = 'Invalid credentials. Please check your email/username and password.';
            }
          } else if (result['message'] != null) {
            errorMessage = result['message'];
          } else {
            errorMessage = 'Invalid email/username or password. Please try again.';
          }
        } else if (result['statusCode'] == 401) {
          errorMessage = 'Unauthorized. Please check your credentials.';
        } else if (result['statusCode'] == 404) {
          errorMessage = 'Account not found. Please sign up first.';
        } else {
          errorMessage = result['error'] ?? 'Login failed. Please check your credentials and try again.';
        }
        
        // Show professional error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unable to connect to server. Please check your internet connection.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    _signupRecognizer.dispose();
    _forgotPasswordRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 800) {
                      return Column(
                        children: [
                          _leftColumn(),
                          _rightColumn(height: 250),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(flex: 5, child: _leftColumn()),
                          Expanded(flex: 7, child: _rightColumn(height: null)),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leftColumn() => Container(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo/Brand
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.shopping_bag,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Welcome Text
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to continue your journey',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        
        // Login Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Username or Email',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: loginController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'User@gmail.com',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: isLoginValid ? Colors.grey.shade600 : Colors.red.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
                errorText: loginErrorText.isNotEmpty ? loginErrorText : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (_) => _validateForm(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Password Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 16),
              onSubmitted: (_) => _performLogin(),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: isPasswordValid ? Colors.grey.shade600 : Colors.red.shade400,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
                errorText: passwordErrorText.isNotEmpty ? passwordErrorText : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (_) => _validateForm(),
            ),
          ],
        ),
        
        // Forgot Password Link
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/forgot-password'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Login Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isButtonEnabled && !_isLoading ? _performLogin : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Sign Up Link
        Center(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Sign up',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _signupRecognizer,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _rightColumn({double? height}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth <= 767 ? 22.0 : 28.0;
    
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(32)),
        image: DecorationImage(
          image: const AssetImage('assets/col7.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay for better text readability
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(32)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black54,
                ],
              ),
            ),
          ),
          
          // Quote Text
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✨ Premium Quality',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '"Welcome back — continue your journey with us."',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.3,
                    shadows: [
                      const Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sustainable fashion starts here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}