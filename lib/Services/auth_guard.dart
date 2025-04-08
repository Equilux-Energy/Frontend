import 'package:flutter/material.dart';
import 'cognito_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget Function(Map<String, dynamic> userData) builder;
  final String redirectRoute;

  const AuthGuard({
    Key? key,
    required this.builder,
    this.redirectRoute = '/signin',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cognitoService = CognitoService();
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: cognitoService.getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final userData = snapshot.data;
        
        if (userData != null) {
          // User is authenticated, show protected content
          return builder(userData);
        } else {
          // Not authenticated, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(redirectRoute);
          });
          
          return const Scaffold(
            body: Center(child: Text('Authentication required')),
          );
        }
      },
    );
  }
}