import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';

void main() {
  group('AppController', () {
    late AppController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      controller = AppController(await LocalStore.create());
    });

    test('scaled recipe adjusts ingredient quantities', () {
      final recipe = controller.recipeById('recipe-2');

      final scaled = recipe.scaledTo(6);

      expect(scaled.servings, 6);
      expect(scaled.ingredients.first.quantity, closeTo(700, 0.01));
    });

    test('addOrMergeItem merges compatible grocery entries', () async {
      final before = controller.shoppingItems.length;

      await controller.addOrMergeItem(
        GroceryItem(
          id: 'manual-1',
          name: 'Bell pepper',
          normalizedName: normalizeName('Bell pepper'),
          category: AisleCategory.produce,
          quantity: 1,
          unit: IngredientUnit.item,
          checked: false,
          source: 'Manual add',
          pantryLinked: false,
        ),
      );

      expect(controller.shoppingItems.length, before);
      final item = controller.shoppingItems.firstWhere(
        (entry) => entry.normalizedName == normalizeName('Bell pepper'),
      );
      expect(item.quantity, 3);
    });

    test(
      'addRecipeIngredients with missingOnly skips covered pantry items',
      () async {
        final recipe = controller.recipeById('recipe-1');
        final before = controller.shoppingItems.length;

        await controller.addRecipeIngredients(recipe, missingOnly: true);

        expect(controller.shoppingItems.length, greaterThanOrEqualTo(before));
        expect(
          controller.shoppingItems.any(
            (item) => item.normalizedName == normalizeName('Lemon'),
          ),
          isFalse,
        );
      },
    );
  });
}
