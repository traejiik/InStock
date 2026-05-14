import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/app.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/database/drift_database.dart';
import 'package:instock/data/repositories/app_flags_repository.dart';
import 'package:instock/features/onboarding/providers/onboarding_provider.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('first launch routes to onboarding before the app shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final driftDb = InStockDriftDb.memory();
    final appDatabase = AppDatabase(db: driftDb);
    await appDatabase.init();
    final appFlagsRepository = AppFlagsRepository(driftDb);
    addTearDown(driftDb.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => appDatabase),
          appFlagsRepositoryProvider.overrideWithValue(appFlagsRepository),
          onboardingInitialStateProvider.overrideWithValue(false),
        ],
        child: const InStockApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to InStock'), findsOneWidget);
    expect(find.text('Shopping'), findsNothing);
  });

  testWidgets('completed onboarding routes to the app shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final driftDb = InStockDriftDb.memory();
    final appDatabase = AppDatabase(db: driftDb);
    await appDatabase.init();
    final appFlagsRepository = AppFlagsRepository(driftDb);
    await appFlagsRepository.markOnboardingComplete();
    addTearDown(driftDb.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => appDatabase),
          appFlagsRepositoryProvider.overrideWithValue(appFlagsRepository),
          onboardingInitialStateProvider.overrideWithValue(true),
        ],
        child: const InStockApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to InStock'), findsNothing);
    expect(find.text('Shopping'), findsWidgets);
  });
}
