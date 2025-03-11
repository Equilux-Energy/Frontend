// main.dart
import 'package:flutter/material.dart';
import 'package:test_web/Pages/landing_page.dart';
import 'Pages/chat_page.dart';
import 'Pages/transaction_page.dart';
import 'pages/signin_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';
// Add this import

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIONEER',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      initialRoute: '/signin',
      routes: {
        '/home': (context) => const HomePage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/landing': (context) => const LandingPage(),
        '/chat': (context) => const ChatPage(),
        '/transactions': (context) => const TransactionPage(),
      },
    );
  }
}
