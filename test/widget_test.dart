import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/recipes/widgets/recipe_card.dart';

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
}
