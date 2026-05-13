import 'dart:convert';
import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import 'drift_database.dart';

const _kMigratedKey = 'instock_drift_migrated_v1';
const _kLegacyFridgeKey = 'fridge_state_v1';
const _kStateKey = 'instock_state_v1';

enum MigrationOutcome { freshInstall, migrated, alreadyDone }

class MigrationService {
  /// Checks SharedPreferences and performs the appropriate action:
  /// - [MigrationOutcome.freshInstall] — no legacy data; caller should seed.
  /// - [MigrationOutcome.migrated] — JSON data migrated into Drift.
  /// - [MigrationOutcome.alreadyDone] — flag was already set; nothing to do.
  static Future<MigrationOutcome> migrateIfNeeded(InStockDriftDb db) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_kMigratedKey) == true) {
      return MigrationOutcome.alreadyDone;
    }

    // Preserve legacy fridge_state_v1 → instock_state_v1 rename.
    if (prefs.containsKey(_kLegacyFridgeKey) &&
        !prefs.containsKey(_kStateKey)) {
      final legacyData = prefs.getString(_kLegacyFridgeKey);
      if (legacyData != null) {
        await prefs.setString(_kStateKey, legacyData);
      }
    }

    final raw = prefs.getString(_kStateKey);
    if (raw == null) {
      // No legacy data — fresh install; caller will seed.
      await prefs.setBool(_kMigratedKey, true);
      return MigrationOutcome.freshInstall;
    }

    try {
      final state = AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      await db.transaction(() async {
        // Insert in FK dependency order; insertOrIgnore is safe for re-runs.
        for (final ing in state.ingredients) {
          await db
              .into(db.ingredients)
              .insert(
                IngredientsCompanion.insert(
                  id: ing.id,
                  canonicalName: ing.canonicalName,
                  category: ing.category.name,
                  aliases: jsonEncode(ing.aliases),
                  createdAt: ing.createdAt.millisecondsSinceEpoch,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        for (final p in state.pantryItems) {
          await db
              .into(db.pantryItems)
              .insert(
                PantryItemsCompanion.insert(
                  id: p.id,
                  ingredientId: p.ingredientId,
                  quantity: p.quantity,
                  initialQuantity: p.initialQuantity,
                  unit: p.unit,
                  addedAt: p.addedAt.millisecondsSinceEpoch,
                  lastVerifiedAt: Value(
                    p.lastVerifiedAt?.millisecondsSinceEpoch,
                  ),
                  deletedAt: Value(p.deletedAt?.millisecondsSinceEpoch),
                  depletedAt: Value(p.depletedAt?.millisecondsSinceEpoch),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        for (final r in state.recipes) {
          await db
              .into(db.recipes)
              .insert(
                RecipesCompanion.insert(
                  id: r.id,
                  title: r.title,
                  emoji: r.emoji,
                  imageUrl: Value(r.imageUrl),
                  instructions: jsonEncode(r.instructions),
                  servings: r.servings,
                  cookMinutes: r.cookMinutes,
                  difficulty: r.difficulty,
                  sourceUrl: Value(r.sourceUrl),
                  notes: Value(r.notes),
                  tags: jsonEncode(r.tags),
                  createdAt: r.createdAt.millisecondsSinceEpoch,
                  updatedAt: r.updatedAt.millisecondsSinceEpoch,
                  deletedAt: Value(r.deletedAt?.millisecondsSinceEpoch),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        for (final ri in state.recipeIngredients) {
          await db
              .into(db.recipeIngredients)
              .insert(
                RecipeIngredientsCompanion.insert(
                  id: ri.id,
                  recipeId: ri.recipeId,
                  ingredientId: ri.ingredientId,
                  quantity: ri.quantity,
                  unit: ri.unit,
                  isOptional: ri.isOptional ? 1 : 0,
                  notes: Value(ri.notes),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        for (final s in state.shoppingItems) {
          await db
              .into(db.shoppingItems)
              .insert(
                ShoppingItemsCompanion.insert(
                  id: s.id,
                  ingredientId: s.ingredientId,
                  quantity: s.quantity,
                  unit: s.unit,
                  checked: s.checked ? 1 : 0,
                  sourceRecipeId: Value(s.sourceRecipeId),
                  addedAt: s.addedAt.millisecondsSinceEpoch,
                  updatedAt: s.updatedAt.millisecondsSinceEpoch,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      });
    } catch (_) {
      // Do not mark migrated if the transaction failed.
      return MigrationOutcome.migrated; // return without setting flag
    }

    await prefs.setBool(_kMigratedKey, true);
    return MigrationOutcome.migrated;
  }
}
