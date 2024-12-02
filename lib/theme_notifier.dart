import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadTheme();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  // Load theme preference from SharedPreferences
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('isDarkMode')) {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    } else {
      // Use system default theme if no preference is saved
      _isDarkMode =
          PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  void _saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }
}
