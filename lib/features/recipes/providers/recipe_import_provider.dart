import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recipe_scraper.dart';

class RecipeImportNotifier extends AsyncNotifier<ParsedRecipe?> {
  @override
  Future<ParsedRecipe?> build() async => null;

  Future<void> scrape(String url) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => RecipeScraper().scrape(url));
  }

  void reset() => state = const AsyncData(null);
}

final recipeImportProvider =
    AsyncNotifierProvider<RecipeImportNotifier, ParsedRecipe?>(
  RecipeImportNotifier.new,
);
