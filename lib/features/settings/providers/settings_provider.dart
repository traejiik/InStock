import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:instock/data/repositories/app_flags_repository.dart';

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
  UnitPreferenceNotifier(this._repository, UnitSystem initialState)
    : super(initialState);

  final AppFlagsRepository _repository;

  Future<void> set(UnitSystem value) async {
    state = value;
    await _repository.setUnitSystem(value);
  }
}

class ThemePreferenceNotifier extends StateNotifier<AppThemeMode> {
  ThemePreferenceNotifier(this._repository, AppThemeMode initialState)
    : super(initialState);

  final AppFlagsRepository _repository;

  Future<void> set(AppThemeMode value) async {
    state = value;
    await _repository.setThemeMode(value);
  }
}

final unitInitialStateProvider = Provider<UnitSystem>(
  (ref) => UnitSystem.metric,
);

final themeInitialStateProvider = Provider<AppThemeMode>(
  (ref) => AppThemeMode.system,
);

final unitPreferenceProvider =
    StateNotifierProvider<UnitPreferenceNotifier, UnitSystem>(
      (ref) => UnitPreferenceNotifier(
        ref.watch(appFlagsRepositoryProvider),
        ref.watch(unitInitialStateProvider),
      ),
    );

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, AppThemeMode>(
      (ref) => ThemePreferenceNotifier(
        ref.watch(appFlagsRepositoryProvider),
        ref.watch(themeInitialStateProvider),
      ),
    );

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});
