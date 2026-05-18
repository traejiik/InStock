import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instock/features/recipes/providers/recipe_import_provider.dart';
import 'package:instock/features/recipes/services/recipe_scraper.dart';

void main() {
  group('RecipeImportNotifier', () {
    test('uses the injected recipe scraper', () async {
      final scraper = _FakeRecipeScraper(
        scrapeHandler: (url) async {
          expect(url, 'https://example.com/recipe');
          return _parsedRecipe(title: 'Injected Recipe');
        },
      );
      final container = ProviderContainer(
        overrides: [recipeScraperProvider.overrideWithValue(scraper)],
      );
      addTearDown(container.dispose);

      await container
          .read(recipeImportProvider.notifier)
          .scrape('https://example.com/recipe');

      expect(
        container.read(recipeImportProvider).value?.title,
        'Injected Recipe',
      );
    });

    test('surfaces failures from the injected scraper', () async {
      var shouldFail = false;
      final scraper = _FakeRecipeScraper(
        scrapeHandler: (url) async {
          if (shouldFail) {
            throw const RecipeParseException(
              'Could not extract instructions from this URL',
            );
          }
          return _parsedRecipe(title: 'First Import');
        },
      );
      final container = ProviderContainer(
        overrides: [recipeScraperProvider.overrideWithValue(scraper)],
      );
      addTearDown(container.dispose);

      await container
          .read(recipeImportProvider.notifier)
          .scrape('https://example.com/first');
      expect(container.read(recipeImportProvider).value?.title, 'First Import');

      shouldFail = true;
      final scrape = container
          .read(recipeImportProvider.notifier)
          .scrape('https://example.com/broken');

      final loadingState = container.read(recipeImportProvider);
      expect(loadingState.isLoading, isTrue);

      await scrape;

      final failedState = container.read(recipeImportProvider);
      expect(failedState.hasError, isTrue);
      expect(failedState.error, isA<RecipeParseException>());
    });
  });
}

class _FakeRecipeScraper extends RecipeScraper {
  final Future<ParsedRecipe> Function(String url) scrapeHandler;

  _FakeRecipeScraper({required this.scrapeHandler});

  @override
  Future<ParsedRecipe> scrape(String url) => scrapeHandler(url);
}

ParsedRecipe _parsedRecipe({required String title}) => ParsedRecipe(
  title: title,
  baseServings: 2,
  ingredients: const [
    ParsedIngredient(name: 'Pasta', quantity: 200, unit: 'g'),
    ParsedIngredient(name: 'Tomato sauce', quantity: 1, unit: 'cups'),
  ],
  steps: const ['Cook the pasta.', 'Toss with sauce.'],
  sourceUrl: 'https://example.com/recipe',
);
