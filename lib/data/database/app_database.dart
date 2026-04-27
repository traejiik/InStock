import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../../core/utils/unit_converter.dart';

const _kStateKey = 'fridge_state_v1';
const _uuid = Uuid();

// Canonical alias upgrades applied on every load so existing saves stay current.
const _aliasUpgrades = <String, List<String>>{
  'ing-chicken': ['chicken', 'boneless chicken', 'boneless chicken breast', 'chicken fillet'],
  'ing-garlic': ['garlic cloves', 'fresh garlic', 'minced garlic'],
  'ing-onion': ['onion', 'brown onion', 'white onion'],
  'ing-milk': ['milk', 'full fat milk', 'full cream milk'],
  'ing-rice': ['rice', 'basmati', 'long grain rice'],
};

class AppDatabase extends ChangeNotifier {
  AppState _state = AppState.empty;

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

  PantryItem? pantryItemForIngredient(String ingredientId) =>
      pantryItems.where((p) => p.ingredientId == ingredientId).firstOrNull;

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStateKey);
    if (raw != null) {
      try {
        _state = AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _applyMigrations();
      } catch (_) {
        await _seed(prefs);
      }
    } else {
      await _seed(prefs);
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStateKey, jsonEncode(_state.toJson()));
  }

  void _update(AppState next) {
    _state = next;
    notifyListeners();
    _save();
  }

  // Applies alias upgrades to existing persisted state so known synonyms stay current.
  void _applyMigrations() {
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
      _state = _state.copyWith(ingredients: updated);
      _save();
    }
  }

  // ─── Ingredient matching ──────────────────────────────────────────────────

  // Finds an existing ingredient by canonical name or alias (case-insensitive),
  // or creates a new one if no match exists.
  Ingredient findOrCreateIngredient(String name) {
    final normalized = name.trim().toLowerCase();
    final byCanonical = _state.ingredients.where(
      (i) => i.canonicalName.toLowerCase() == normalized,
    ).firstOrNull;
    if (byCanonical != null) return byCanonical;

    final byAlias = _state.ingredients.where(
      (i) => i.aliases.any((a) => a.toLowerCase() == normalized),
    ).firstOrNull;
    if (byAlias != null) return byAlias;

    final newIng = Ingredient(
      id: 'ing-${normalized.replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}',
      canonicalName: name.trim(),
      category: IngredientCategory.custom,
      aliases: [],
      createdAt: DateTime.now(),
    );
    _update(_state.copyWith(ingredients: [..._state.ingredients, newIng]));
    return newIng;
  }

  // ─── Shopping mutations ───────────────────────────────────────────────────

  void toggleShoppingItem(String id) {
    final now = DateTime.now();
    final items = _state.shoppingItems.map((item) {
      if (item.id != id) return item;
      final toggled = item.copyWith(checked: !item.checked, updatedAt: now);
      if (toggled.checked) _addOrIncrementPantryInternal(toggled.ingredientId, toggled.quantity, toggled.unit);
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
      if (status == PantryMatchStatus.missing || status == PantryMatchStatus.partial) {
        final scaledQty = UnitConverter.scaleQuantity(ri.quantity, recipe.servings, servings);
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

  // ─── Pantry mutations ─────────────────────────────────────────────────────

  void _addOrIncrementPantryInternal(String ingredientId, double qty, String unit) {
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
        initialQuantity: clamped > p.initialQuantity ? clamped : p.initialQuantity,
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
      return p.copyWith(quantity: 0, lastVerifiedAt: now, depletedAt: p.depletedAt ?? now);
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
      final newQty = (pantry[idx].quantity - scaledQty).clamp(0.0, double.infinity);
      pantry[idx] = pantry[idx].copyWith(
        quantity: newQty,
        lastVerifiedAt: now,
        depletedAt: newQty == 0 ? (pantry[idx].depletedAt ?? now) : pantry[idx].depletedAt,
      );
    }
    _update(_state.copyWith(pantryItems: pantry));
  }

  // ─── Pantry match helpers ─────────────────────────────────────────────────

  PantryMatchStatus _matchStatus(String ingredientId, double required, String unit) {
    final pantry = pantryItemForIngredient(ingredientId);
    if (pantry == null) return PantryMatchStatus.missing;
    final status = UnitConverter.calculateStockStatus(
      pantry.quantity, pantry.unit, required, unit,
    );
    return switch (status) {
      StockStatus.inStock => PantryMatchStatus.enough,
      StockStatus.low => PantryMatchStatus.partial,
      StockStatus.need => PantryMatchStatus.missing,
    };
  }

  PantryMatchStatus matchStatus(String ingredientId, double required, String unit) =>
      _matchStatus(ingredientId, required, unit);

  bool isRecipeMakeable(String recipeId) {
    final ingredients = ingredientsForRecipe(recipeId).where((ri) => !ri.isOptional);
    return ingredients.every(
      (ri) => _matchStatus(ri.ingredientId, ri.quantity, ri.unit) == PantryMatchStatus.enough,
    );
  }

  int missingCountForRecipe(String recipeId) {
    return ingredientsForRecipe(recipeId)
        .where((ri) => !ri.isOptional)
        .where((ri) => _matchStatus(ri.ingredientId, ri.quantity, ri.unit) != PantryMatchStatus.enough)
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
        return ingredientById(ri.ingredientId)?.canonicalName ?? 'an ingredient';
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
        .where((p) => p.lastVerifiedAt == null || p.lastVerifiedAt!.isBefore(cutoff))
        .toList();
  }

  // ─── Seed ─────────────────────────────────────────────────────────────────

  Future<void> _seed(SharedPreferences prefs) async {
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
      Ingredient(id: iMilk, canonicalName: 'Whole Milk', category: IngredientCategory.dairy,
          aliases: ['milk', 'full fat milk', 'full cream milk'], createdAt: now),
      Ingredient(id: iYogurt, canonicalName: 'Greek Yogurt', category: IngredientCategory.dairy,
          aliases: ['yogurt'], createdAt: now),
      Ingredient(id: iGarlic, canonicalName: 'Garlic', category: IngredientCategory.produce,
          aliases: ['garlic cloves', 'fresh garlic', 'minced garlic'], createdAt: now),
      Ingredient(id: iOnion, canonicalName: 'Yellow Onion', category: IngredientCategory.produce,
          aliases: ['onion', 'brown onion', 'white onion'], createdAt: now),
      Ingredient(id: iRice, canonicalName: 'Basmati Rice', category: IngredientCategory.grain,
          aliases: ['rice', 'basmati', 'long grain rice'], createdAt: now),
      Ingredient(id: iEggs, canonicalName: 'Eggs', category: IngredientCategory.produce,
          aliases: ['egg'], createdAt: now),
      Ingredient(id: iPassata, canonicalName: 'Tomato Passata', category: IngredientCategory.produce,
          aliases: ['passata', 'tomato sauce'], createdAt: now),
      Ingredient(id: iGaram, canonicalName: 'Garam Masala', category: IngredientCategory.spice,
          aliases: ['garam masala spice'], createdAt: now),
      Ingredient(id: iParmesan, canonicalName: 'Parmesan', category: IngredientCategory.dairy,
          aliases: ['parmigiano'], createdAt: now),
      Ingredient(id: iChicken, canonicalName: 'Chicken Breast', category: IngredientCategory.meat,
          aliases: ['chicken', 'boneless chicken', 'boneless chicken breast', 'chicken fillet'], createdAt: now),
      Ingredient(id: iSalmon, canonicalName: 'Salmon Fillet', category: IngredientCategory.meat,
          aliases: ['salmon'], createdAt: now),
      Ingredient(id: iCream, canonicalName: 'Heavy Cream', category: IngredientCategory.dairy,
          aliases: ['cream', 'double cream'], createdAt: now),
      Ingredient(id: iPanko, canonicalName: 'Panko Breadcrumbs', category: IngredientCategory.grain,
          aliases: ['breadcrumbs', 'panko'], createdAt: now),
      Ingredient(id: iButter, canonicalName: 'Butter', category: IngredientCategory.dairy,
          aliases: [], createdAt: now),
      Ingredient(id: iPasta, canonicalName: 'Spaghetti', category: IngredientCategory.grain,
          aliases: ['pasta', 'spaghetti'], createdAt: now),
      Ingredient(id: iRamen, canonicalName: 'Ramen Noodles', category: IngredientCategory.grain,
          aliases: ['noodles'], createdAt: now),
      Ingredient(id: iSoy, canonicalName: 'Soy Sauce', category: IngredientCategory.spice,
          aliases: ['soy'], createdAt: now),
      Ingredient(id: iMiso, canonicalName: 'Miso Paste', category: IngredientCategory.spice,
          aliases: ['miso'], createdAt: now),
      Ingredient(id: iGreens, canonicalName: 'Mixed Greens', category: IngredientCategory.produce,
          aliases: ['salad leaves', 'greens'], createdAt: now),
      Ingredient(id: iSesame, canonicalName: 'Sesame Seeds', category: IngredientCategory.spice,
          aliases: ['sesame'], createdAt: now),
      Ingredient(id: iBroccoli, canonicalName: 'Broccoli', category: IngredientCategory.produce,
          aliases: [], createdAt: now),
      Ingredient(id: iTeriyaki, canonicalName: 'Teriyaki Sauce', category: IngredientCategory.spice,
          aliases: ['teriyaki'], createdAt: now),
    ];

    final pantryItems = [
      PantryItem(id: 'p-milk', ingredientId: iMilk, quantity: 1.5, initialQuantity: 2.0, unit: 'L', addedAt: now.subtract(const Duration(days: 3))),
      PantryItem(id: 'p-yogurt', ingredientId: iYogurt, quantity: 80, initialQuantity: 500, unit: 'g', addedAt: now.subtract(const Duration(days: 5))),
      PantryItem(id: 'p-garlic', ingredientId: iGarlic, quantity: 6, initialQuantity: 6, unit: 'cloves', addedAt: now.subtract(const Duration(days: 2))),
      PantryItem(id: 'p-onion', ingredientId: iOnion, quantity: 3, initialQuantity: 5, unit: 'pcs', addedAt: now.subtract(const Duration(days: 4))),
      PantryItem(id: 'p-rice', ingredientId: iRice, quantity: 800, initialQuantity: 1000, unit: 'g', addedAt: now.subtract(const Duration(days: 1))),
      PantryItem(id: 'p-eggs', ingredientId: iEggs, quantity: 12, initialQuantity: 12, unit: 'pcs', addedAt: now.subtract(const Duration(days: 1))),
      PantryItem(id: 'p-passata', ingredientId: iPassata, quantity: 400, initialQuantity: 400, unit: 'g', addedAt: now.subtract(const Duration(days: 7))),
      PantryItem(id: 'p-garam', ingredientId: iGaram, quantity: 1, initialQuantity: 1, unit: 'jar', addedAt: now.subtract(const Duration(days: 14))),
      PantryItem(id: 'p-parmesan', ingredientId: iParmesan, quantity: 150, initialQuantity: 200, unit: 'g', addedAt: now.subtract(const Duration(days: 3))),
      PantryItem(id: 'p-soy', ingredientId: iSoy, quantity: 1, initialQuantity: 1, unit: 'bottle', addedAt: now.subtract(const Duration(days: 10))),
      PantryItem(id: 'p-miso', ingredientId: iMiso, quantity: 1, initialQuantity: 1, unit: 'jar', addedAt: now.subtract(const Duration(days: 10))),
      PantryItem(id: 'p-ramen', ingredientId: iRamen, quantity: 400, initialQuantity: 400, unit: 'g', addedAt: now.subtract(const Duration(days: 10))),
      PantryItem(id: 'p-butter', ingredientId: iButter, quantity: 200, initialQuantity: 250, unit: 'g', addedAt: now.subtract(const Duration(days: 2))),
    ];

    final recipes = [
      Recipe(
        id: rButterChicken, title: 'Butter Chicken', emoji: '🍛',
        instructions: [
          'Marinate chicken in yogurt, garlic, and garam masala for 30 minutes.',
          'Sear chicken pieces in butter until golden.',
          'Sauté onion until soft, add garlic and garam masala.',
          'Add passata and simmer for 10 minutes.',
          'Stir in cream and return chicken to pan.',
          'Simmer 15 minutes until sauce thickens. Serve over basmati rice.',
        ],
        servings: 4, cookMinutes: 45, difficulty: 'Medium',
        tags: ['dinner', 'indian'], createdAt: now, updatedAt: now,
      ),
      Recipe(
        id: rRamen, title: 'Ramen Bowl', emoji: '🍜',
        instructions: [
          'Bring broth to a boil with miso paste and soy sauce.',
          'Cook ramen noodles according to package instructions.',
          'Soft-boil eggs for 6.5 minutes, peel and halve.',
          'Divide noodles into bowls, ladle broth over.',
          'Top with soft-boiled egg and spring onions.',
        ],
        servings: 2, cookMinutes: 30, difficulty: 'Easy',
        tags: ['dinner', 'asian'], createdAt: now, updatedAt: now,
      ),
      Recipe(
        id: rSalad, title: 'Asian Salad', emoji: '🥗',
        instructions: [
          'Whisk together soy sauce, sesame oil and a pinch of sugar.',
          'Toss mixed greens with the dressing.',
          'Top with sesame seeds and serve immediately.',
        ],
        servings: 2, cookMinutes: 15, difficulty: 'Easy',
        tags: ['lunch', 'asian', 'vegetarian'], createdAt: now, updatedAt: now,
      ),
      Recipe(
        id: rCarbonara, title: 'Carbonara', emoji: '🍝',
        instructions: [
          'Cook spaghetti in well-salted boiling water until al dente.',
          'Fry guanciale or pancetta until crispy.',
          'Whisk eggs with grated parmesan.',
          'Toss hot pasta off heat with egg mixture and pancetta.',
          'Add pasta water to achieve a silky sauce. Season generously.',
        ],
        servings: 2, cookMinutes: 25, difficulty: 'Medium',
        tags: ['dinner', 'italian'], createdAt: now, updatedAt: now,
      ),
      Recipe(
        id: rTeriyaki, title: 'Teriyaki Bowl', emoji: '🍱',
        instructions: [
          'Marinate salmon in teriyaki sauce for 15 minutes.',
          'Cook rice according to package instructions.',
          'Steam or roast broccoli until tender.',
          'Sear salmon in a hot pan for 3–4 minutes each side.',
          'Serve salmon over rice with broccoli.',
        ],
        servings: 2, cookMinutes: 20, difficulty: 'Easy',
        tags: ['dinner', 'asian'], createdAt: now, updatedAt: now,
      ),
    ];

    final recipeIngredients = [
      // Butter Chicken
      const RecipeIngredient(id: 'ri-bc-1', recipeId: rButterChicken, ingredientId: iChicken, quantity: 600, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-bc-2', recipeId: rButterChicken, ingredientId: iButter, quantity: 50, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-bc-3', recipeId: rButterChicken, ingredientId: iGarlic, quantity: 4, unit: 'cloves', isOptional: false),
      const RecipeIngredient(id: 'ri-bc-4', recipeId: rButterChicken, ingredientId: iOnion, quantity: 1, unit: 'pcs', isOptional: false),
      const RecipeIngredient(id: 'ri-bc-5', recipeId: rButterChicken, ingredientId: iPassata, quantity: 400, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-bc-6', recipeId: rButterChicken, ingredientId: iCream, quantity: 200, unit: 'ml', isOptional: false),
      const RecipeIngredient(id: 'ri-bc-7', recipeId: rButterChicken, ingredientId: iGaram, quantity: 2, unit: 'tbsp', isOptional: false),
      const RecipeIngredient(id: 'ri-bc-8', recipeId: rButterChicken, ingredientId: iRice, quantity: 300, unit: 'g', isOptional: false),
      // Ramen
      const RecipeIngredient(id: 'ri-rm-1', recipeId: rRamen, ingredientId: iRamen, quantity: 200, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-rm-2', recipeId: rRamen, ingredientId: iEggs, quantity: 2, unit: 'pcs', isOptional: false),
      const RecipeIngredient(id: 'ri-rm-3', recipeId: rRamen, ingredientId: iSoy, quantity: 3, unit: 'tbsp', isOptional: false),
      const RecipeIngredient(id: 'ri-rm-4', recipeId: rRamen, ingredientId: iMiso, quantity: 2, unit: 'tbsp', isOptional: false),
      // Asian Salad
      const RecipeIngredient(id: 'ri-as-1', recipeId: rSalad, ingredientId: iGreens, quantity: 100, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-as-2', recipeId: rSalad, ingredientId: iSesame, quantity: 1, unit: 'tbsp', isOptional: false),
      const RecipeIngredient(id: 'ri-as-3', recipeId: rSalad, ingredientId: iSoy, quantity: 2, unit: 'tbsp', isOptional: false),
      // Carbonara
      const RecipeIngredient(id: 'ri-ca-1', recipeId: rCarbonara, ingredientId: iPasta, quantity: 200, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-ca-2', recipeId: rCarbonara, ingredientId: iEggs, quantity: 3, unit: 'pcs', isOptional: false),
      const RecipeIngredient(id: 'ri-ca-3', recipeId: rCarbonara, ingredientId: iParmesan, quantity: 80, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-ca-4', recipeId: rCarbonara, ingredientId: iButter, quantity: 30, unit: 'g', isOptional: true),
      // Teriyaki Bowl
      const RecipeIngredient(id: 'ri-te-1', recipeId: rTeriyaki, ingredientId: iSalmon, quantity: 2, unit: 'pcs', isOptional: false),
      const RecipeIngredient(id: 'ri-te-2', recipeId: rTeriyaki, ingredientId: iRice, quantity: 200, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-te-3', recipeId: rTeriyaki, ingredientId: iBroccoli, quantity: 150, unit: 'g', isOptional: false),
      const RecipeIngredient(id: 'ri-te-4', recipeId: rTeriyaki, ingredientId: iTeriyaki, quantity: 4, unit: 'tbsp', isOptional: false),
    ];

    final shoppingItems = [
      ShoppingItem(id: 'shop-1', ingredientId: iChicken, quantity: 600, unit: 'g', checked: false, sourceRecipeId: rButterChicken, addedAt: now, updatedAt: now),
      ShoppingItem(id: 'shop-2', ingredientId: iSalmon, quantity: 2, unit: 'pcs', checked: false, sourceRecipeId: rTeriyaki, addedAt: now, updatedAt: now),
      ShoppingItem(id: 'shop-3', ingredientId: iCream, quantity: 200, unit: 'ml', checked: false, addedAt: now, updatedAt: now),
      ShoppingItem(id: 'shop-4', ingredientId: iPanko, quantity: 1, unit: 'bag', checked: false, addedAt: now, updatedAt: now),
    ];

    _state = AppState(
      ingredients: ingredients,
      pantryItems: pantryItems,
      recipes: recipes,
      recipeIngredients: recipeIngredients,
      shoppingItems: shoppingItems,
    );
    await prefs.setString(_kStateKey, jsonEncode(_state.toJson()));
  }
}
