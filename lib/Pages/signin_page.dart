// signin_page.dart
import 'package:flutter/material.dart';
import '../Services/cognito_service.dart';
import '../Services/user_service.dart';
import '../Widgets/animated_background.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _cognitoService = CognitoService();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Authenticate with Cognito
        final authResult = await _cognitoService.signIn(
          username: _usernameController.text,
          password: _passwordController.text,
        );
        
        // Load user data
        final userService = UserService();
        final userData = await userService.getUserData(_usernameController.text);
        
        if (userData == null) {
          throw Exception('Failed to retrieve user data');
        }
        
        if (mounted) {
          // Use this navigation method to completely replace the URL
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: userData,
          );
        }
      } catch (e) {
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SizedBox(
              width: 600,
              height: 800,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 600,
                      height: 718,
                      child: Card(
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const FlutterLogo(size: 80),
                              const SizedBox(height: 24),
                              const Text('Sign In to Your Account',
                                  style: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 32),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _usernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                      validator: (value) => value!.isEmpty
                                          ? 'Enter username'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock),
                                      ),
                                      validator: (value) => value!.isEmpty
                                          ? 'Enter password'
                                          : null,
                                    ),
                                    const SizedBox(height: 8), // Smaller spacing
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const ForgotPasswordPage(),
                                            ),
                                          );
                                        },
                                        child: const Text('Forgot Password?'),
                                      ),
                                    ),
                                    const SizedBox(height: 24), // Keep spacing before button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            padding:
                                                const EdgeInsets.symmetric(vertical: 16)),
                                        onPressed: _isLoading ? null : _submit,
                                        child: _isLoading
                                            ? const CircularProgressIndicator()
                                            : const Text('Sign In'),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const SignUpPage(),
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
                                    child: const Text('Create new account'),
                                  ),
                                    // Social Login Section
                                    const SizedBox(height: 24),
                                    const Row(
                                      children: [
                                        Expanded(child: Divider()),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('OR'),
                                        ),
                                        Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.g_mobiledata, size: 24),
                                        label: const Text('Continue with Google'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: const BorderSide(color: Colors.grey),
                                        ),
                                        onPressed: () {}, // Empty onPressed for now
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.facebook, size: 24),
                                        label: const Text('Continue with Facebook'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: const BorderSide(color: Colors.grey),
                                        ),
                                        onPressed: () {}, // Empty onPressed for now
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                              const Text(
                                'By signing in, you agree to our\nTerms of Service and Privacy Policy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
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
