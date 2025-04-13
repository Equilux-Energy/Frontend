import 'package:flutter/material.dart';
import '../Services/cognito_service.dart';
import '../Services/user_service.dart';

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
    
    return FutureBuilder<bool>(
      future: cognitoService.isAuthenticated(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final isAuthenticated = authSnapshot.data ?? false;
        
        if (!isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(redirectRoute);
          });
          
          return const Scaffold(
            body: Center(child: Text('Authentication required')),
          );
        }
        
        // Get username from token claims
        return FutureBuilder<Map<String, dynamic>?>(
          future: cognitoService.getUserInfo(),
          builder: (context, userInfoSnapshot) {
            if (userInfoSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            final userInfo = userInfoSnapshot.data;
            final username = userInfo?['cognito:username'] ?? userInfo?['username'];
            
            if (username == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed(redirectRoute);
              });
              
              return const Scaffold(
                body: Center(child: Text('Username not found')),
              );
            }
            
            // Now get full user data using getUserData
            return FutureBuilder<Map<String, dynamic>?>(
              future: UserService().getUserData(username),
              builder: (context, userDataSnapshot) {
                if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final userData = userDataSnapshot.data;
                
                if (userData == null) {
                  // Instead of an empty map, we'll redirect to sign-in if there's no data
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacementNamed(redirectRoute);
                  });
                  
                  return const Scaffold(
                    body: Center(child: Text('User data not available')),
                  );
                }
                
                // Add userinfo data to userData for completeness
                if (userInfo != null) {
                  userData.addAll(userInfo);
                }
                
                return builder(userData);
              },
            );
          },
        );
      },
    );
  }
}