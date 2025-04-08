import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_web/Pages/landing_page.dart';
import 'Pages/signup_page.dart';
import 'Pages/verification_page.dart';
import 'Pages/forgot_password_page.dart'; // Add this
import 'Pages/reset_password_page.dart'; // Add this
import 'Services/theme_provider.dart';
import 'Pages/home_page.dart';
import 'Pages/profile_page.dart';
import 'Pages/transaction_page.dart';
import 'Services/auth_guard.dart';
import 'Pages/chat_page.dart';
import 'Pages/settings_page.dart';
import 'Pages/signin_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'PIONEER Energy Platform',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            initialRoute: '/signin',
            routes: {
              // Unprotected routes
              '/': (context) => const SignInPage(),
              '/signin': (context) => const SignInPage(),
              '/signup': (context) => const SignUpPage(),
              '/verification': (context) => const VerificationPage(),
              '/forgot-password': (context) => const ForgotPasswordPage(), // Add this
              '/reset-password': (context) => const ResetPasswordPage(),   // Add this
              
              // Protected routes
              '/home': (context) => AuthGuard(
                builder: (userData) => HomePage(userData: userData),
              ),
              '/profile': (context) => AuthGuard(
                builder: (userData) => ProfilePage(userData: userData),
              ),
              '/transactions': (context) => AuthGuard(
                builder: (userData) => TransactionPage(userData: userData),
              ),
              '/chat': (context) => AuthGuard(
                builder: (userData) => ChatPage(userData: userData),
              ),
              '/settings': (context) => AuthGuard(
                builder: (userData) => SettingsPage(userData: userData),
              ),
              '/landing': (context) => const LandingPage(),
            },
          );
        },
      ),
    );
  }
}