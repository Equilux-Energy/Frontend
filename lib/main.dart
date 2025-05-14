import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart'; // Add this import
import 'package:go_router/go_router.dart';
import 'package:test_web/Pages/landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_web/Services/metamask.dart';
import 'Pages/signup_page.dart';
import 'Pages/verification_page.dart';
import 'Pages/forgot_password_page.dart';
import 'Pages/reset_password_page.dart';
import 'Services/theme_provider.dart';
import 'Pages/home_page.dart';
import 'Pages/profile_page.dart';
import 'Pages/transaction_page.dart';
import 'Services/auth_guard.dart';
import 'Pages/chat_page.dart';
import 'Pages/settings_page.dart';
import 'Pages/signin_page.dart';
import 'providers/blockchain_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure Flutter Web to use path URL strategy (no hash)
  setUrlStrategy(PathUrlStrategy());
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // Create and initialize provider
  final metaMaskProvider = MetaMaskProvider();
  await metaMaskProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: metaMaskProvider),
        ChangeNotifierProvider(create: (_) => BlockchainProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PIONEAR Energy Platform',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          initialRoute: '/signin',
          routes: {
            '/': (context) => const LandingPage(),
            '/signin': (context) => const SignInPage(),
            '/signup': (context) => const SignUpPage(),
            '/verification': (context) => const VerificationPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
          },
          // Use onGenerateRoute for routes that need user data
          onGenerateRoute: (settings) {
            // Extract user data if provided
            final arguments = settings.arguments as Map<String, dynamic>?;
            
            switch (settings.name) {
              case '/home':
                if (arguments != null) {
                  // Direct navigation with user data
                  return MaterialPageRoute(
                    builder: (context) => HomePage(userData: arguments),
                  settings: settings,
                  );
                } else {
                  // Protected route using AuthGuard
                  return MaterialPageRoute(
                    builder: (context) => AuthGuard(
                      builder: (userData) => HomePage(userData: userData),
                    ),
                  settings: settings,
                  );
                }
                
              case '/profile':
                if (arguments != null) {
                  return MaterialPageRoute(
                    builder: (context) => ProfilePage(userData: arguments),
                  settings: settings,
                  );
                } else {
                  return MaterialPageRoute(
                    builder: (context) => AuthGuard(
                      builder: (userData) => ProfilePage(userData: userData),
                    ),
                  settings: settings,
                  );
                }
                
              // Other routes remain the same
              case '/transactions':
                return MaterialPageRoute(
                  builder: (context) => AuthGuard(
                    builder: (userData) => TransactionPage(userData: userData),
                  ),
                  settings: settings,
                );
                
              case '/chat':
                return MaterialPageRoute(
                  builder: (context) => AuthGuard(
                    builder: (userData) => ChatPage(userData: userData),
                  ),
                  settings: settings,
                );
                
              case '/settings':
                return MaterialPageRoute(
                  builder: (context) => AuthGuard(
                    builder: (userData) => SettingsPage(userData: userData),
                  ),
                  settings: settings,
                );
                // Handle these routes as before
                
              default:
                return null;
            }
          },
        );
      },
    );
  }
}