import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pose_vision/core/constants/hive_constants.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final Color accentColor;

  const ThemeState({
    required this.themeMode,
    required this.accentColor,
  });

  @override
  List<Object?> get props => [themeMode, accentColor];

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  final Box _settingsBox = Hive.box(HiveBoxes.settings);

  static const String _themeKey = 'theme_mode';
  static const String _accentKey = 'accent_color';

  static const Color defaultAccent = Color(0xFF6366F1); // Indigo

  ThemeCubit()
      : super(const ThemeState(
          themeMode: ThemeMode.system,
          accentColor: defaultAccent,
        )) {
    _loadSettings();
  }

  // Loads persisted theme values on startup.
  void _loadSettings() {
    final savedTheme = _settingsBox.get(_themeKey, defaultValue: 'system');
    final savedAccentInt =
        _settingsBox.get(_accentKey, defaultValue: defaultAccent.value);

    ThemeMode mode;
    switch (savedTheme) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    emit(ThemeState(
      themeMode: mode,
      accentColor: Color(savedAccentInt),
    ));
  }

  Future<void> toggleTheme(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    await _settingsBox.put(_themeKey, isDark ? 'dark' : 'light');
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String themeStr;
    switch (mode) {
      case ThemeMode.light:
        themeStr = 'light';
        break;
      case ThemeMode.dark:
        themeStr = 'dark';
        break;
      default:
        themeStr = 'system';
    }
    await _settingsBox.put(_themeKey, themeStr);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> updateAccentColor(Color color) async {
    await _settingsBox.put(_accentKey, color.value);
    emit(state.copyWith(accentColor: color));
  }
}
