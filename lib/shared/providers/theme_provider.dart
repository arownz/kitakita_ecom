import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  bool _loaded = false;

  Future<void> loadFromPrefs() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('dark_mode') ?? false;
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  Future<void> setDarkMode(bool enabled) async {
    state = enabled ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', enabled);
    } catch (_) {}
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
      final controller = ThemeController();
      // Fire-and-forget load; guarded internally to only run once.
      controller.loadFromPrefs();
      return controller;
    });
