import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/cognito_service.dart';
import '../Services/theme_provider.dart';
import '../Widgets/animated_background.dart';
import '../Widgets/animated_background_light.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  late String _username;
  late String _email;

  // Create an instance of the CognitoService
  final _cognitoService = CognitoService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _username = args['username'];
    _email = args['email'];
  }

  void _submitVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _cognitoService.confirmSignUp(
          username: _username,
          confirmationCode: _codeController.text,
        );
        
        // Handle successful verification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully! You can now sign in.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to sign in page
          Navigator.pushReplacementNamed(context, '/signin');
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

  void _resendVerificationCode() async {
    setState(() => _isResending = true);
    
    try {
      await _cognitoService.resendConfirmationCode(
        username: _username,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent. Please check your email.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resending code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Stack(
      children: [
        if (isDarkMode) const AnimatedBackground() else const AnimatedBackgroundLight(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Verify Email'),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 450,
                      ),
                      child: Card(
                        elevation: 8,
                        margin: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.mark_email_read,
                                size: 70,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Verify Your Email',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'We\'ve sent a verification code to $_email',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
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
                                        hintText: 'Enter 6-digit code',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter verification code';
                                        }
                                        if (value.length != 6) {
                                          return 'Code must be 6 digits';
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
                                        onPressed: _isLoading ? null : _submitVerification,
                                        child: _isLoading
                                            ? const CircularProgressIndicator()
                                            : const Text('Verify Email'),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      onPressed: _isResending ? null : _resendVerificationCode,
                                      icon: _isResending 
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.refresh),
                                      label: Text(_isResending ? 'Sending...' : 'Resend verification code'),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Didn\'t receive the code? Check your spam folder or try resending.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
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