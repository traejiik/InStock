import 'package:flutter_test/flutter_test.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/database/drift_database.dart';

void main() {
  test('placeholder', () {
    expect(2 + 2, 4);
  });

  group('updateRecipe', () {
    test('updates recipe fields and replaces ingredients', () async {
      final db = AppDatabase(db: InStockDriftDb.memory());
      await db.init();

      final id = db.saveRecipe(
        title: 'Original',
        servings: 2,
        cookMinutes: 10,
        difficulty: 'Easy',
        instructions: ['Step 1'],
        ingredients: [
          (
            name: 'Flour',
            quantity: 200.0,
            unit: 'g',
            isOptional: false,
            notes: null,
          ),
        ],
      );

      await db.updateRecipe(
        id: id,
        title: 'Updated',
        servings: 4,
        cookMinutes: 20,
        difficulty: 'Medium',
        instructions: ['Step A', 'Step B'],
        ingredients: [
          (
            name: 'Sugar',
            quantity: 100.0,
            unit: 'g',
            isOptional: false,
            notes: null,
          ),
        ],
      );

      final recipe = db.recipeById(id);
      expect(recipe?.title, 'Updated');
      expect(recipe?.servings, 4);
      expect(recipe?.cookMinutes, 20);
      expect(recipe?.instructions, ['Step A', 'Step B']);

      final ris = db.ingredientsForRecipe(id);
      expect(ris.length, 1);
      final ing = db.ingredientById(ris.first.ingredientId);
      expect(ing?.canonicalName, 'Sugar');
    });
  });
}
