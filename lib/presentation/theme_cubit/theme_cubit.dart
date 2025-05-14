import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_themes.dart';

enum AppTheme { light, dark }

class ThemeCubit extends Cubit<AppTheme> {
  static const String _themePreferenceKey = 'app_theme_preference_v1';

  ThemeCubit() : super(AppTheme.light) {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_themePreferenceKey)) {
        final themeIndex = prefs.getInt(_themePreferenceKey);
        if (themeIndex != null && themeIndex >= 0 && themeIndex < AppTheme.values.length) {
          emit(AppTheme.values[themeIndex]);
        } else {
          emit(AppTheme.light);
          await prefs.remove(_themePreferenceKey);
        }
      } else {
        emit(AppTheme.light);
      }
    } catch (e) {
      emit(AppTheme.light);
      print("Error loading theme preference: $e");
    }
  }

  Future<void> _saveThemePreference(AppTheme theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePreferenceKey, theme.index);
    } catch (e) {
      print("Error saving theme preference: $e");
    }
  }

  void toggleTheme() {
    final newTheme = (state == AppTheme.light) ? AppTheme.dark : AppTheme.light;
    emit(newTheme);
    _saveThemePreference(newTheme);
  }

  void setTheme(AppTheme theme) {
    if (state != theme) {
      emit(theme);
      _saveThemePreference(theme);
    }
  }

  ThemeData get currentThemeData {
    return state == AppTheme.light ? AppThemes.lightTheme : AppThemes.darkTheme;
  }
}