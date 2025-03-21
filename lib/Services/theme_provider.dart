import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode to match current style
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }
  
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  
  ThemeData get themeData {
    if (_isDarkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF5C005C),
        scaffoldBackgroundColor: const Color(0xFF1A001A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A0030),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF5C005C),
          secondary: const Color(0xFF9C27B0),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF2A0030),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C005C),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.purple[200],
          ),
        ),
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: const Color(0xFF5C005C),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF5C005C),
          elevation: 0,
          titleTextStyle: const TextStyle(color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        colorScheme: const ColorScheme.light().copyWith(
          primary: const Color(0xFF5C005C),
          secondary: const Color(0xFF9C27B0),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C005C),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5C005C),
            side: const BorderSide(color: Color(0xFF5C005C)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.purple[800],
          ),
        ),
      );
    }
  }
  
  // Custom gradient for card backgrounds
  LinearGradient get cardGradient {
    if (_isDarkMode) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2A0030).withOpacity(0.7),
          const Color(0xff5e0b8b).withOpacity(0.5),
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          const Color(0xFFF3E5F5),
        ],
      );
    }
  }
  
  // Text color based on theme
  Color get textColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get textColorSecondary => _isDarkMode ? Colors.white70 : Colors.black54;
}