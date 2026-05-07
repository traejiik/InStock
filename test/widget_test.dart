import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/recipes/widgets/recipe_card.dart';
import 'package:instock/shared/widgets/category_picker.dart';

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
}
