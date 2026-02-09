import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _signupRecognizer = TapGestureRecognizer();
  final loginController = TextEditingController(); // Changed from emailController
  final passwordController = TextEditingController();
  bool isButtonEnabled = false, isLoginValid = true, isPasswordValid = true; // Changed isEmailValid to isLoginValid
  String loginErrorText = '', passwordErrorText = ''; // Changed emailErrorText to loginErrorText
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _signupRecognizer.onTap = () => Navigator.pushNamed(context, '/signup');
    loginController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final login = loginController.text.trim(); // This can be username OR email
    final password = passwordController.text.trim();
    
    // ACCEPT ANY NON-EMPTY LOGIN (username or email)
    final validLogin = login.isNotEmpty && login.length >= 3;
    
    final validPassword = password.length >= 3;
    
    setState(() {
      isLoginValid = validLogin;
      isPasswordValid = validPassword;
      
      loginErrorText = login.isNotEmpty && !validLogin ? 'Login must be at least 3 characters' : '';
      passwordErrorText = password.isNotEmpty && !validPassword ? 'Password must be at least 3 characters' : '';
      
      isButtonEnabled = validLogin && validPassword;
    });
  }

  Future<void> _performLogin() async {
    if (!isButtonEnabled || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final login = loginController.text.trim(); // This is username OR email
      final password = passwordController.text.trim();
      
      final authService = AuthService();
      final result = await authService.login(login, password); // Pass login, not email
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success'] == true) {
        // Navigate to profile screen
        Navigator.pushReplacementNamed(context, '/profile');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    _signupRecognizer.dispose();
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return constraints.maxWidth < 800
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [_leftColumn(), const SizedBox(height: 20), _rightColumn()],
                          )
                        : Row(
                            children: [
                              Expanded(flex: 5, child: _leftColumn()),
                              Expanded(flex: 7, child: _rightColumn()),
                            ],
                          );
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
    margin: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Login to your Account',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: loginController, // Changed from emailController
          keyboardType: TextInputType.text, // Changed from emailAddress
          decoration: InputDecoration(
            labelText: 'Username or Email', // Changed label
            hintText: 'explain816 or user@gmail.com', // Changed hint
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            errorText: loginErrorText.isNotEmpty ? loginErrorText : null, // Changed variable
            errorStyle: const TextStyle(color: Colors.red),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isLoginValid ? Colors.blue : Colors.red, // Changed variable
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          onChanged: (_) => _validateForm(),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: '**********',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            errorText: passwordErrorText.isNotEmpty ? passwordErrorText : null,
            errorStyle: const TextStyle(color: Colors.red),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isPasswordValid ? Colors.blue : Colors.red,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          onChanged: (_) => _validateForm(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: isButtonEnabled ? _performLogin : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isButtonEnabled ? Colors.red : Colors.grey.shade400,
                boxShadow: isButtonEnabled
                    ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isButtonEnabled ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Sign up',
                  style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w700),
                  recognizer: _signupRecognizer,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _rightColumn() {
    final fontSize = MediaQuery.of(context).size.width <= 767 ? 22.0 : 28.0;
    return Stack(
      children: [
        Image.asset('assets/col7.png', width: double.infinity, fit: BoxFit.cover),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Text(
              "'Welcome back — continue your journey with us.'",
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
                shadows: const [
                  Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}