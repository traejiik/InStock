import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/database/drift_database.dart';
import 'package:instock/data/models/app_models.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Pantry decrement', () {
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(db: InStockDriftDb.memory());
      await db.init(); // seeds with default data
    });

    // Carbonara (rec-carbonara, 2 servings):
    //   pasta  200g  non-optional  (not in pantry seed → skip)
    //   eggs   3 pcs non-optional  (pantry: 12 pcs)
    //   parmesan 80g non-optional  (pantry: 150g)
    //   butter 30g   optional      (pantry: 200g — must NOT be decremented)

    test('decrement by less than available → correct remainder', () {
      // eggs: 12 pcs in pantry, recipe needs 3 for 2 servings
      db.decrementPantryForRecipe('rec-carbonara', 2);
      final eggs = db.pantryItemForIngredient('ing-eggs');
      expect(eggs, isNotNull);
      expect(eggs!.quantity, closeTo(9.0, 0.001));
    });

    test('decrement by exact amount → quantity == 0 and depletedAt set', () {
      // Set parmesan to exactly 80g so it hits 0 after decrement
      final parmesan = db.pantryItems.firstWhere(
        (p) => p.ingredientId == 'ing-parmesan',
      );
      db.updatePantryQuantity(parmesan.id, 80.0);

      db.decrementPantryForRecipe('rec-carbonara', 2);

      final updated = db.pantryItemForIngredient('ing-parmesan');
      expect(updated!.quantity, 0.0);
      expect(updated.depletedAt, isNotNull);
    });

    test('decrement by more than available → quantity == 0, no negative', () {
      // Set eggs to 1 pcs; recipe needs 3 → would go negative without guard
      final eggs = db.pantryItems.firstWhere(
        (p) => p.ingredientId == 'ing-eggs',
      );
      db.updatePantryQuantity(eggs.id, 1.0);

      db.decrementPantryForRecipe('rec-carbonara', 2);

      final updated = db.pantryItemForIngredient('ing-eggs');
      expect(updated!.quantity, 0.0);
      expect(updated.quantity, greaterThanOrEqualTo(0.0));
      expect(updated.depletedAt, isNotNull);
    });

    test('optional ingredients are never decremented', () {
      // Butter is optional in Carbonara (ri-ca-4); quantity must stay at 200g
      final before = db.pantryItemForIngredient('ing-butter')!.quantity;

      db.decrementPantryForRecipe('rec-carbonara', 2);

      final after = db.pantryItemForIngredient('ing-butter')!.quantity;
      expect(after, closeTo(before, 0.001));
    });
  });

  group('Ingredient creation', () {
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(db: InStockDriftDb.memory());
      await db.init();
    });

    test('creates a new ingredient with the selected category', () {
      final ingredient = db.findOrCreateIngredient(
        'Kefir grains',
        category: IngredientCategory.dairy,
      );

      expect(ingredient.canonicalName, 'Kefir grains');
      expect(ingredient.category, IngredientCategory.dairy);
    });

    test(
      'updates an existing custom ingredient when a category is selected',
      () {
        final custom = db.findOrCreateIngredient('Tofu');
        expect(custom.category, IngredientCategory.custom);

        final categorized = db.findOrCreateIngredient(
          'Tofu',
          category: IngredientCategory.produce,
        );

        expect(categorized.id, custom.id);
        expect(categorized.category, IngredientCategory.produce);
      },
    );
  });
}
