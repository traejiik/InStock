import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class RecipeParseException implements Exception {
  final String message;
  final String? pageTitle;
  const RecipeParseException(this.message, {this.pageTitle});

  @override
  String toString() => 'RecipeParseException: $message';
}

class ParsedIngredient {
  final String name;
  final double quantity;
  final String? unit;
  final bool isOptional;

  const ParsedIngredient({
    required this.name,
    required this.quantity,
    this.unit,
    this.isOptional = false,
  });

  ParsedIngredient copyWith({
    String? name,
    double? quantity,
    String? unit,
    bool? isOptional,
  }) =>
      ParsedIngredient(
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        isOptional: isOptional ?? this.isOptional,
      );
}

class ParsedRecipe {
  final String title;
  final String? imageUrl;
  final int? cookTimeMinutes;
  final int baseServings;
  final List<ParsedIngredient> ingredients;
  final List<String> steps;
  final String? sourceUrl;

  const ParsedRecipe({
    required this.title,
    this.imageUrl,
    this.cookTimeMinutes,
    required this.baseServings,
    required this.ingredients,
    required this.steps,
    this.sourceUrl,
  });

  ParsedRecipe copyWith({
    String? title,
    String? imageUrl,
    int? cookTimeMinutes,
    int? baseServings,
    List<ParsedIngredient>? ingredients,
    List<String>? steps,
    String? sourceUrl,
  }) =>
      ParsedRecipe(
        title: title ?? this.title,
        imageUrl: imageUrl ?? this.imageUrl,
        cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
        baseServings: baseServings ?? this.baseServings,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        sourceUrl: sourceUrl ?? this.sourceUrl,
      );
}

class RecipeScraper {
  static const _knownUnits = [
    'fl oz', 'fl_oz',
    'cloves', 'slices', 'cups', 'lbs',
    'tbsp', 'tsp', 'cup', 'pcs', 'oz', 'kg', 'ml', 'lb', 'pc',
    'clove', 'slice', 'pinch', 'g', 'l',
  ];

  static const _fractions = {
    '½': 0.5, '¼': 0.25, '¾': 0.75,
    '⅓': 0.333, '⅔': 0.667,
    '⅛': 0.125, '⅜': 0.375, '⅝': 0.625, '⅞': 0.875,
  };

  Future<ParsedRecipe> scrape(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      throw const RecipeParseException('Invalid URL');
    }

    final http.Response response;
    try {
      response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; FridgeApp/1.0)',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw RecipeParseException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw RecipeParseException('HTTP ${response.statusCode}');
    }

    final doc = html_parser.parse(response.body);
    final pageTitle = doc.querySelector('title')?.text.trim();

    try {
      final result = _tryJsonLd(doc, url);
      if (result != null && result.ingredients.length >= 2) return result;
    } catch (_) {}

    try {
      final result = _tryHeuristic(doc, url);
      if (result != null && result.ingredients.length >= 2) return result;
    } catch (_) {}

    throw RecipeParseException(
      'Could not extract ingredients from this URL',
      pageTitle: pageTitle,
    );
  }

  ParsedRecipe? _tryJsonLd(Document doc, String url) {
    final scripts = doc.querySelectorAll('script[type="application/ld+json"]');
    for (final script in scripts) {
      try {
        final json = jsonDecode(script.text);
        final recipe = _findRecipeNode(json);
        if (recipe == null) continue;

        final title = recipe['name'] as String? ?? '';
        if (title.isEmpty) continue;

        final imageUrl = _extractImageUrl(recipe['image']);
        final cookTime = _parseDuration(
          recipe['totalTime'] as String? ?? recipe['cookTime'] as String?,
        );
        final servings = _parseServings(recipe['recipeYield']);

        final ingredientStrings =
            (recipe['recipeIngredient'] as List?)?.cast<String>() ?? [];
        final ingredients = ingredientStrings.map(_parseIngredientString).toList();

        final steps = _extractSteps(recipe['recipeInstructions']);

        return ParsedRecipe(
          title: title,
          imageUrl: imageUrl,
          cookTimeMinutes: cookTime,
          baseServings: servings,
          ingredients: ingredients,
          steps: steps,
          sourceUrl: url,
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findRecipeNode(dynamic json) {
    if (json is Map<String, dynamic>) {
      final type = json['@type'];
      if (type == 'Recipe' || (type is List && type.contains('Recipe'))) {
        return json;
      }
      if (json['@graph'] is List) {
        for (final node in json['@graph'] as List) {
          final found = _findRecipeNode(node);
          if (found != null) return found;
        }
      }
    }
    if (json is List) {
      for (final item in json) {
        final found = _findRecipeNode(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _extractImageUrl(dynamic image) {
    if (image == null) return null;
    if (image is String) return image.isNotEmpty ? image : null;
    if (image is List && image.isNotEmpty) return _extractImageUrl(image.first);
    if (image is Map) return image['url'] as String?;
    return null;
  }

  int? _parseDuration(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(iso);
    if (match == null) return null;
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final total = hours * 60 + minutes;
    return total > 0 ? total : null;
  }

  int _parseServings(dynamic yield_) {
    if (yield_ == null) return 2;
    final str = yield_ is List ? yield_.first.toString() : yield_.toString();
    final match = RegExp(r'(\d+)').firstMatch(str);
    return int.tryParse(match?.group(1) ?? '') ?? 2;
  }

  List<String> _extractSteps(dynamic instructions) {
    if (instructions == null) return [];
    if (instructions is String) return [instructions];
    if (instructions is List) {
      return instructions.map((step) {
        if (step is String) return step.trim();
        if (step is Map) {
          final text = step['text'] as String?;
          if (text != null && text.isNotEmpty) return text.trim();
          final name = step['name'] as String?;
          return name?.trim() ?? '';
        }
        return step.toString().trim();
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  ParsedRecipe? _tryHeuristic(Document doc, String url) {
    final title =
        doc.querySelector('meta[property="og:title"]')?.attributes['content'] ??
            doc.querySelector('title')?.text ??
            '';
    final imageUrl =
        doc.querySelector('meta[property="og:image"]')?.attributes['content'];

    final allLists = doc.querySelectorAll('ul, ol');
    Element? bestList;
    int bestScore = 0;

    for (final list in allLists) {
      final cls = list.className.toLowerCase();
      final id = list.id.toLowerCase();
      if (cls.contains('ingredient') || id.contains('ingredient')) {
        final items = list.querySelectorAll('li');
        if (items.length > bestScore) {
          bestScore = items.length;
          bestList = list;
        }
      }
    }

    if (bestList == null) return null;

    final ingredientStrings = bestList
        .querySelectorAll('li')
        .map((li) => li.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (ingredientStrings.length < 2) return null;

    final ingredients = ingredientStrings.map(_parseIngredientString).toList();

    List<String> steps = [];
    for (final list in doc.querySelectorAll('ol')) {
      final cls = list.className.toLowerCase();
      final id = list.id.toLowerCase();
      if (cls.contains('instruction') ||
          cls.contains('step') ||
          id.contains('instruction') ||
          id.contains('step')) {
        final extracted = list
            .querySelectorAll('li')
            .map((li) => li.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (extracted.isNotEmpty) {
          steps = extracted;
          break;
        }
      }
    }

    return ParsedRecipe(
      title: title.trim(),
      imageUrl: imageUrl,
      cookTimeMinutes: null,
      baseServings: 2,
      ingredients: ingredients,
      steps: steps,
      sourceUrl: url,
    );
  }

  ParsedIngredient _parseIngredientString(String raw) {
    // ── 1. Detect optional before any mutation ───────────────────────────────
    final isOptional =
        RegExp(r'\boptional\b', caseSensitive: false).hasMatch(raw);

    var text = raw.trim();

    // ── 2. Fraction substitution ──────────────────────────────────────────────
    for (final entry in _fractions.entries) {
      text = text.replaceAll(entry.key, '${entry.value}');
    }

    text = text.replaceAllMapped(
      RegExp(r'(\d+)\s*/\s*(\d+)'),
      (m) {
        final num = int.parse(m.group(1)!);
        final den = int.parse(m.group(2)!);
        return den != 0 ? '${num / den}' : '$num';
      },
    );

    // ── 3. Quantity parsing ───────────────────────────────────────────────────
    double quantity = 1;
    final qtyMatch = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(text);
    if (qtyMatch != null) {
      quantity = double.tryParse(qtyMatch.group(1)!) ?? 1;
      text = text.substring(qtyMatch.end).trim();
      final mixedMatch = RegExp(r'^(0\.\d+)\s').firstMatch(text);
      if (mixedMatch != null) {
        quantity += double.tryParse(mixedMatch.group(1)!) ?? 0;
        text = text.substring(mixedMatch.end).trim();
      }
    }

    // ── 4. Unit parsing ───────────────────────────────────────────────────────
    String? unit;
    for (final u in _knownUnits) {
      final pattern = RegExp('^${RegExp.escape(u)}\\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        unit = _normalizeUnit(u.toLowerCase());
        text = text.replaceFirst(pattern, '').trim();
        break;
      }
    }

    // ── 5. Name cleaner ───────────────────────────────────────────────────────
    // Strip double parentheticals: ((anything))
    text = text.replaceAll(RegExp(r'\(\([^)]*\)\)', dotAll: true), '').trim();

    // Strip single parentheticals: (anything)
    text = text.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

    // Strip the word "optional" (already detected above)
    text = text.replaceAll(RegExp(r'\boptional\b', caseSensitive: false), '').trim();

    // Strip leading punctuation, dashes, commas
    text = text.replaceFirst(RegExp(r'^[,;\-\s]+'), '').trim();

    // Strip trailing commas, conjunctions, prepositions
    text = text.replaceFirst(
      RegExp(r'[,;\s]+(and|or|to|with|plus|more|for)?[,;\s]*$',
          caseSensitive: false),
      '',
    ).trim();

    // Capitalise first letter
    final name = text.isNotEmpty
        ? text[0].toUpperCase() + text.substring(1)
        : raw.trim();

    // ── 6. Return ─────────────────────────────────────────────────────────────
    return ParsedIngredient(
      name: name.isNotEmpty ? name : raw.trim(),
      quantity: quantity,
      unit: unit,
      isOptional: isOptional,
    );
  }

  String _normalizeUnit(String u) {
    return switch (u) {
      'cup' => 'cups',
      'clove' => 'cloves',
      'slice' => 'slices',
      'pc' => 'pcs',
      'lb' => 'lbs',
      'fl_oz' => 'fl oz',
      _ => u,
    };
  }

  static ParsedIngredient convertToMetric(ParsedIngredient ingredient) {
    final unit = ingredient.unit?.toLowerCase();
    if (unit == null) return ingredient;

    double? factor;
    String? newUnit;

    switch (unit) {
      case 'cups':
      case 'cup':
        factor = 240;
        newUnit = 'ml';
      case 'tbsp':
        factor = 15;
        newUnit = 'ml';
      case 'tsp':
        factor = 5;
        newUnit = 'ml';
      case 'oz':
        factor = 28.35;
        newUnit = 'g';
      case 'lbs':
      case 'lb':
        factor = 453.6;
        newUnit = 'g';
      case 'fl oz':
      case 'fl_oz':
        factor = 29.57;
        newUnit = 'ml';
    }

    if (factor == null || newUnit == null) return ingredient;

    final raw = ingredient.quantity * factor;
    final converted =
        raw < 10 ? double.parse(raw.toStringAsFixed(1)) : raw.roundToDouble();

    return ParsedIngredient(name: ingredient.name, quantity: converted, unit: newUnit);
  }

  static List<ParsedIngredient> applyMetricConversion(
    List<ParsedIngredient> ingredients,
  ) =>
      ingredients.map(convertToMetric).toList();
}
