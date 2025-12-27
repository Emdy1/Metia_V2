import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  Color _seedColor = const Color.fromARGB(255, 72, 255, 0);

  bool get isDarkMode => _isDarkMode;

  ColorScheme get scheme =>
      ColorScheme.fromSeed(seedColor: _seedColor, brightness: _isDarkMode ? Brightness.dark : Brightness.light);

  void setSeed(Color color) {
    _seedColor = color;
    notifyListeners();
  }

  void setLightMode() {
    _isDarkMode = false;
    notifyListeners();
  }

  void setDarkMode() {
    _isDarkMode = true;
    notifyListeners();
  }
}
