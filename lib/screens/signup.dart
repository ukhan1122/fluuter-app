import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/auth_service.dart'; // Use AuthService instead

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _loginRecognizer = TapGestureRecognizer();
  final phoneController = TextEditingController();
  bool isChecked = false, isPhoneValid = true, isButtonEnabled = false;
  String phoneErrorText = '';
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _loginRecognizer.onTap = () => Navigator.pushNamed(context, '/login');
    phoneController.addListener(_validateForm);
  }

  void _validateForm() {
    final phone = phoneController.text.trim();
    final startsWith03 = phone.startsWith('03');
    final is11Digits = phone.length == 11;
    final remainingNumeric = _isNumeric(phone.substring(2));
    
    isPhoneValid = startsWith03 && is11Digits && remainingNumeric;
    
    setState(() {
      phoneErrorText = phone.isNotEmpty && !isPhoneValid
          ? !startsWith03 ? 'Phone must start with 03'
          : !is11Digits ? 'Phone must be 11 digits'
          : 'Phone must contain only numbers'
          : '';
      
      isButtonEnabled = isPhoneValid && isChecked;
    });
  }
  
  Future<void> _sendVerification() async {
    if (!isButtonEnabled || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final phone = phoneController.text.trim();
      
      final authService = AuthService();
      final result = await authService.sendVerificationCode(phone);
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success'] == true) {
        // Navigate to OTP verification screen (you'll need to create this)
        Navigator.pushNamed(context, '/verify-otp', arguments: {
          'phone': phone,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send code: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _isNumeric(String str) => str.isNotEmpty && double.tryParse(str) != null;

  @override
  void dispose() {
    phoneController.dispose();
    _loginRecognizer.dispose();
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
                decoration: BoxDecoration(  // FIXED: Added back decoration
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
    margin: const EdgeInsets.symmetric(horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your Mobile Number',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            hintText: '033*********',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            errorText: phoneErrorText.isNotEmpty ? phoneErrorText : null,
            errorStyle: const TextStyle(color: Colors.red),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isPhoneValid ? Colors.blue : Colors.red, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          onChanged: (_) => _validateForm(),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Checkbox(
              value: isChecked,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              onChanged: (value) => setState(() {
                isChecked = value!;
                _validateForm();
              }),
            ),
            const Expanded(
              child: Text(
                'I agree to the Terms of Service and our Privacy Policy',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        SizedBox(  // FIXED: Added back SizedBox wrapper
          width: double.infinity,
          child: InkWell(
            onTap: isButtonEnabled ? _sendVerification : null,
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
                        'Send Code',
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
        const SizedBox(height: 30),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Login',
                  style: const TextStyle(
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: _loginRecognizer,
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
              "'Give your clothes a new life — and earn from it.'",
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