import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:drift/drift.dart' show Value, countAll;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../../core/utils/unit_converter.dart';
import 'drift_database.dart';

const _uuid = Uuid();

// Canonical alias upgrades applied on every load so existing saves stay current.
const _aliasUpgrades = <String, List<String>>{
  'ing-chicken': [
    'chicken',
    'boneless chicken',
    'boneless chicken breast',
    'chicken fillet',
  ],
  'ing-garlic': ['garlic cloves', 'fresh garlic', 'minced garlic'],
  'ing-onion': ['onion', 'brown onion', 'white onion'],
  'ing-milk': ['milk', 'full fat milk', 'full cream milk'],
  'ing-rice': ['rice', 'basmati', 'long grain rice'],
};

class AppDatabase extends ChangeNotifier {
  final InStockDriftDb _db;
  AppState _state = AppState.empty;

  AppDatabase({InStockDriftDb? db}) : _db = db ?? InStockDriftDb();

  AppState get state => _state;

  // ─── Public accessors ────────────────────────────────────────────────────

  List<Ingredient> get ingredients => _state.ingredients;
  List<PantryItem> get pantryItems =>
      _state.pantryItems.where((p) => p.deletedAt == null).toList();
  List<Recipe> get recipes =>
      _state.recipes.where((r) => r.deletedAt == null).toList();
  List<RecipeIngredient> get recipeIngredients => _state.recipeIngredients;
  List<ShoppingItem> get shoppingItems => _state.shoppingItems;

  Ingredient? ingredientById(String id) =>
      _state.ingredients.where((i) => i.id == id).firstOrNull;

  Recipe? recipeById(String id) =>
      _state.recipes.where((r) => r.id == id).firstOrNull;

  List<RecipeIngredient> ingredientsForRecipe(String recipeId) =>
      _state.recipeIngredients.where((ri) => ri.recipeId == recipeId).toList();

  void deleteRecipe(String recipeId) {
    final updated = _state.recipes.map((r) {
      return r.id == recipeId ? r.copyWith(deletedAt: DateTime.now()) : r;
    }).toList();
    _update(_state.copyWith(recipes: updated));
  }

  Future<void> clearAllData() async {
    await _db.transaction(() async {
      await _db.delete(_db.shoppingItems).go();
      await _db.delete(_db.recipeIngredients).go();
      await _db.delete(_db.recipes).go();
      await _db.delete(_db.pantryItems).go();
      await _db.delete(_db.ingredients).go();
    });
    await _reload();
  }

  PantryItem? pantryItemForIngredient(String ingredientId) =>
      pantryItems.where((p) => p.ingredientId == ingredientId).firstOrNull;

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final hasData = await _hasAnyData();
    if (!hasData) {
      await _seed();
    }
    await _reload();
    await _applyAliasUpgrades();
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  Future<bool> _hasAnyData() async {
    final count = countAll();
    final row = await (_db.selectOnly(
      _db.ingredients,
    )..addColumns([count])).getSingle();
    return (row.read(count) ?? 0) > 0;
  }

  Future<void> _reload() async {
    final ingRows = await _db.select(_db.ingredients).get();
    final pantryRows = await _db.select(_db.pantryItems).get();
    final recipeRows = await _db.select(_db.recipes).get();
    final riRows = await _db.select(_db.recipeIngredients).get();
    final shoppingRows = await _db.select(_db.shoppingItems).get();

    _state = AppState(
      ingredients: ingRows.map(_mapIngredient).toList(),
      pantryItems: pantryRows.map(_mapPantryItem).toList(),
      recipes: recipeRows.map(_mapRecipe).toList(),
      recipeIngredients: riRows.map(_mapRecipeIngredient).toList(),
      shoppingItems: shoppingRows.map(_mapShoppingItem).toList(),
    );
    notifyListeners();
  }

  void _update(AppState next) {
    _state = next;
    notifyListeners();
    unawaited(_persistFullState());
  }

  Future<void> _persistFullState() async {
    try {
      final snapshot = _state;
      await _db.transaction(() async {
        for (final ing in snapshot.ingredients) {
          await _db
              .into(_db.ingredients)
              .insertOnConflictUpdate(_ingredientCompanion(ing));
        }
        for (final p in snapshot.pantryItems) {
          await _db
              .into(_db.pantryItems)
              .insertOnConflictUpdate(_pantryItemCompanion(p));
        }
        for (final r in snapshot.recipes) {
          await _db
              .into(_db.recipes)
              .insertOnConflictUpdate(_recipeCompanion(r));
        }
        for (final ri in snapshot.recipeIngredients) {
          await _db
              .into(_db.recipeIngredients)
              .insertOnConflictUpdate(_recipeIngredientCompanion(ri));
        }
        for (final s in snapshot.shoppingItems) {
          await _db
              .into(_db.shoppingItems)
              .insertOnConflictUpdate(_shoppingItemCompanion(s));
        }
      });
    } catch (e) {
      debugPrint('[AppDatabase] persist error: $e');
    }
  }

  Future<void> _applyAliasUpgrades() async {
    bool changed = false;
    final updated = _state.ingredients.map((ing) {
      final upgrade = _aliasUpgrades[ing.id];
      if (upgrade == null) return ing;
      final current = Set<String>.from(ing.aliases);
      final target = Set<String>.from(upgrade);
      if (target.difference(current).isEmpty) return ing;
      changed = true;
      return Ingredient(
        id: ing.id,
        canonicalName: ing.canonicalName,
        category: ing.category,
        aliases: upgrade,
        createdAt: ing.createdAt,
      );
    }).toList();
    if (changed) {
      await _db.transaction(() async {
        for (final ing in updated) {
          await _db
              .into(_db.ingredients)
              .insertOnConflictUpdate(_ingredientCompanion(ing));
        }
      });
      await _reload();
    }
  }

  // ─── Ingredient matching ──────────────────────────────────────────────────

  // Finds an existing ingredient by canonical name or alias (case-insensitive),
  // or creates a new one if no match exists.
  Ingredient findOrCreateIngredient(
    String name, {
    IngredientCategory category = IngredientCategory.custom,
  }) {
    final normalized = name.trim().toLowerCase();
    final canonicalName = _normalizeEntryName(name);
    final byCanonical = _state.ingredients
        .where((i) => i.canonicalName.toLowerCase() == normalized)
        .firstOrNull;
    if (byCanonical != null) {
      return _withSelectedCategory(byCanonical, category);
    }

    final byAlias = _state.ingredients
        .where((i) => i.aliases.any((a) => a.toLowerCase() == normalized))
        .firstOrNull;
    if (byAlias != null) {
      return _withSelectedCategory(byAlias, category);
    }

    final newIng = Ingredient(
      id: 'ing-${normalized.replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}',
      canonicalName: canonicalName,
      category: category,
      aliases: [],
      createdAt: DateTime.now(),
    );
    _update(_state.copyWith(ingredients: [..._state.ingredients, newIng]));
    return newIng;
  }

  Ingredient _withSelectedCategory(
    Ingredient ingredient,
    IngredientCategory selectedCategory,
  ) {
    if (ingredient.category != IngredientCategory.custom ||
        selectedCategory == IngredientCategory.custom) {
      return ingredient;
    }

    final updated = Ingredient(
      id: ingredient.id,
      canonicalName: ingredient.canonicalName,
      category: selectedCategory,
      aliases: ingredient.aliases,
      createdAt: ingredient.createdAt,
    );
    final ingredients = _state.ingredients
        .map((i) => i.id == ingredient.id ? updated : i)
        .toList();
    _update(_state.copyWith(ingredients: ingredients));
    return updated;
  }

  static String _normalizeEntryName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  // ─── Shopping mutations ───────────────────────────────────────────────────

  void toggleShoppingItem(String id) {
    final now = DateTime.now();
    final items = _state.shoppingItems.map((item) {
      if (item.id != id) return item;
      final toggled = item.copyWith(checked: !item.checked, updatedAt: now);
      if (toggled.checked) {
        _addOrIncrementPantryInternal(
          toggled.ingredientId,
          toggled.quantity,
          toggled.unit,
        );
      }
      return toggled;
    }).toList();
    _update(_state.copyWith(shoppingItems: items));
  }

  void addShoppingItem({
    required String ingredientId,
    required double quantity,
    required String unit,
    String? sourceRecipeId,
  }) {
    final now = DateTime.now();
    final item = ShoppingItem(
      id: _uuid.v4(),
      ingredientId: ingredientId,
      quantity: quantity,
      unit: unit,
      checked: false,
      sourceRecipeId: sourceRecipeId,
      addedAt: now,
      updatedAt: now,
    );
    _update(_state.copyWith(shoppingItems: [..._state.shoppingItems, item]));
  }

  // Adds missing recipe ingredients to the shopping list. Returns the number of
  // items added or incremented. Existing unchecked items are incremented rather
  // than duplicated. Quantity is scaled to the requested servings count.
  int addMissingToShopping(String recipeId, int servings) {
    final recipe = recipeById(recipeId);
    if (recipe == null) return 0;
    final ingredients = ingredientsForRecipe(recipeId);
    final now = DateTime.now();
    int added = 0;
    var state = _state;

    for (final ri in ingredients) {
      if (ri.isOptional) continue;
      final status = _matchStatus(ri.ingredientId, ri.quantity, ri.unit);
      if (status == PantryMatchStatus.missing ||
          status == PantryMatchStatus.partial) {
        final scaledQty = UnitConverter.scaleQuantity(
          ri.quantity,
          recipe.servings,
          servings,
        );
        final existingIdx = state.shoppingItems.indexWhere(
          (s) => s.ingredientId == ri.ingredientId && !s.checked,
        );
        if (existingIdx != -1) {
          final existing = state.shoppingItems[existingIdx];
          final updated = ShoppingItem(
            id: existing.id,
            ingredientId: existing.ingredientId,
            quantity: existing.quantity + scaledQty,
            unit: existing.unit,
            checked: false,
            sourceRecipeId: existing.sourceRecipeId,
            addedAt: existing.addedAt,
            updatedAt: now,
          );
          final items = List<ShoppingItem>.from(state.shoppingItems);
          items[existingIdx] = updated;
          state = state.copyWith(shoppingItems: items);
        } else {
          final item = ShoppingItem(
            id: _uuid.v4(),
            ingredientId: ri.ingredientId,
            quantity: scaledQty,
            unit: ri.unit,
            checked: false,
            sourceRecipeId: recipeId,
            addedAt: now,
            updatedAt: now,
          );
          state = state.copyWith(shoppingItems: [...state.shoppingItems, item]);
        }
        added++;
      }
    }

    if (added > 0) _update(state);
    return added;
  }

  // Adds a shopping item, or increments the quantity of an existing unchecked
  // item for the same ingredient rather than creating a duplicate row.
  void addOrIncrementShopping({
    required String ingredientId,
    required double quantity,
    required String unit,
    String? sourceRecipeId,
  }) {
    final now = DateTime.now();
    final existingIdx = _state.shoppingItems.indexWhere(
      (s) => s.ingredientId == ingredientId && !s.checked,
    );
    if (existingIdx != -1) {
      final existing = _state.shoppingItems[existingIdx];
      final items = List<ShoppingItem>.from(_state.shoppingItems);
      items[existingIdx] = ShoppingItem(
        id: existing.id,
        ingredientId: existing.ingredientId,
        quantity: existing.quantity + quantity,
        unit: existing.unit,
        checked: false,
        sourceRecipeId: existing.sourceRecipeId,
        addedAt: existing.addedAt,
        updatedAt: now,
      );
      _update(_state.copyWith(shoppingItems: items));
    } else {
      addShoppingItem(
        ingredientId: ingredientId,
        quantity: quantity,
        unit: unit,
        sourceRecipeId: sourceRecipeId,
      );
    }
  }

  // ─── Pantry mutations ─────────────────────────────────────────────────────

  void _addOrIncrementPantryInternal(
    String ingredientId,
    double qty,
    String unit,
  ) {
    final existing = pantryItemForIngredient(ingredientId);
    if (existing != null) {
      final newQty = existing.quantity + qty;
      final updated = existing.copyWith(
        quantity: newQty,
        lastVerifiedAt: DateTime.now(),
        depletedAt: newQty > 0 ? null : existing.depletedAt,
      );
      final items = _state.pantryItems
          .map((p) => p.id == existing.id ? updated : p)
          .toList();
      _state = _state.copyWith(pantryItems: items);
    } else {
      final item = PantryItem(
        id: _uuid.v4(),
        ingredientId: ingredientId,
        quantity: qty,
        initialQuantity: qty,
        unit: unit,
        addedAt: DateTime.now(),
        lastVerifiedAt: DateTime.now(),
      );
      _state = _state.copyWith(pantryItems: [..._state.pantryItems, item]);
    }
  }

  void addOrIncrementPantry(String ingredientId, double qty, String unit) {
    _addOrIncrementPantryInternal(ingredientId, qty, unit);
    _update(_state);
  }

  void updatePantryQuantity(String pantryItemId, double newQty) {
    final clamped = newQty.clamp(0.0, double.infinity);
    final now = DateTime.now();
    final items = _state.pantryItems.map((p) {
      if (p.id != pantryItemId) return p;
      return p.copyWith(
        quantity: clamped,
        initialQuantity: clamped > p.initialQuantity
            ? clamped
            : p.initialQuantity,
        lastVerifiedAt: now,
        depletedAt: clamped == 0 ? (p.depletedAt ?? now) : p.depletedAt,
      );
    }).toList();
    _update(_state.copyWith(pantryItems: items));
  }

  void markPantryItemOut(String pantryItemId) {
    final now = DateTime.now();
    final items = _state.pantryItems.map((p) {
      if (p.id != pantryItemId) return p;
      return p.copyWith(
        quantity: 0,
        lastVerifiedAt: now,
        depletedAt: p.depletedAt ?? now,
      );
    }).toList();
    _update(_state.copyWith(pantryItems: items));
  }

  void markPantryItemVerified(String pantryItemId) {
    final items = _state.pantryItems.map((p) {
      if (p.id != pantryItemId) return p;
      return p.copyWith(lastVerifiedAt: DateTime.now());
    }).toList();
    _update(_state.copyWith(pantryItems: items));
  }

  void debugResetVerification() {
    if (!kDebugMode) return;
    final staleDate = DateTime.now().subtract(const Duration(days: 14));
    final items = _state.pantryItems
        .map((p) => p.copyWith(lastVerifiedAt: staleDate))
        .toList();
    _update(_state.copyWith(pantryItems: items));
  }

  void decrementPantryForRecipe(String recipeId, int servingsCooked) {
    final recipeIngrs = ingredientsForRecipe(recipeId);
    final recipe = recipeById(recipeId);
    if (recipe == null) return;
    final now = DateTime.now();

    var pantry = List<PantryItem>.from(_state.pantryItems);
    for (final ri in recipeIngrs) {
      if (ri.isOptional) continue;
      final scaledQty = ri.quantity * servingsCooked / recipe.servings;
      final idx = pantry.indexWhere(
        (p) => p.ingredientId == ri.ingredientId && p.deletedAt == null,
      );
      if (idx == -1) continue;
      final newQty = (pantry[idx].quantity - scaledQty).clamp(
        0.0,
        double.infinity,
      );
      pantry[idx] = pantry[idx].copyWith(
        quantity: newQty,
        lastVerifiedAt: now,
        depletedAt: newQty == 0
            ? (pantry[idx].depletedAt ?? now)
            : pantry[idx].depletedAt,
      );
    }
    _update(_state.copyWith(pantryItems: pantry));
  }

  // ─── Pantry match helpers ─────────────────────────────────────────────────

  PantryMatchStatus _matchStatus(
    String ingredientId,
    double required,
    String unit,
  ) {
    final pantry = pantryItemForIngredient(ingredientId);
    if (pantry == null) return PantryMatchStatus.missing;
    final status = UnitConverter.calculateStockStatus(
      pantry.quantity,
      pantry.unit,
      required,
      unit,
    );
    return switch (status) {
      StockStatus.inStock => PantryMatchStatus.enough,
      StockStatus.low => PantryMatchStatus.partial,
      StockStatus.need => PantryMatchStatus.missing,
    };
  }

  PantryMatchStatus matchStatus(
    String ingredientId,
    double required,
    String unit,
  ) => _matchStatus(ingredientId, required, unit);

  bool isRecipeMakeable(String recipeId) {
    final ingredients = ingredientsForRecipe(
      recipeId,
    ).where((ri) => !ri.isOptional);
    return ingredients.every(
      (ri) =>
          _matchStatus(ri.ingredientId, ri.quantity, ri.unit) ==
          PantryMatchStatus.enough,
    );
  }

  int missingCountForRecipe(String recipeId) {
    return ingredientsForRecipe(recipeId)
        .where((ri) => !ri.isOptional)
        .where(
          (ri) =>
              _matchStatus(ri.ingredientId, ri.quantity, ri.unit) !=
              PantryMatchStatus.enough,
        )
        .length;
  }

  StockStatus stockStatusForIngredient(String ingredientId) {
    final pantry = pantryItemForIngredient(ingredientId);
    if (pantry == null || pantry.quantity == 0) return StockStatus.need;
    if (pantry.fillLevel < 0.25) return StockStatus.low;
    return StockStatus.inStock;
  }

  // Returns the canonical name of the first non-optional ingredient that is
  // absent or zeroed out in the pantry, or null if everything is present.
  String? firstMissingNonOptional(String recipeId) {
    for (final ri in ingredientsForRecipe(recipeId)) {
      if (ri.isOptional) continue;
      final pantry = pantryItemForIngredient(ri.ingredientId);
      if (pantry == null || pantry.quantity == 0) {
        return ingredientById(ri.ingredientId)?.canonicalName ??
            'an ingredient';
      }
    }
    return null;
  }

  bool get needsVerification {
    final cutoff = DateTime.now().subtract(const Duration(days: 10));
    return pantryItems.any(
      (p) => p.lastVerifiedAt == null || p.lastVerifiedAt!.isBefore(cutoff),
    );
  }

  List<PantryItem> get unverifiedItems {
    final cutoff = DateTime.now().subtract(const Duration(days: 10));
    return pantryItems
        .where(
          (p) => p.lastVerifiedAt == null || p.lastVerifiedAt!.isBefore(cutoff),
        )
        .toList();
  }

  // ─── Recipe mutations ────────────────────────────────────────────────────

  String saveRecipe({
    required String title,
    required int servings,
    required int cookMinutes,
    required String difficulty,
    required List<String> instructions,
    required List<
      ({
        String name,
        double quantity,
        String unit,
        bool isOptional,
        String? notes,
      })
    >
    ingredients,
    String? sourceUrl,
    String? imageUrl,
    String? notes,
    String? emoji,
  }) {
    final now = DateTime.now();
    final recipeId = _uuid.v4();
    var workingState = _state;

    final newRecipeIngredients = <RecipeIngredient>[];
    for (final ing in ingredients) {
      final normalized = ing.name.trim().toLowerCase();
      var ingredient = workingState.ingredients.where((i) {
        return i.canonicalName.toLowerCase() == normalized ||
            i.aliases.any((a) => a.toLowerCase() == normalized);
      }).firstOrNull;

      if (ingredient == null) {
        ingredient = Ingredient(
          id: 'ing-${normalized.replaceAll(' ', '-')}-${now.millisecondsSinceEpoch}',
          canonicalName: ing.name.trim(),
          category: IngredientCategory.custom,
          aliases: [],
          createdAt: now,
        );
        workingState = workingState.copyWith(
          ingredients: [...workingState.ingredients, ingredient],
        );
      }

      newRecipeIngredients.add(
        RecipeIngredient(
          id: _uuid.v4(),
          recipeId: recipeId,
          ingredientId: ingredient.id,
          quantity: ing.quantity,
          unit: ing.unit,
          isOptional: ing.isOptional,
          notes: ing.notes,
        ),
      );
    }

    final recipe = Recipe(
      id: recipeId,
      title: title,
      emoji: emoji ?? '🍽️',
      imageUrl: imageUrl,
      instructions: instructions,
      servings: servings,
      cookMinutes: cookMinutes,
      difficulty: difficulty,
      sourceUrl: sourceUrl,
      notes: notes,
      tags: [],
      createdAt: now,
      updatedAt: now,
    );

    _update(
      workingState.copyWith(
        recipes: [...workingState.recipes, recipe],
        recipeIngredients: [
          ...workingState.recipeIngredients,
          ...newRecipeIngredients,
        ],
      ),
    );

    return recipeId;
  }

  // ─── Seed ─────────────────────────────────────────────────────────────────

  Future<void> _seed() async {
    final now = DateTime.now();

    const iMilk = 'ing-milk';
    const iYogurt = 'ing-yogurt';
    const iGarlic = 'ing-garlic';
    const iOnion = 'ing-onion';
    const iRice = 'ing-rice';
    const iEggs = 'ing-eggs';
    const iPassata = 'ing-passata';
    const iGaram = 'ing-garam';
    const iParmesan = 'ing-parmesan';
    const iChicken = 'ing-chicken';
    const iSalmon = 'ing-salmon';
    const iCream = 'ing-cream';
    const iPanko = 'ing-panko';
    const iButter = 'ing-butter';
    const iPasta = 'ing-pasta';
    const iRamen = 'ing-ramen';
    const iSoy = 'ing-soy';
    const iMiso = 'ing-miso';
    const iGreens = 'ing-greens';
    const iSesame = 'ing-sesame';
    const iBroccoli = 'ing-broccoli';
    const iTeriyaki = 'ing-teriyaki';

    const rButterChicken = 'rec-butter-chicken';
    const rRamen = 'rec-ramen';
    const rSalad = 'rec-asian-salad';
    const rCarbonara = 'rec-carbonara';
    const rTeriyaki = 'rec-teriyaki';

    final ingredients = [
      Ingredient(
        id: iMilk,
        canonicalName: 'Whole Milk',
        category: IngredientCategory.dairy,
        aliases: ['milk', 'full fat milk', 'full cream milk'],
        createdAt: now,
      ),
      Ingredient(
        id: iYogurt,
        canonicalName: 'Greek Yogurt',
        category: IngredientCategory.dairy,
        aliases: ['yogurt'],
        createdAt: now,
      ),
      Ingredient(
        id: iGarlic,
        canonicalName: 'Garlic',
        category: IngredientCategory.produce,
        aliases: ['garlic cloves', 'fresh garlic', 'minced garlic'],
        createdAt: now,
      ),
      Ingredient(
        id: iOnion,
        canonicalName: 'Yellow Onion',
        category: IngredientCategory.produce,
        aliases: ['onion', 'brown onion', 'white onion'],
        createdAt: now,
      ),
      Ingredient(
        id: iRice,
        canonicalName: 'Basmati Rice',
        category: IngredientCategory.grain,
        aliases: ['rice', 'basmati', 'long grain rice'],
        createdAt: now,
      ),
      Ingredient(
        id: iEggs,
        canonicalName: 'Eggs',
        category: IngredientCategory.produce,
        aliases: ['egg'],
        createdAt: now,
      ),
      Ingredient(
        id: iPassata,
        canonicalName: 'Tomato Passata',
        category: IngredientCategory.produce,
        aliases: ['passata', 'tomato sauce'],
        createdAt: now,
      ),
      Ingredient(
        id: iGaram,
        canonicalName: 'Garam Masala',
        category: IngredientCategory.spice,
        aliases: ['garam masala spice'],
        createdAt: now,
      ),
      Ingredient(
        id: iParmesan,
        canonicalName: 'Parmesan',
        category: IngredientCategory.dairy,
        aliases: ['parmigiano'],
        createdAt: now,
      ),
      Ingredient(
        id: iChicken,
        canonicalName: 'Chicken Breast',
        category: IngredientCategory.meat,
        aliases: [
          'chicken',
          'boneless chicken',
          'boneless chicken breast',
          'chicken fillet',
        ],
        createdAt: now,
      ),
      Ingredient(
        id: iSalmon,
        canonicalName: 'Salmon Fillet',
        category: IngredientCategory.meat,
        aliases: ['salmon'],
        createdAt: now,
      ),
      Ingredient(
        id: iCream,
        canonicalName: 'Heavy Cream',
        category: IngredientCategory.dairy,
        aliases: ['cream', 'double cream'],
        createdAt: now,
      ),
      Ingredient(
        id: iPanko,
        canonicalName: 'Panko Breadcrumbs',
        category: IngredientCategory.grain,
        aliases: ['breadcrumbs', 'panko'],
        createdAt: now,
      ),
      Ingredient(
        id: iButter,
        canonicalName: 'Butter',
        category: IngredientCategory.dairy,
        aliases: [],
        createdAt: now,
      ),
      Ingredient(
        id: iPasta,
        canonicalName: 'Spaghetti',
        category: IngredientCategory.grain,
        aliases: ['pasta', 'spaghetti'],
        createdAt: now,
      ),
      Ingredient(
        id: iRamen,
        canonicalName: 'Ramen Noodles',
        category: IngredientCategory.grain,
        aliases: ['noodles'],
        createdAt: now,
      ),
      Ingredient(
        id: iSoy,
        canonicalName: 'Soy Sauce',
        category: IngredientCategory.spice,
        aliases: ['soy'],
        createdAt: now,
      ),
      Ingredient(
        id: iMiso,
        canonicalName: 'Miso Paste',
        category: IngredientCategory.spice,
        aliases: ['miso'],
        createdAt: now,
      ),
      Ingredient(
        id: iGreens,
        canonicalName: 'Mixed Greens',
        category: IngredientCategory.produce,
        aliases: ['salad leaves', 'greens'],
        createdAt: now,
      ),
      Ingredient(
        id: iSesame,
        canonicalName: 'Sesame Seeds',
        category: IngredientCategory.spice,
        aliases: ['sesame'],
        createdAt: now,
      ),
      Ingredient(
        id: iBroccoli,
        canonicalName: 'Broccoli',
        category: IngredientCategory.produce,
        aliases: [],
        createdAt: now,
      ),
      Ingredient(
        id: iTeriyaki,
        canonicalName: 'Teriyaki Sauce',
        category: IngredientCategory.spice,
        aliases: ['teriyaki'],
        createdAt: now,
      ),
    ];

    final pantryItems = [
      PantryItem(
        id: 'p-milk',
        ingredientId: iMilk,
        quantity: 1.5,
        initialQuantity: 2.0,
        unit: 'L',
        addedAt: now.subtract(const Duration(days: 3)),
      ),
      PantryItem(
        id: 'p-yogurt',
        ingredientId: iYogurt,
        quantity: 80,
        initialQuantity: 500,
        unit: 'g',
        addedAt: now.subtract(const Duration(days: 5)),
      ),
      PantryItem(
        id: 'p-garlic',
        ingredientId: iGarlic,
        quantity: 6,
        initialQuantity: 6,
        unit: 'cloves',
        addedAt: now.subtract(const Duration(days: 2)),
      ),
      PantryItem(
        id: 'p-onion',
        ingredientId: iOnion,
        quantity: 3,
        initialQuantity: 5,
        unit: 'pcs',
        addedAt: now.subtract(const Duration(days: 4)),
      ),
      PantryItem(
        id: 'p-rice',
        ingredientId: iRice,
        quantity: 800,
        initialQuantity: 1000,
        unit: 'g',
        addedAt: now.subtract(const Duration(days: 1)),
      ),
      PantryItem(
        id: 'p-eggs',
        ingredientId: iEggs,
        quantity: 12,
        initialQuantity: 12,
        unit: 'pcs',
        addedAt: now.subtract(const Duration(days: 1)),
      ),
      PantryItem(
        id: 'p-passata',
        ingredientId: iPassata,
        quantity: 400,
        initialQuantity: 400,
        unit: 'g',
        addedAt: now.subtract(const Duration(days: 7)),
      ),
      PantryItem(
        id: 'p-garam',
        ingredientId: iGaram,
        quantity: 1,
        initialQuantity: 1,
        unit: 'jar',
        addedAt: now.subtract(const Duration(days: 14)),
      ),
      PantryItem(
        id: 'p-parmesan',
        ingredientId: iParmesan,
        quantity: 150,
        initialQuantity: 200,
        unit: 'g',
        addedAt: now.subtract(const Duration(days: 3)),
      ),
      PantryItem(
        id: 'p-soy',
        ingredientId: iSoy,
        quantity: 1,
        initialQuantity: 1,
        unit: 'bottle',
        addedAt: now.subtract(const Duration(days: 10)),
      ),
      PantryItem(
        id: 'p-miso',
        ingredientId: iMiso,
        quantity: 1,
        initialQuantity: 1,
        unit: 'jar',
        addedAt: now.subtract(const Duration(days: 10)),
      ),
      PantryItem(
        id: 'p-ramen',
        ingredientId: iRamen,
        quantity: 400,
        initialQuantity: 400,
        unit: 'g',
        addedAt: now.subtract(const Duration(days: 10)),
      ),
      PantryItem(
        id: 'p-butter',
        ingredientId: iButter,
        quantity: 200,
        initialQuantity: 250,
        unit: 'g',
        addedAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    final recipes = [
      Recipe(
        id: rButterChicken,
        title: 'Butter Chicken',
        emoji: '🍛',
        instructions: [
          'Marinate chicken in yogurt, garlic, and garam masala for 30 minutes.',
          'Sear chicken pieces in butter until golden.',
          'Sauté onion until soft, add garlic and garam masala.',
          'Add passata and simmer for 10 minutes.',
          'Stir in cream and return chicken to pan.',
          'Simmer 15 minutes until sauce thickens. Serve over basmati rice.',
        ],
        servings: 4,
        cookMinutes: 45,
        difficulty: 'Medium',
        tags: ['dinner', 'indian'],
        createdAt: now,
        updatedAt: now,
      ),
      Recipe(
        id: rRamen,
        title: 'Ramen Bowl',
        emoji: '🍜',
        instructions: [
          'Bring broth to a boil with miso paste and soy sauce.',
          'Cook ramen noodles according to package instructions.',
          'Soft-boil eggs for 6.5 minutes, peel and halve.',
          'Divide noodles into bowls, ladle broth over.',
          'Top with soft-boiled egg and spring onions.',
        ],
        servings: 2,
        cookMinutes: 30,
        difficulty: 'Easy',
        tags: ['dinner', 'asian'],
        createdAt: now,
        updatedAt: now,
      ),
      Recipe(
        id: rSalad,
        title: 'Asian Salad',
        emoji: '🥗',
        instructions: [
          'Whisk together soy sauce, sesame oil and a pinch of sugar.',
          'Toss mixed greens with the dressing.',
          'Top with sesame seeds and serve immediately.',
        ],
        servings: 2,
        cookMinutes: 15,
        difficulty: 'Easy',
        tags: ['lunch', 'asian', 'vegetarian'],
        createdAt: now,
        updatedAt: now,
      ),
      Recipe(
        id: rCarbonara,
        title: 'Carbonara',
        emoji: '🍝',
        instructions: [
          'Cook spaghetti in well-salted boiling water until al dente.',
          'Fry guanciale or pancetta until crispy.',
          'Whisk eggs with grated parmesan.',
          'Toss hot pasta off heat with egg mixture and pancetta.',
          'Add pasta water to achieve a silky sauce. Season generously.',
        ],
        servings: 2,
        cookMinutes: 25,
        difficulty: 'Medium',
        tags: ['dinner', 'italian'],
        createdAt: now,
        updatedAt: now,
      ),
      Recipe(
        id: rTeriyaki,
        title: 'Teriyaki Bowl',
        emoji: '🍱',
        instructions: [
          'Marinate salmon in teriyaki sauce for 15 minutes.',
          'Cook rice according to package instructions.',
          'Steam or roast broccoli until tender.',
          'Sear salmon in a hot pan for 3–4 minutes each side.',
          'Serve salmon over rice with broccoli.',
        ],
        servings: 2,
        cookMinutes: 20,
        difficulty: 'Easy',
        tags: ['dinner', 'asian'],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final recipeIngredients = [
      // Butter Chicken
      const RecipeIngredient(
        id: 'ri-bc-1',
        recipeId: rButterChicken,
        ingredientId: iChicken,
        quantity: 600,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-bc-2',
        recipeId: rButterChicken,
        ingredientId: iButter,
        quantity: 50,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-bc-3',
        recipeId: rButterChicken,
        ingredientId: iGarlic,
        quantity: 4,
        unit: 'cloves',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-bc-4',
        recipeId: rButterChicken,
        ingredientId: iOnion,
        quantity: 1,
        unit: 'pcs',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-bc-5',
        recipeId: rButterChicken,
        ingredientId: iPassata,
        quantity: 400,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-bc-6',
        recipeId: rButterChicken,
        ingredientId: iCream,
        quantity: 200,
        unit: 'ml',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-bc-7',
        recipeId: rButterChicken,
        ingredientId: iGaram,
        quantity: 2,
        unit: 'tbsp',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-bc-8',
        recipeId: rButterChicken,
        ingredientId: iRice,
        quantity: 300,
        unit: 'g',
        isOptional: false,
      ),
      // Ramen
      const RecipeIngredient(
        id: 'ri-rm-1',
        recipeId: rRamen,
        ingredientId: iRamen,
        quantity: 200,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-rm-2',
        recipeId: rRamen,
        ingredientId: iEggs,
        quantity: 2,
        unit: 'pcs',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-rm-3',
        recipeId: rRamen,
        ingredientId: iSoy,
        quantity: 3,
        unit: 'tbsp',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-rm-4',
        recipeId: rRamen,
        ingredientId: iMiso,
        quantity: 2,
        unit: 'tbsp',
        isOptional: false,
      ),
      // Asian Salad
      const RecipeIngredient(
        id: 'ri-as-1',
        recipeId: rSalad,
        ingredientId: iGreens,
        quantity: 100,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-as-2',
        recipeId: rSalad,
        ingredientId: iSesame,
        quantity: 1,
        unit: 'tbsp',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-as-3',
        recipeId: rSalad,
        ingredientId: iSoy,
        quantity: 2,
        unit: 'tbsp',
        isOptional: false,
      ),
      // Carbonara
      const RecipeIngredient(
        id: 'ri-ca-1',
        recipeId: rCarbonara,
        ingredientId: iPasta,
        quantity: 200,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-ca-2',
        recipeId: rCarbonara,
        ingredientId: iEggs,
        quantity: 3,
        unit: 'pcs',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-ca-3',
        recipeId: rCarbonara,
        ingredientId: iParmesan,
        quantity: 80,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-ca-4',
        recipeId: rCarbonara,
        ingredientId: iButter,
        quantity: 30,
        unit: 'g',
        isOptional: true,
      ),
      // Teriyaki Bowl
      const RecipeIngredient(
        id: 'ri-te-1',
        recipeId: rTeriyaki,
        ingredientId: iSalmon,
        quantity: 2,
        unit: 'pcs',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-te-2',
        recipeId: rTeriyaki,
        ingredientId: iRice,
        quantity: 200,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-te-3',
        recipeId: rTeriyaki,
        ingredientId: iBroccoli,
        quantity: 150,
        unit: 'g',
        isOptional: false,
      ),
      const RecipeIngredient(
        id: 'ri-te-4',
        recipeId: rTeriyaki,
        ingredientId: iTeriyaki,
        quantity: 4,
        unit: 'tbsp',
        isOptional: false,
      ),
    ];

    final shoppingItems = [
      ShoppingItem(
        id: 'shop-1',
        ingredientId: iChicken,
        quantity: 600,
        unit: 'g',
        checked: false,
        sourceRecipeId: rButterChicken,
        addedAt: now,
        updatedAt: now,
      ),
      ShoppingItem(
        id: 'shop-2',
        ingredientId: iSalmon,
        quantity: 2,
        unit: 'pcs',
        checked: false,
        sourceRecipeId: rTeriyaki,
        addedAt: now,
        updatedAt: now,
      ),
      ShoppingItem(
        id: 'shop-3',
        ingredientId: iCream,
        quantity: 200,
        unit: 'ml',
        checked: false,
        addedAt: now,
        updatedAt: now,
      ),
      ShoppingItem(
        id: 'shop-4',
        ingredientId: iPanko,
        quantity: 1,
        unit: 'bag',
        checked: false,
        addedAt: now,
        updatedAt: now,
      ),
    ];

    await _db.transaction(() async {
      for (final ing in ingredients) {
        await _db
            .into(_db.ingredients)
            .insertOnConflictUpdate(_ingredientCompanion(ing));
      }
      for (final p in pantryItems) {
        await _db
            .into(_db.pantryItems)
            .insertOnConflictUpdate(_pantryItemCompanion(p));
      }
      for (final r in recipes) {
        await _db.into(_db.recipes).insertOnConflictUpdate(_recipeCompanion(r));
      }
      for (final ri in recipeIngredients) {
        await _db
            .into(_db.recipeIngredients)
            .insertOnConflictUpdate(_recipeIngredientCompanion(ri));
      }
      for (final s in shoppingItems) {
        await _db
            .into(_db.shoppingItems)
            .insertOnConflictUpdate(_shoppingItemCompanion(s));
      }
    });
  }

  // ─── Mappers: Drift rows → domain models ─────────────────────────────────

  static Ingredient _mapIngredient(IngredientData row) => Ingredient(
    id: row.id,
    canonicalName: row.canonicalName,
    category: IngredientCategory.values.firstWhere(
      (e) => e.name == row.category,
      orElse: () => IngredientCategory.custom,
    ),
    aliases: List<String>.from(jsonDecode(row.aliases) as List),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  static PantryItem _mapPantryItem(PantryItemData row) => PantryItem(
    id: row.id,
    ingredientId: row.ingredientId,
    quantity: row.quantity,
    initialQuantity: row.initialQuantity,
    unit: row.unit,
    addedAt: DateTime.fromMillisecondsSinceEpoch(row.addedAt),
    lastVerifiedAt: row.lastVerifiedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.lastVerifiedAt!)
        : null,
    deletedAt: row.deletedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
        : null,
    depletedAt: row.depletedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.depletedAt!)
        : null,
  );

  static Recipe _mapRecipe(RecipeData row) => Recipe(
    id: row.id,
    title: row.title,
    emoji: row.emoji,
    imageUrl: row.imageUrl,
    instructions: List<String>.from(jsonDecode(row.instructions) as List),
    servings: row.servings,
    cookMinutes: row.cookMinutes,
    difficulty: row.difficulty,
    sourceUrl: row.sourceUrl,
    notes: row.notes,
    tags: List<String>.from(jsonDecode(row.tags) as List),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    deletedAt: row.deletedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
        : null,
  );

  static RecipeIngredient _mapRecipeIngredient(RecipeIngredientData row) =>
      RecipeIngredient(
        id: row.id,
        recipeId: row.recipeId,
        ingredientId: row.ingredientId,
        quantity: row.quantity,
        unit: row.unit,
        isOptional: row.isOptional == 1,
        notes: row.notes,
      );

  static ShoppingItem _mapShoppingItem(ShoppingItemData row) => ShoppingItem(
    id: row.id,
    ingredientId: row.ingredientId,
    quantity: row.quantity,
    unit: row.unit,
    checked: row.checked == 1,
    sourceRecipeId: row.sourceRecipeId,
    addedAt: DateTime.fromMillisecondsSinceEpoch(row.addedAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  // ─── Companions: domain models → Drift ───────────────────────────────────

  static IngredientsCompanion _ingredientCompanion(Ingredient ing) =>
      IngredientsCompanion.insert(
        id: ing.id,
        canonicalName: ing.canonicalName,
        category: ing.category.name,
        aliases: jsonEncode(ing.aliases),
        createdAt: ing.createdAt.millisecondsSinceEpoch,
      );

  static PantryItemsCompanion _pantryItemCompanion(PantryItem p) =>
      PantryItemsCompanion.insert(
        id: p.id,
        ingredientId: p.ingredientId,
        quantity: p.quantity,
        initialQuantity: p.initialQuantity,
        unit: p.unit,
        addedAt: p.addedAt.millisecondsSinceEpoch,
        lastVerifiedAt: Value(p.lastVerifiedAt?.millisecondsSinceEpoch),
        deletedAt: Value(p.deletedAt?.millisecondsSinceEpoch),
        depletedAt: Value(p.depletedAt?.millisecondsSinceEpoch),
      );

  static RecipesCompanion _recipeCompanion(Recipe r) => RecipesCompanion.insert(
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
  );

  static RecipeIngredientsCompanion _recipeIngredientCompanion(
    RecipeIngredient ri,
  ) => RecipeIngredientsCompanion.insert(
    id: ri.id,
    recipeId: ri.recipeId,
    ingredientId: ri.ingredientId,
    quantity: ri.quantity,
    unit: ri.unit,
    isOptional: ri.isOptional ? 1 : 0,
    notes: Value(ri.notes),
  );

  static ShoppingItemsCompanion _shoppingItemCompanion(ShoppingItem s) =>
      ShoppingItemsCompanion.insert(
        id: s.id,
        ingredientId: s.ingredientId,
        quantity: s.quantity,
        unit: s.unit,
        checked: s.checked ? 1 : 0,
        sourceRecipeId: Value(s.sourceRecipeId),
        addedAt: s.addedAt.millisecondsSinceEpoch,
        updatedAt: s.updatedAt.millisecondsSinceEpoch,
      );
}
