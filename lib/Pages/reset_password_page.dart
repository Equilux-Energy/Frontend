// reset_password_page.dart
import 'package:flutter/material.dart';
import '../Services/cognito_service.dart';
import '../Widgets/animated_background.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  late String _username;
  
  final _cognitoService = CognitoService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _username = args['username'];
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _cognitoService.confirmForgotPassword(
          username: _username,
          confirmationCode: _codeController.text,
          newPassword: _passwordController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successful! You can now sign in with your new password.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to sign in
          Navigator.pushReplacementNamed(context, '/signin');
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
    _codeController.dispose();
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Reset Password'),
          ),
          body: Center(
            child: SizedBox(
              width: 600,
              child: Card(
                elevation: 8,
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_open,
                          size: 80,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Reset Your Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enter the verification code sent to the email associated with username $_username and create a new password.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Verification Code',
                                  prefixIcon: Icon(Icons.security),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the verification code';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                  prefixIcon: Icon(Icons.lock),
                                  helperText: 'Must contain at least 8 characters, uppercase, lowercase, number and special character',
                                  helperMaxLines: 2,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a new password';
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
                                  labelText: 'Confirm New Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your new password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  onPressed: _isLoading ? null : _resetPassword,
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : const Text('Reset Password'),
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
            ),
          ),
        ),
      ],
    );
  }
}