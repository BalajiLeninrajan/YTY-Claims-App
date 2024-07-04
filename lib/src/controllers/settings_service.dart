import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that stores and retrieves user settings.
///
/// By default, this class does not persist user settings. If you'd like to
/// persist the user settings locally, use the shared_preferences package. If
/// you'd like to store settings on a web server, use the http package.
class SettingsService {
  static const String prefKeyThemeMode = 'ThemeMode';
  static const String prefKeyLoginFlag = 'LoginFlag';

  /// Loads the User's preferred ThemeMode from local or remote storage.
  Future<ThemeMode> themeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString(prefKeyThemeMode) ?? ThemeMode.system.name;
    if (name == ThemeMode.light.name) {
      return ThemeMode.light;
    } else if (name == ThemeMode.dark.name) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system;
    }
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(prefKeyThemeMode, theme.name);
  }

  Future<bool> loginFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyLoginFlag) ?? false;
  }

  Future<void> updateLoginFlag(bool flag) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(prefKeyLoginFlag, flag);
  }
}
