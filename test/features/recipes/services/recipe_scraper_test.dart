import 'package:flutter_test/flutter_test.dart';
import 'package:instock/features/recipes/services/recipe_scraper.dart';

void main() {
  group('RecipeScraper.normalizeUrl', () {
    test('adds https to a bare recipe URL', () {
      final uri = RecipeScraper.normalizeUrl(
        'recipetineats.com/chicken-breast-recipe/',
      );

      expect(
        uri.toString(),
        'https://recipetineats.com/chicken-breast-recipe/',
      );
    });

    test('rejects non-web URLs', () {
      expect(RecipeScraper.normalizeUrl('not a url'), isNull);
      expect(RecipeScraper.normalizeUrl('ftp://example.com/recipe'), isNull);
    });

    test('accepts recipe URLs pasted with surrounding angle brackets', () {
      final uri = RecipeScraper.normalizeUrl(
        '  <https://example.com/recipe/chicken>  ',
      );

      expect(uri.toString(), 'https://example.com/recipe/chicken');
    });
  });

  group('RecipeScraper.parseHtml', () {
    test('keeps recipe sections out of ingredient and step rows', () {
      final parsed = RecipeScraper.parseHtml(
        _recipeTinStyleHtml,
        sourceUrl: 'https://example.com/chicken-breast-recipe/',
      );

      expect(parsed.title, 'My go-to Chicken Breast recipe');
      expect(parsed.baseServings, 4);
      expect(parsed.cookTimeMinutes, 7);
      expect(parsed.ingredients, hasLength(12));
      expect(parsed.ingredientSections.map((s) => s.label), [
        isNull,
        'Savoury seasoned crust',
        'Butter sauce',
      ]);
      expect(
        parsed.ingredients.map((i) => i.name),
        isNot(contains('SAVOURY SEASONED CRUST:')),
      );
      expect(
        parsed.ingredients.map((i) => i.name),
        isNot(contains('BUTTER SAUCE:')),
      );
      expect(parsed.ingredients.map((i) => i.name), [
        'Chicken breast',
        'Butter',
        'Paprika',
        'Onion powder',
        'Garlic powder',
        'Cumin',
        'Salt',
        'Black pepper',
        'Flour',
        'White wine',
        'Butter',
        'Parsley',
      ]);
      expect(
        parsed.ingredients[0].notes,
        contains('250 - 300g/8 - 10 oz each'),
      );
      expect(parsed.ingredients[8].name, 'Flour');
      expect(parsed.ingredients[8].notes, contains('plain/all-purpose'));
      expect(parsed.ingredients[10].name, 'Butter');
      expect(parsed.ingredients[10].quantity, 30);
      expect(parsed.ingredients[10].unit, 'g');
      expect(parsed.ingredients[10].notes, contains('2 tbsp'));
      expect(parsed.steps, [
        startsWith('Season - Mix the Seasoning ingredients'),
        startsWith('Sear - Melt the butter'),
        startsWith('Pan sauce - Lower then heat'),
        startsWith('Serve - Serve chicken'),
      ]);
      expect(parsed.steps, isNot(contains('ABBREVIATED')));
      expect(parsed.steps, isNot(contains('FULL RECIPE')));
    });

    test('cleans imported ingredient names down to core pantry items', () {
      final parsed = RecipeScraper.parseHtml(
        _messyIngredientHtml,
        sourceUrl: 'https://example.com/messy',
      );

      expect(parsed.ingredients.map((i) => i.name), [
        'Butter',
        'White wine',
        'Parsley',
        'Onion powder',
        'Garlic powder',
      ]);
      expect(parsed.ingredients.map((i) => i.name), everyElement(isNot('')));
      expect(
        parsed.ingredients.map((i) => i.name),
        everyElement(
          allOf(
            isNot(contains('(')),
            isNot(contains(')')),
            isNot(contains('/ 1')),
            isNot(contains('roughly')),
            isNot(contains('chopped')),
            isNot(contains('unsalted')),
            isNot(contains('dry')),
          ),
        ),
      );

      expect(parsed.ingredients[0].quantity, 30);
      expect(parsed.ingredients[0].unit, 'g');
      expect(parsed.ingredients[0].notes, contains('1 1/2 tbsp'));
      expect(parsed.ingredients[1].quantity, 80);
      expect(parsed.ingredients[1].unit, 'ml');
    });

    test('extracts nested HowToSection instructions from JSON-LD', () {
      final parsed = RecipeScraper.parseHtml(
        _howToSectionHtml,
        sourceUrl: 'https://example.com/pasta',
      );

      expect(parsed.steps, [
        'Boil the pasta until al dente.',
        'Toss pasta with sauce.',
      ]);
      expect(parsed.instructionSections.map((s) => s.label), ['Method']);
    });

    test('prefers richer visible instructions over terse structured steps', () {
      final parsed = RecipeScraper.parseHtml(
        _visibleInstructionsHtml,
        sourceUrl: 'https://example.com/rich-steps',
      );

      expect(parsed.steps, [
        "Whisk the sauce ingredients together until it's glossy and smooth.",
        'Sear the chicken until deep golden, then simmer it gently in the sauce for 8 minutes.',
        'Rest the chicken for 5 minutes before slicing and serving with parsley.',
      ]);
      expect(parsed.steps, isNot(contains('Cook chicken.')));
      expect(parsed.notes, contains('Leftovers keep for 3 days'));
      expect(parsed.notes, contains('Use low-sodium stock if skipping wine'));
      expect(parsed.steps.join(' '), isNot(contains('Leftovers keep')));
    });

    test('ignores abbreviated visible instructions when full steps exist', () {
      final parsed = RecipeScraper.parseHtml(
        _visibleAbbreviatedAndFullHtml,
        sourceUrl: 'https://example.com/full-steps',
      );

      expect(parsed.steps, [
        'Season the chicken on both sides with the spice mix.',
        'Cook the chicken in butter until golden and cooked through.',
      ]);
      expect(parsed.steps, isNot(contains('Season, cook, serve.')));
    });

    test('does not convert tiny spoon measures to milliliters', () {
      final parsed = RecipeScraper.parseHtml(
        _recipeTinStyleHtml,
        sourceUrl: 'https://example.com/chicken-breast-recipe/',
      );
      final converted = RecipeScraper.applyMetricConversion(parsed.ingredients);

      expect(converted[2].name, 'Paprika');
      expect(converted[2].quantity, 1);
      expect(converted[2].unit, 'tsp');
    });

    test('rejects structured recipes with ingredients but no instructions', () {
      expect(
        () => RecipeScraper.parseHtml(
          _ingredientOnlyJsonLdHtml,
          sourceUrl: 'https://example.com/no-steps',
        ),
        throwsA(
          isA<RecipeParseException>().having(
            (e) => e.message,
            'message',
            contains('instructions'),
          ),
        ),
      );
    });

    test('rejects heuristic imports with ingredients but no instructions', () {
      expect(
        () => RecipeScraper.parseHtml(
          _ingredientOnlyHeuristicHtml,
          sourceUrl: 'https://example.com/no-visible-steps',
        ),
        throwsA(
          isA<RecipeParseException>().having(
            (e) => e.message,
            'message',
            contains('instructions'),
          ),
        ),
      );
    });
  });
}

const _recipeTinStyleHtml = '''
<!doctype html>
<html>
<head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "My go-to Chicken Breast recipe",
  "image": "https://example.com/chicken.jpg",
  "totalTime": "PT7M",
  "recipeYield": "4 servings",
  "recipeIngredient": [
    "2 large chicken breasts (250 - 300g/8 - 10 oz each), each cut in half horizontally to form 4 steaks, no need to pound (Note 1)",
    "30 g unsalted butter or 1 1/2 tbsp olive oil",
    "SAVOURY SEASONED CRUST:",
    "1 tsp paprika, regular/sweet (or smoky)",
    "0.5 tsp onion powder (or more garlic)",
    "0.5 tsp garlic powder (or more onion)",
    "0.25 tsp cumin (sub coriander, thyme leaves crushed between fingers, or omit)",
    "0.75 tsp cooking salt / kosher salt (halve for table salt, +50% for flakes)",
    "0.13 tsp black pepper",
    "1.5 tbsp flour, plain/all-purpose, GF (Note 2)",
    "BUTTER SAUCE:",
    "80 ml dry white wine or chicken stock (low sodium), sub water (Note 3)",
    "30 g unsalted butter / 2 tbsp",
    "1 tbsp roughly chopped parsley, optional but recommended"
  ],
  "recipeInstructions": [
    {
      "@type": "HowToSection",
      "name": "ABBREVIATED",
      "itemListElement": [
        {"@type": "HowToStep", "text": "Dust chicken with Seasoning, pan fry in the butter, remove. Deglaze with wine, melt in butter, serve sauce on chicken."}
      ]
    },
    {
      "@type": "HowToSection",
      "name": "FULL RECIPE",
      "itemListElement": [
        {"@type": "HowToStep", "name": "Season", "text": "Season - Mix the Seasoning ingredients in a bowl. Sprinkle on each side of the chicken."},
        {"@type": "HowToStep", "name": "Sear", "text": "Sear - Melt the butter in a large non-stick pan over high heat."},
        {"@type": "HowToStep", "name": "Pan sauce", "text": "Pan sauce - Lower then heat to medium high. Add the wine and simmer rapidly."},
        {"@type": "HowToStep", "name": "Serve", "text": "Serve - Serve chicken with sauce and sprinkled with parsley. Enjoy!"}
      ]
    }
  ]
}
</script>
</head>
<body></body>
</html>
''';

const _visibleInstructionsHtml = '''
<!doctype html>
<html>
<head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Rich Step Chicken",
  "recipeIngredient": ["2 chicken breasts", "1 tbsp parsley"],
  "recipeInstructions": ["Cook chicken."]
}
</script>
</head>
<body>
  <ol class="wprm-recipe-instructions">
    <li>Whisk the sauce ingredients together until it&#39;s glossy and smooth.</li>
    <li>Sear the chicken until deep golden, then simmer it gently in the sauce for 8 minutes.</li>
    <li>Rest the chicken for 5 minutes before slicing and serving with parsley.</li>
  </ol>
  <div class="wprm-recipe-notes">
    <p>Leftovers keep for 3 days.</p>
    <p>Use low-sodium stock if skipping wine.</p>
  </div>
</body>
</html>
''';

const _visibleAbbreviatedAndFullHtml = '''
<!doctype html>
<html>
<head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Full Step Chicken",
  "recipeIngredient": ["2 chicken breasts", "1 tbsp parsley"],
  "recipeInstructions": ["Cook chicken."]
}
</script>
</head>
<body>
  <section class="recipe-instructions">
    <h3>Abbreviated</h3>
    <ol><li>Season, cook, serve.</li></ol>
  </section>
  <section class="recipe-instructions">
    <h3>Full Recipe</h3>
    <ol>
      <li>Season the chicken on both sides with the spice mix.</li>
      <li>Cook the chicken in butter until golden and cooked through.</li>
    </ol>
  </section>
</body>
</html>
''';

const _howToSectionHtml = '''
<!doctype html>
<html>
<head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Saucy Pasta",
  "recipeIngredient": ["200 g pasta", "1 cup tomato sauce"],
  "recipeInstructions": [
    {
      "@type": "HowToSection",
      "name": "Method",
      "itemListElement": [
        {"@type": "HowToStep", "text": "Boil the pasta until al dente."},
        {"@type": "HowToStep", "text": "Toss pasta with sauce."}
      ]
    }
  ]
}
</script>
</head>
<body></body>
</html>
''';

const _messyIngredientHtml = '''
<!doctype html>
<html>
<head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Messy Ingredient Soup",
  "recipeIngredient": [
    "30g / 1 1/2 tbsp unsalted butter",
    "80ml dry white wine or chicken stock (low sodium), sub water",
    "1 tbsp roughly chopped parsley",
    "0.5 tsp onion powder ()",
    "0.5 tsp garlic powder ()",
    "30g"
  ],
  "recipeInstructions": ["Cook everything."]
}
</script>
</head>
<body></body>
</html>
''';

const _ingredientOnlyJsonLdHtml = '''
<!doctype html>
<html>
<head>
<title>Ingredient Only Pasta</title>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Ingredient Only Pasta",
  "recipeIngredient": ["200 g pasta", "1 cup tomato sauce"]
}
</script>
</head>
<body></body>
</html>
''';

const _ingredientOnlyHeuristicHtml = '''
<!doctype html>
<html>
<head>
  <title>Ingredient Only Heuristic</title>
  <meta property="og:title" content="Ingredient Only Heuristic">
</head>
<body>
  <ul class="recipe-ingredients">
    <li>200 g pasta</li>
    <li>1 cup tomato sauce</li>
  </ul>
</body>
</html>
''';
