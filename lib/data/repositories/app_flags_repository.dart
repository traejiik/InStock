import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/features/settings/providers/settings_provider.dart';

import '../database/drift_database.dart';

const _appFlagsSingletonId = 'singleton';

final appFlagsRepositoryProvider = Provider<AppFlagsRepository>(
  (ref) => throw UnimplementedError(
    'Override appFlagsRepositoryProvider in ProviderScope',
  ),
);

class AppFlagsSnapshot {
  const AppFlagsSnapshot({
    required this.onboardingCompleted,
    required this.unitSystem,
    required this.themeMode,
  });

  final bool onboardingCompleted;
  final UnitSystem unitSystem;
  final AppThemeMode themeMode;
}

class AppFlagsRepository {
  AppFlagsRepository(this._db);

  final InStockDriftDb _db;

  Future<AppFlagsSnapshot> load() async {
    final row = await _readSingleton();
    return AppFlagsSnapshot(
      onboardingCompleted: row?.onboardingCompleted == 1,
      unitSystem: _unitSystemFromStorage(row?.unitSystem),
      themeMode: _themeModeFromStorage(row?.themeMode),
    );
  }

  Future<bool> isOnboardingComplete() async {
    final row = await _readSingleton();

    return row?.onboardingCompleted == 1;
  }

  Future<void> markOnboardingComplete() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.appFlags)
        .insertOnConflictUpdate(
          AppFlagsCompanion.insert(
            id: _appFlagsSingletonId,
            onboardingCompleted: 1,
            onboardingCompletedAt: Value(now),
            updatedAt: now,
          ),
        );
  }

  Future<UnitSystem> getUnitSystem() async {
    final row = await _readSingleton();
    return _unitSystemFromStorage(row?.unitSystem);
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = await _readSingleton();
    await _db
        .into(_db.appFlags)
        .insertOnConflictUpdate(
          AppFlagsCompanion.insert(
            id: _appFlagsSingletonId,
            onboardingCompleted: row?.onboardingCompleted ?? 0,
            onboardingCompletedAt: Value(row?.onboardingCompletedAt),
            unitSystem: Value(_unitSystemToStorage(value)),
            themeMode: Value(
              row?.themeMode ?? _themeModeToStorage(AppThemeMode.system),
            ),
            updatedAt: now,
          ),
        );
  }

  Future<AppThemeMode> getThemeMode() async {
    final row = await _readSingleton();
    return _themeModeFromStorage(row?.themeMode);
  }

  Future<void> setThemeMode(AppThemeMode value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = await _readSingleton();
    await _db
        .into(_db.appFlags)
        .insertOnConflictUpdate(
          AppFlagsCompanion.insert(
            id: _appFlagsSingletonId,
            onboardingCompleted: row?.onboardingCompleted ?? 0,
            onboardingCompletedAt: Value(row?.onboardingCompletedAt),
            unitSystem: Value(
              row?.unitSystem ?? _unitSystemToStorage(UnitSystem.metric),
            ),
            themeMode: Value(_themeModeToStorage(value)),
            updatedAt: now,
          ),
        );
  }

  Future<void> reset() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.appFlags)
        .insertOnConflictUpdate(
          AppFlagsCompanion.insert(
            id: _appFlagsSingletonId,
            onboardingCompleted: 0,
            onboardingCompletedAt: const Value(null),
            updatedAt: now,
          ),
        );
  }

  Future<AppFlagData?> _readSingleton() {
    return (_db.select(
      _db.appFlags,
    )..where((flag) => flag.id.equals(_appFlagsSingletonId))).getSingleOrNull();
  }
}

UnitSystem _unitSystemFromStorage(String? value) {
  return switch (value) {
    'imperial' => UnitSystem.imperial,
    _ => UnitSystem.metric,
  };
}

String _unitSystemToStorage(UnitSystem value) {
  return switch (value) {
    UnitSystem.imperial => 'imperial',
    UnitSystem.metric => 'metric',
  };
}

AppThemeMode _themeModeFromStorage(String? value) {
  return switch (value) {
    'dark' => AppThemeMode.dark,
    'light' => AppThemeMode.light,
    _ => AppThemeMode.system,
  };
}

String _themeModeToStorage(AppThemeMode value) {
  return switch (value) {
    AppThemeMode.dark => 'dark',
    AppThemeMode.light => 'light',
    AppThemeMode.system => 'system',
  };
}
