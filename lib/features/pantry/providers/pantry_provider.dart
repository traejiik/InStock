import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/core/providers/app_database_provider.dart';
import 'package:instock/data/models/app_models.dart';

final pantryItemsProvider = Provider<List<PantryItem>>((ref) {
  return ref.watch(appDatabaseProvider).pantryItems;
});

final ingredientsProvider = Provider<List<Ingredient>>((ref) {
  return ref.watch(appDatabaseProvider).ingredients;
});

final pantryVerificationStatusProvider = Provider<bool>((ref) {
  return ref.watch(appDatabaseProvider).needsVerification;
});
