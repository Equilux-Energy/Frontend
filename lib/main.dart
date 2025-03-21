import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_web/Pages/landing_page.dart';
import 'Pages/signup_page.dart';
import 'Services/theme_provider.dart';
import 'Pages/home_page.dart';
import 'Pages/profile_page.dart';
import 'Pages/transaction_page.dart';
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
              '/': (context) => const HomePage(),
              '/home': (context) => const HomePage(),
              '/signin': (context) => const SignInPage(),
              '/signup': (context) => const SignUpPage(),
              '/chat': (context) => const ChatPage(),
              '/transactions': (context) => const TransactionPage(),
              '/profile': (context) => const ProfilePage(),
              '/settings': (context) => const SettingsPage(),
              '/landing': (context) => const LandingPage(),
            },
          );
        },
      ),
    );
  }
}