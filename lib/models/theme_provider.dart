import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ColorScheme get scheme => ColorScheme.fromSeed(
    seedColor: Color.fromARGB(255, 72, 255, 0),
    brightness: _isDarkMode ? Brightness.dark : Brightness.light,
  );

  void setLightMode() {
    _isDarkMode = false;
    notifyListeners();
  }

  void setDarkMode() {
    _isDarkMode = true;
    notifyListeners();
  }
}
