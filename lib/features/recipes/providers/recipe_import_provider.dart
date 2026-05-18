import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recipe_scraper.dart';

final recipeScraperProvider = Provider<RecipeScraper>((ref) => RecipeScraper());

class RecipeImportNotifier extends AsyncNotifier<ParsedRecipe?> {
  @override
  Future<ParsedRecipe?> build() async => null;

  Future<void> scrape(String url) async {
    state = const AsyncLoading<ParsedRecipe?>();
    final scraper = ref.read(recipeScraperProvider);
    state = await AsyncValue.guard(() => scraper.scrape(url));
  }

  void reset() => state = const AsyncData(null);
}

final recipeImportProvider =
    AsyncNotifierProvider<RecipeImportNotifier, ParsedRecipe?>(
      RecipeImportNotifier.new,
    );
