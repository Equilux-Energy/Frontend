// signup_page.dart
import 'package:flutter/material.dart';

import '../Widgets/animated_background.dart';
import '../Services/cognito_service.dart'; // Add this import
import 'signin_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Add controllers for all fields
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Create an instance of the CognitoService
  final _cognitoService = CognitoService();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _cognitoService.signUp(
          username: _usernameController.text,
          password: _passwordController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
        );
        
        // Handle successful signup
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please check your email for confirmation.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to verification page instead of home
          Navigator.pushReplacementNamed(
            context, 
            '/verification',
            arguments: {
              'username': _usernameController.text,
              'email': _emailController.text,
            },
          );
        }
      } catch (e) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Stack(
    children: [
      const AnimatedBackground(),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(  // Add ScrollView for overflow handling
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: 450, // Fixed width constraint
                    ),
                    child: Card(
                      elevation: 8,
                      margin: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,  // Height will still shrink-wrap content
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const FlutterLogo(size: 80),
                            const SizedBox(height: 24),
                            const Text('Create New Account',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 32),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email)),
                                    validator: (value) => value!.isEmpty ? 'Enter email' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      prefixIcon: Icon(Icons.phone)),
                                    validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.supervised_user_circle_sharp)),
                                    validator: (value) => value!.isEmpty ? 'Enter Username' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock),
                                      helperText: 'Must contain at least 8 characters, uppercase, lowercase, number and special character',
                                      helperMaxLines: 2,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      
                                      bool hasMinLength = value.length >= 8;
                                      bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
                                      bool hasLowercase = value.contains(RegExp(r'[a-z]'));
                                      bool hasNumber = value.contains(RegExp(r'[0-9]'));
                                      bool hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
                                      
                                      List<String> requirements = [];
                                      if (!hasMinLength) requirements.add('8+ characters');
                                      if (!hasUppercase) requirements.add('uppercase letter');
                                      if (!hasLowercase) requirements.add('lowercase letter');
                                      if (!hasNumber) requirements.add('number');
                                      if (!hasSpecialChar) requirements.add('special character');
                                      
                                      if (requirements.isEmpty) {
                                        return null;
                                      } else {
                                        return 'Must include ${requirements.join(', ')}';
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm Password',
                                      prefixIcon: Icon(Icons.lock_outline)),
                                    validator: (value) => value != _passwordController.text
                                        ? 'Passwords do not match'
                                        : null,
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16)),
                                      onPressed: _isLoading ? null : _submit,
                                      child: _isLoading
                                          ? const CircularProgressIndicator()
                                          : const Text('Sign Up'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => const SignInPage(),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              const begin = Offset(1.0, 0.0);
                                              const end = Offset.zero;
                                              const curve = Curves.ease;

                                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                              return SlideTransition(
                                                position: animation.drive(tween),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: const Text('Already have an account? Sign In'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'By signing up, you agree to our\nTerms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
  }
}