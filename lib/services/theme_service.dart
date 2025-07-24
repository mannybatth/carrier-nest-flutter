import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  AppThemeMode _themeMode = AppThemeMode.system;
  late SharedPreferences _prefs;

  AppThemeMode get themeMode => _themeMode;

  /// Initialize theme service and load saved preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemeMode();
  }

  /// Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    final savedThemeMode = _prefs.getString(_themeModeKey);
    switch (savedThemeMode) {
      case 'light':
        _themeMode = AppThemeMode.light;
        break;
      case 'dark':
        _themeMode = AppThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = AppThemeMode.system;
        break;
    }
    notifyListeners();
  }

  /// Save theme mode to shared preferences
  Future<void> _saveThemeMode() async {
    String themeModeString;
    switch (_themeMode) {
      case AppThemeMode.light:
        themeModeString = 'light';
        break;
      case AppThemeMode.dark:
        themeModeString = 'dark';
        break;
      case AppThemeMode.system:
        themeModeString = 'system';
        break;
    }
    await _prefs.setString(_themeModeKey, themeModeString);
  }

  /// Update theme mode
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      await _saveThemeMode();
      notifyListeners();
    }
  }

  /// Get the effective brightness based on current theme mode and system settings
  Brightness getEffectiveBrightness(BuildContext context) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Check if dark mode is currently active
  bool isDarkMode(BuildContext context) {
    return getEffectiveBrightness(context) == Brightness.dark;
  }

  /// Get theme mode display name
  String getThemeModeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'Automatic';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  /// Get current theme mode display name
  String get currentThemeModeDisplayName => getThemeModeDisplayName(_themeMode);

  /// Convert to Material ThemeMode
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

/// Global theme service instance
final themeService = ThemeService();
