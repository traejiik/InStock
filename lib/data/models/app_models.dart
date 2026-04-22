import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum IngredientCategory { dairy, produce, grain, meat, spice, custom }

extension IngredientCategoryX on IngredientCategory {
  String get label => switch (this) {
        IngredientCategory.dairy => 'Dairy',
        IngredientCategory.produce => 'Produce',
        IngredientCategory.grain => 'Grains',
        IngredientCategory.meat => 'Meat & Fish',
        IngredientCategory.spice => 'Spices',
        IngredientCategory.custom => 'Other',
      };

  String get emoji => switch (this) {
        IngredientCategory.dairy => '🥛',
        IngredientCategory.produce => '🥦',
        IngredientCategory.grain => '🌾',
        IngredientCategory.meat => '🥩',
        IngredientCategory.spice => '🧂',
        IngredientCategory.custom => '📦',
      };

  Color get color => switch (this) {
        IngredientCategory.dairy => AppColors.blue,
        IngredientCategory.produce => AppColors.green,
        IngredientCategory.grain => AppColors.amber,
        IngredientCategory.meat => AppColors.red,
        IngredientCategory.spice => AppColors.purple,
        IngredientCategory.custom => AppColors.teal,
      };
}

enum StockStatus { inStock, low, need }

enum PantryMatchStatus { enough, partial, missing }

// ─── Models ───────────────────────────────────────────────────────────────────

class Ingredient {
  final String id;
  final String canonicalName;
  final IngredientCategory category;
  final List<String> aliases;
  final DateTime createdAt;

  const Ingredient({
    required this.id,
    required this.canonicalName,
    required this.category,
    required this.aliases,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'canonicalName': canonicalName,
        'category': category.name,
        'aliases': aliases,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        id: j['id'] as String,
        canonicalName: j['canonicalName'] as String,
        category: IngredientCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => IngredientCategory.custom,
        ),
        aliases: List<String>.from(j['aliases'] as List),
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
      );
}

class PantryItem {
  final String id;
  final String ingredientId;
  final double quantity;
  final double initialQuantity;
  final String unit;
  final DateTime addedAt;
  final DateTime? lastVerifiedAt;
  final DateTime? deletedAt;

  const PantryItem({
    required this.id,
    required this.ingredientId,
    required this.quantity,
    required this.initialQuantity,
    required this.unit,
    required this.addedAt,
    this.lastVerifiedAt,
    this.deletedAt,
  });

  PantryItem copyWith({
    double? quantity,
    double? initialQuantity,
    DateTime? lastVerifiedAt,
    DateTime? deletedAt,
  }) =>
      PantryItem(
        id: id,
        ingredientId: ingredientId,
        quantity: quantity ?? this.quantity,
        initialQuantity: initialQuantity ?? this.initialQuantity,
        unit: unit,
        addedAt: addedAt,
        lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  double get fillLevel =>
      initialQuantity > 0 ? (quantity / initialQuantity).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'quantity': quantity,
        'initialQuantity': initialQuantity,
        'unit': unit,
        'addedAt': addedAt.millisecondsSinceEpoch,
        'lastVerifiedAt': lastVerifiedAt?.millisecondsSinceEpoch,
        'deletedAt': deletedAt?.millisecondsSinceEpoch,
      };

  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
        id: j['id'] as String,
        ingredientId: j['ingredientId'] as String,
        quantity: (j['quantity'] as num).toDouble(),
        initialQuantity: (j['initialQuantity'] as num).toDouble(),
        unit: j['unit'] as String,
        addedAt: DateTime.fromMillisecondsSinceEpoch(j['addedAt'] as int),
        lastVerifiedAt: j['lastVerifiedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['lastVerifiedAt'] as int)
            : null,
        deletedAt: j['deletedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['deletedAt'] as int)
            : null,
      );
}

class Recipe {
  final String id;
  final String title;
  final String emoji;
  final List<String> instructions;
  final int servings;
  final int cookMinutes;
  final String difficulty;
  final String? sourceUrl;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Recipe({
    required this.id,
    required this.title,
    required this.emoji,
    required this.instructions,
    required this.servings,
    required this.cookMinutes,
    required this.difficulty,
    this.sourceUrl,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'instructions': instructions,
        'servings': servings,
        'cookMinutes': cookMinutes,
        'difficulty': difficulty,
        'sourceUrl': sourceUrl,
        'tags': tags,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'deletedAt': deletedAt?.millisecondsSinceEpoch,
      };

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        title: j['title'] as String,
        emoji: j['emoji'] as String? ?? '🍽️',
        instructions: List<String>.from(j['instructions'] as List),
        servings: j['servings'] as int,
        cookMinutes: j['cookMinutes'] as int? ?? 30,
        difficulty: j['difficulty'] as String? ?? 'Medium',
        sourceUrl: j['sourceUrl'] as String?,
        tags: List<String>.from(j['tags'] as List),
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int),
        deletedAt: j['deletedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['deletedAt'] as int)
            : null,
      );
}

class RecipeIngredient {
  final String id;
  final String recipeId;
  final String ingredientId;
  final double quantity;
  final String unit;
  final bool isOptional;
  final String? notes;

  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    required this.isOptional,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'ingredientId': ingredientId,
        'quantity': quantity,
        'unit': unit,
        'isOptional': isOptional ? 1 : 0,
        'notes': notes,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
        id: j['id'] as String,
        recipeId: j['recipeId'] as String,
        ingredientId: j['ingredientId'] as String,
        quantity: (j['quantity'] as num).toDouble(),
        unit: j['unit'] as String,
        isOptional: (j['isOptional'] as int) == 1,
        notes: j['notes'] as String?,
      );
}

class ShoppingItem {
  final String id;
  final String ingredientId;
  final double quantity;
  final String unit;
  final bool checked;
  final String? sourceRecipeId;
  final DateTime addedAt;
  final DateTime updatedAt;

  const ShoppingItem({
    required this.id,
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    required this.checked,
    this.sourceRecipeId,
    required this.addedAt,
    required this.updatedAt,
  });

  ShoppingItem copyWith({bool? checked, DateTime? updatedAt}) => ShoppingItem(
        id: id,
        ingredientId: ingredientId,
        quantity: quantity,
        unit: unit,
        checked: checked ?? this.checked,
        sourceRecipeId: sourceRecipeId,
        addedAt: addedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'quantity': quantity,
        'unit': unit,
        'checked': checked ? 1 : 0,
        'sourceRecipeId': sourceRecipeId,
        'addedAt': addedAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] as String,
        ingredientId: j['ingredientId'] as String,
        quantity: (j['quantity'] as num).toDouble(),
        unit: j['unit'] as String,
        checked: (j['checked'] as int) == 1,
        sourceRecipeId: j['sourceRecipeId'] as String?,
        addedAt: DateTime.fromMillisecondsSinceEpoch(j['addedAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int),
      );
}

// ─── App State ────────────────────────────────────────────────────────────────

class AppState {
  final List<Ingredient> ingredients;
  final List<PantryItem> pantryItems;
  final List<Recipe> recipes;
  final List<RecipeIngredient> recipeIngredients;
  final List<ShoppingItem> shoppingItems;

  const AppState({
    required this.ingredients,
    required this.pantryItems,
    required this.recipes,
    required this.recipeIngredients,
    required this.shoppingItems,
  });

  static const empty = AppState(
    ingredients: [],
    pantryItems: [],
    recipes: [],
    recipeIngredients: [],
    shoppingItems: [],
  );

  AppState copyWith({
    List<Ingredient>? ingredients,
    List<PantryItem>? pantryItems,
    List<Recipe>? recipes,
    List<RecipeIngredient>? recipeIngredients,
    List<ShoppingItem>? shoppingItems,
  }) =>
      AppState(
        ingredients: ingredients ?? this.ingredients,
        pantryItems: pantryItems ?? this.pantryItems,
        recipes: recipes ?? this.recipes,
        recipeIngredients: recipeIngredients ?? this.recipeIngredients,
        shoppingItems: shoppingItems ?? this.shoppingItems,
      );

  Map<String, dynamic> toJson() => {
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'pantryItems': pantryItems.map((e) => e.toJson()).toList(),
        'recipes': recipes.map((e) => e.toJson()).toList(),
        'recipeIngredients': recipeIngredients.map((e) => e.toJson()).toList(),
        'shoppingItems': shoppingItems.map((e) => e.toJson()).toList(),
      };

  factory AppState.fromJson(Map<String, dynamic> j) => AppState(
        ingredients: (j['ingredients'] as List)
            .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        pantryItems: (j['pantryItems'] as List)
            .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        recipes: (j['recipes'] as List)
            .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
            .toList(),
        recipeIngredients: (j['recipeIngredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        shoppingItems: (j['shoppingItems'] as List)
            .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
