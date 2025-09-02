import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkModeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Get Dark Mode Value
  getDarkMode() async {
    try {
      _isLoading = true;

      final prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey('is_dark_mode')) {
        _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      } else {
        _isDarkMode = false;
        await prefs.setBool('is_dark_mode', _isDarkMode);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Get Dark Mode Error: ${e.toString()}');
    }
  }

  // Set Dark Mode Value
  setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isDarkMode = value;
      prefs.setBool('is_dark_mode', value);

      notifyListeners();
    } catch (e) {
      debugPrint('Set Dark Mode Error: ${e.toString()}');
    }
  }
}
