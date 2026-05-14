import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:instock/data/database/drift_database.dart';
import 'package:instock/data/repositories/app_flags_repository.dart';
import 'package:instock/features/settings/providers/settings_provider.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('AppFlagsRepository', () {
    late InStockDriftDb db;
    late AppFlagsRepository repository;

    setUp(() {
      db = InStockDriftDb.memory();
      repository = AppFlagsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'reports onboarding incomplete when the singleton row is missing',
      () async {
        expect(await repository.isOnboardingComplete(), isFalse);
      },
    );

    test('marks onboarding complete and persists the flag', () async {
      await repository.markOnboardingComplete();

      expect(await repository.isOnboardingComplete(), isTrue);
    });

    test('resets onboarding completion for QA', () async {
      await repository.markOnboardingComplete();
      await repository.reset();

      expect(await repository.isOnboardingComplete(), isFalse);
    });

    test(
      'defaults unit and theme preferences when the row is missing',
      () async {
        expect(await repository.getUnitSystem(), UnitSystem.metric);
        expect(await repository.getThemeMode(), AppThemeMode.system);
      },
    );

    test('persists unit and theme preferences through AppFlags', () async {
      await repository.setUnitSystem(UnitSystem.imperial);
      await repository.setThemeMode(AppThemeMode.light);

      expect(await repository.getUnitSystem(), UnitSystem.imperial);
      expect(await repository.getThemeMode(), AppThemeMode.light);
    });
  });
}
