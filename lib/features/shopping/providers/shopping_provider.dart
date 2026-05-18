import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/core/providers/app_database_provider.dart';
import 'package:instock/data/models/app_models.dart';

final shoppingItemsProvider = Provider<List<ShoppingItem>>((ref) {
  return ref.watch(appDatabaseProvider).shoppingItems;
});
