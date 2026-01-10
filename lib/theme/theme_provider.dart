import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider({required bool isDark})
      : _themeData = isDark ? darkMode : lightMode;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (_themeData == lightMode) {
      _themeData = darkMode;
      await prefs.setBool("isDarkMode", true);
    } else {
      _themeData = lightMode;
      await prefs.setBool("isDarkMode", false);
    }

    notifyListeners();
  }
}
