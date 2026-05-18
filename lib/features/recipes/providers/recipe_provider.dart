import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/core/providers/app_database_provider.dart';
import 'package:instock/data/models/app_models.dart';

final recipesProvider = Provider<List<Recipe>>((ref) {
  return ref.watch(appDatabaseProvider).recipes;
});

final recipeIngredientsProvider = Provider<List<RecipeIngredient>>((ref) {
  return ref.watch(appDatabaseProvider).recipeIngredients;
});

final makeableRecipesProvider = Provider<List<Recipe>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.recipes.where((r) => db.isRecipeMakeable(r.id)).toList();
});
