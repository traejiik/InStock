import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature providers do not re-export shopping provider ownership', () {
    final pantryProvider = File(
      'lib/features/pantry/providers/pantry_provider.dart',
    ).readAsStringSync();
    final recipeProvider = File(
      'lib/features/recipes/providers/recipe_provider.dart',
    ).readAsStringSync();
    final shoppingProvider = File(
      'lib/features/shopping/providers/shopping_provider.dart',
    ).readAsStringSync();

    expect(pantryProvider, isNot(contains('shopping_provider.dart')));
    expect(recipeProvider, isNot(contains('shopping_provider.dart')));
    expect(shoppingProvider, isNot(contains('pantryItemsProvider')));
    expect(shoppingProvider, isNot(contains('recipesProvider')));
    expect(
      File('lib/core/providers/app_database_provider.dart').existsSync(),
      isTrue,
    );
  });
}
