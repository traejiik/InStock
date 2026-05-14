import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/data/database/drift_database.dart';
import 'package:instock/data/repositories/app_flags_repository.dart';
import 'package:instock/features/onboarding/providers/onboarding_provider.dart';
import 'package:instock/features/onboarding/screens/onboarding_screen.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('onboarding advances through pages and completes', (
    tester,
  ) async {
    final db = InStockDriftDb.memory();
    final repository = AppFlagsRepository(db);
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFlagsRepositoryProvider.overrideWithValue(repository),
          onboardingInitialStateProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: GoRouter(
            initialLocation: '/onboarding',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Scaffold(body: Text('Home')),
              ),
              GoRoute(
                path: '/onboarding',
                builder: (context, state) => const OnboardingScreen(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Welcome to InStock'), findsOneWidget);
    expect(_skipOpacity(tester), 0);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Track what you have'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(_skipOpacity(tester), 1);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Shop with a plan'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(await repository.isOnboardingComplete(), isTrue);
    expect(find.text('Home'), findsOneWidget);
  });
}

double _skipOpacity(WidgetTester tester) {
  final opacity = tester.widget<AnimatedOpacity>(
    find.ancestor(
      of: find.widgetWithText(TextButton, 'Skip'),
      matching: find.byType(AnimatedOpacity),
    ),
  );
  return opacity.opacity;
}
