import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/database/drift_database.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/features/recipes/screens/add_recipe_screen.dart';
import 'package:instock/features/recipes/widgets/recipe_card.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/features/shopping/screens/shopping_screen.dart';
import 'package:instock/shared/widgets/category_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('RecipeCardSm lays out inside a row with unbounded height', (
    tester,
  ) async {
    final recipe = Recipe(
      id: 'recipe-1',
      title: 'Test Recipe',
      emoji: '🍽️',
      instructions: const ['Cook it.'],
      servings: 2,
      cookMinutes: 15,
      difficulty: 'Easy',
      tags: const [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RecipeCardSm(
                        recipe: recipe,
                        isMakeable: true,
                        missingCount: 0,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'CategoryPicker uses a dropdown and emits the selected category',
    (tester) async {
      var selected = IngredientCategory.custom;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPicker(
              selectedCategory: selected,
              onChanged: (category) => selected = category,
            ),
          ),
        ),
      );

      expect(
        find.byType(DropdownButtonFormField<IngredientCategory>),
        findsOneWidget,
      );

      await tester.tap(
        find.byType(DropdownButtonFormField<IngredientCategory>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('🥦 Produce').last);
      await tester.pumpAndSettle();

      expect(selected, IngredientCategory.produce);
    },
  );

  testWidgets('Shopping empty state fits a landscape phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(812, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();
    await db.clearAllData();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: ShoppingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Your list is empty'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.text('Add from Recipe'), findsOneWidget);
  });

  testWidgets('Import Recipe button enables for a normalized recipe URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const AddRecipeScreen(),
        ),
      ),
    );
    await tester.pump();

    GestureDetector importButton() => tester.widget<GestureDetector>(
      find.ancestor(
        of: find.text('Import Recipe'),
        matching: find.byType(GestureDetector),
      ),
    );

    expect(importButton().onTap, isNull);

    await tester.enterText(
      find.byType(TextField).first,
      'recipetineats.com/chicken-breast-recipe/',
    );
    await tester.pump();

    expect(importButton().onTap, isNotNull);
  });
}
