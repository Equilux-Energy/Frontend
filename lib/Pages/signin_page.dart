// signin_page.dart
import 'package:flutter/material.dart';
import '../Widgets/animated_background.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 1), () {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
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
                                      decoration: const InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(Icons.email)),
                                      validator: (value) => value!.isEmpty
                                          ? 'Enter email'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: Icon(Icons.lock)),
                                      validator: (value) => value!.length < 6
                                          ? 'Minimum 6 characters'
                                          : null,
                                    ),
                                    const SizedBox(height: 32),
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
