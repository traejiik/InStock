import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/models/app_models.dart';

final appDatabaseProvider = ChangeNotifierProvider<AppDatabase>(
  (ref) => throw UnimplementedError('Override appDatabaseProvider in ProviderScope'),
);

final shoppingItemsProvider = Provider<List<ShoppingItem>>((ref) {
  return ref.watch(appDatabaseProvider).shoppingItems;
});

final pantryItemsProvider = Provider<List<PantryItem>>((ref) {
  return ref.watch(appDatabaseProvider).pantryItems;
});

final ingredientsProvider = Provider<List<Ingredient>>((ref) {
  return ref.watch(appDatabaseProvider).ingredients;
});

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

final pantryVerificationStatusProvider = Provider<bool>((ref) {
  return ref.watch(appDatabaseProvider).needsVerification;
});
