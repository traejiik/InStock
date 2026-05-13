import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUnitPrefKey = 'instock_unit_pref';
const _kThemePrefKey = 'instock_theme_pref';

enum UnitSystem { metric, imperial }

enum AppThemeMode { dark, system, light }

extension AppThemeModeX on AppThemeMode {
  ThemeMode toThemeMode() => switch (this) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
  };
}

class UnitPreferenceNotifier extends StateNotifier<UnitSystem> {
  UnitPreferenceNotifier() : super(UnitSystem.metric) {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      final raw = prefs.getString(_kUnitPrefKey);
      if (raw == 'imperial') state = UnitSystem.imperial;
    });
  }

  SharedPreferences? _prefs;

  void set(UnitSystem value) {
    state = value;
    _prefs?.setString(
      _kUnitPrefKey,
      value == UnitSystem.imperial ? 'imperial' : 'metric',
    );
  }
}

class ThemePreferenceNotifier extends StateNotifier<AppThemeMode> {
  ThemePreferenceNotifier() : super(AppThemeMode.system) {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      final raw = prefs.getString(_kThemePrefKey);
      state = switch (raw) {
        'dark' => AppThemeMode.dark,
        'light' => AppThemeMode.light,
        _ => AppThemeMode.system,
      };
    });
  }

  SharedPreferences? _prefs;

  void set(AppThemeMode value) {
    state = value;
    _prefs?.setString(_kThemePrefKey, switch (value) {
      AppThemeMode.dark => 'dark',
      AppThemeMode.light => 'light',
      AppThemeMode.system => 'system',
    });
  }
}

final unitPreferenceProvider =
    StateNotifierProvider<UnitPreferenceNotifier, UnitSystem>(
      (ref) => UnitPreferenceNotifier(),
    );

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, AppThemeMode>(
      (ref) => ThemePreferenceNotifier(),
    );

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});
