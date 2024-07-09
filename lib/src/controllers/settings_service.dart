import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that stores and retrieves user settings.
class SettingsService {
  static const String prefKeyThemeMode = 'ThemeMode';
  static const String prefKeyLoginFlag = 'LoginFlag';

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

  Future<void> updateThemeMode(ThemeMode theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(prefKeyThemeMode, theme.name);
  }

  Future<String> loginFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefKeyLoginFlag) ?? '';
  }

  Future<void> updateLoginFlag(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(prefKeyLoginFlag, id);
  }

  Future<void> removeLoginFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(prefKeyLoginFlag);
  }
}
