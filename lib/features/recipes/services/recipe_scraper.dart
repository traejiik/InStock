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
  final String? notes;
  final String? rawText;

  const ParsedIngredient({
    required this.name,
    required this.quantity,
    this.unit,
    this.isOptional = false,
    this.notes,
    this.rawText,
  });

  ParsedIngredient copyWith({
    String? name,
    double? quantity,
    String? unit,
    bool? isOptional,
    String? notes,
    String? rawText,
  }) => ParsedIngredient(
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    isOptional: isOptional ?? this.isOptional,
    notes: notes ?? this.notes,
    rawText: rawText ?? this.rawText,
  );
}

class ParsedIngredientSection {
  final String? label;
  final List<ParsedIngredient> ingredients;

  const ParsedIngredientSection({this.label, required this.ingredients});
}

class ParsedInstructionSection {
  final String? label;
  final List<String> steps;

  const ParsedInstructionSection({this.label, required this.steps});
}

class ParsedRecipe {
  final String title;
  final String? imageUrl;
  final int? cookTimeMinutes;
  final int baseServings;
  final List<ParsedIngredient> ingredients;
  final List<String> steps;
  final String? sourceUrl;
  final List<ParsedIngredientSection> ingredientSections;
  final List<ParsedInstructionSection> instructionSections;

  const ParsedRecipe({
    required this.title,
    this.imageUrl,
    this.cookTimeMinutes,
    required this.baseServings,
    required this.ingredients,
    required this.steps,
    this.sourceUrl,
    this.ingredientSections = const [],
    this.instructionSections = const [],
  });

  ParsedRecipe copyWith({
    String? title,
    String? imageUrl,
    int? cookTimeMinutes,
    int? baseServings,
    List<ParsedIngredient>? ingredients,
    List<String>? steps,
    String? sourceUrl,
    List<ParsedIngredientSection>? ingredientSections,
    List<ParsedInstructionSection>? instructionSections,
  }) {
    final nextIngredients = ingredients ?? this.ingredients;
    return ParsedRecipe(
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      baseServings: baseServings ?? this.baseServings,
      ingredients: nextIngredients,
      steps: steps ?? this.steps,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      ingredientSections:
          ingredientSections ?? _replaceSectionIngredients(nextIngredients),
      instructionSections: instructionSections ?? this.instructionSections,
    );
  }

  List<ParsedIngredientSection> _replaceSectionIngredients(
    List<ParsedIngredient> nextIngredients,
  ) {
    if (ingredientSections.isEmpty) {
      return [ParsedIngredientSection(ingredients: nextIngredients)];
    }

    var cursor = 0;
    final sections = <ParsedIngredientSection>[];
    for (final section in ingredientSections) {
      final count = section.ingredients.length;
      if (cursor >= nextIngredients.length) {
        sections.add(
          ParsedIngredientSection(label: section.label, ingredients: const []),
        );
        continue;
      }
      final end = (cursor + count).clamp(cursor, nextIngredients.length);
      sections.add(
        ParsedIngredientSection(
          label: section.label,
          ingredients: nextIngredients.sublist(cursor, end),
        ),
      );
      cursor = end;
    }
    if (cursor < nextIngredients.length) {
      sections.add(
        ParsedIngredientSection(ingredients: nextIngredients.sublist(cursor)),
      );
    }
    return sections.where((s) => s.ingredients.isNotEmpty).toList();
  }
}

class RecipeScraper {
  static const _knownUnits = [
    'tablespoons',
    'tablespoon',
    'teaspoons',
    'teaspoon',
    'fluid ounces',
    'fluid ounce',
    'ounces',
    'ounce',
    'grams',
    'gram',
    'kilograms',
    'kilogram',
    'milliliters',
    'milliliter',
    'millilitres',
    'millilitre',
    'litres',
    'litre',
    'cloves',
    'slices',
    'cups',
    'tbsp',
    'tbs',
    'tsp',
    'fl oz',
    'fl_oz',
    'lbs',
    'lb',
    'cup',
    'pcs',
    'pc',
    'oz',
    'kg',
    'ml',
    'clove',
    'slice',
    'pinch',
    'g',
    'l',
  ];

  static const _descriptors = {
    'large',
    'small',
    'medium',
    'whole',
    'skinless',
    'boneless',
    'fresh',
  };

  static const _fractions = {
    '½': 0.5,
    '¼': 0.25,
    '¾': 0.75,
    '⅓': 0.333,
    '⅔': 0.667,
    '⅛': 0.125,
    '⅜': 0.375,
    '⅝': 0.625,
    '⅞': 0.875,
  };

  Future<ParsedRecipe> scrape(String url) async {
    final uri = normalizeUrl(url);
    if (uri == null) {
      throw const RecipeParseException('Invalid URL');
    }

    final http.Response response;
    try {
      response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; InStockApp/1.0)',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw RecipeParseException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw RecipeParseException('HTTP ${response.statusCode}');
    }

    try {
      return parseHtml(response.body, sourceUrl: uri.toString());
    } on RecipeParseException {
      rethrow;
    } catch (e) {
      throw RecipeParseException('Could not extract recipe: $e');
    }
  }

  static Uri? normalizeUrl(String input) {
    var value = input.trim();
    if (value.isEmpty || value.contains(RegExp(r'\s'))) return null;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value)) {
      if (!value.contains('.') || value.startsWith('.')) return null;
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  static ParsedRecipe parseHtml(String html, {required String sourceUrl}) {
    final doc = html_parser.parse(html);
    final pageTitle = doc.querySelector('title')?.text.trim();

    final fromJsonLd = _tryJsonLd(doc, sourceUrl);
    if (fromJsonLd != null && fromJsonLd.ingredients.length >= 2) {
      return fromJsonLd;
    }

    final fromHtml = _tryHeuristic(doc, sourceUrl);
    if (fromHtml != null && fromHtml.ingredients.length >= 2) return fromHtml;

    throw RecipeParseException(
      'Could not extract ingredients from this URL',
      pageTitle: pageTitle,
    );
  }

  static ParsedRecipe? _tryJsonLd(Document doc, String url) {
    final scripts = doc.querySelectorAll('script[type="application/ld+json"]');
    for (final script in scripts) {
      final jsonText = script.text.trim();
      if (jsonText.isEmpty) continue;

      try {
        final json = jsonDecode(jsonText);
        final recipe = _findRecipeNode(json);
        if (recipe == null) continue;

        final title = recipe['name']?.toString().trim() ?? '';
        if (title.isEmpty) continue;

        final ingredientStrings =
            (recipe['recipeIngredient'] as List?)
                ?.map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toList() ??
            [];
        if (ingredientStrings.length < 2) continue;

        final ingredientSections = _parseIngredientSections(ingredientStrings);
        final ingredients = ingredientSections
            .expand((section) => section.ingredients)
            .toList(growable: false);
        final instructionSections = _extractInstructionSections(
          recipe['recipeInstructions'],
        );
        final steps = _chooseSteps(instructionSections);

        return ParsedRecipe(
          title: title,
          imageUrl: _extractImageUrl(recipe['image']),
          cookTimeMinutes: _parseDuration(
            recipe['totalTime']?.toString() ?? recipe['cookTime']?.toString(),
          ),
          baseServings: _parseServings(recipe['recipeYield']),
          ingredients: ingredients,
          steps: steps,
          sourceUrl: url,
          ingredientSections: ingredientSections,
          instructionSections: instructionSections,
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _findRecipeNode(dynamic json) {
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final type = map['@type'];
      if (type == 'Recipe' || (type is List && type.contains('Recipe'))) {
        return map;
      }
      if (map['@graph'] is List) {
        for (final node in map['@graph'] as List) {
          final found = _findRecipeNode(node);
          if (found != null) return found;
        }
      }
      for (final value in map.values) {
        if (value is List || value is Map) {
          final found = _findRecipeNode(value);
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

  static String? _extractImageUrl(dynamic image) {
    if (image == null) return null;
    if (image is String) return image.isNotEmpty ? image : null;
    if (image is List && image.isNotEmpty) return _extractImageUrl(image.first);
    if (image is Map) return image['url']?.toString();
    return null;
  }

  static int? _parseDuration(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(iso);
    if (match == null) return null;
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final total = hours * 60 + minutes;
    return total > 0 ? total : null;
  }

  static int _parseServings(dynamic yield_) {
    if (yield_ == null) return 2;
    final str = yield_ is List ? yield_.first.toString() : yield_.toString();
    final match = RegExp(r'(\d+)').firstMatch(str);
    return int.tryParse(match?.group(1) ?? '') ?? 2;
  }

  static List<ParsedIngredientSection> _parseIngredientSections(
    List<String> lines,
  ) {
    final sections = <ParsedIngredientSection>[];
    String? currentLabel;
    var currentIngredients = <ParsedIngredient>[];

    void flush() {
      if (currentIngredients.isEmpty) return;
      sections.add(
        ParsedIngredientSection(
          label: currentLabel,
          ingredients: List.unmodifiable(currentIngredients),
        ),
      );
      currentIngredients = [];
    }

    for (final raw in lines) {
      final line = _cleanRawText(raw);
      if (line.isEmpty) continue;

      final heading = _ingredientHeadingLabel(line);
      if (heading != null) {
        flush();
        currentLabel = heading;
        continue;
      }

      currentIngredients.add(_parseIngredientString(line));
    }

    flush();
    return sections;
  }

  static String _cleanRawText(String raw) => raw
      .replaceAll(RegExp(r'[\u200b\u200c\u200d]'), '')
      .replaceAll(RegExp(r'^[☐□✓✔\s]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String? _ingredientHeadingLabel(String line) {
    final trimmed = line.trim();
    final noColon = trimmed.replaceFirst(RegExp(r':$'), '').trim();
    if (noColon.isEmpty) return null;
    if (_parseLeadingQuantity(noColon) != null) return null;

    final words = noColon.split(RegExp(r'\s+'));
    final looksLikeHeading =
        trimmed.endsWith(':') ||
        (words.length <= 5 &&
            noColon == noColon.toUpperCase() &&
            RegExp(r'[A-Z]').hasMatch(noColon));
    if (!looksLikeHeading) return null;
    return _sentenceCase(noColon.toLowerCase());
  }

  static List<ParsedInstructionSection> _extractInstructionSections(
    dynamic instructions,
  ) {
    if (instructions == null) return const [];
    if (instructions is String) {
      final cleaned = _cleanStepText(instructions);
      return cleaned.isEmpty
          ? const []
          : [
              ParsedInstructionSection(steps: [cleaned]),
            ];
    }
    if (instructions is! List) return const [];

    final sections = <ParsedInstructionSection>[];
    final flatSteps = <String>[];
    for (final item in instructions) {
      if (item is String) {
        final cleaned = _cleanStepText(item);
        if (cleaned.isNotEmpty) flatSteps.add(cleaned);
        continue;
      }
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final type = map['@type'];
      final isSection =
          type == 'HowToSection' ||
          (type is List && type.contains('HowToSection')) ||
          map['itemListElement'] is List;
      if (isSection) {
        final sectionSteps = _extractInstructionSections(
          map['itemListElement'],
        ).expand((section) => section.steps).toList();
        if (sectionSteps.isNotEmpty) {
          sections.add(
            ParsedInstructionSection(
              label: _cleanNullableText(map['name']),
              steps: sectionSteps,
            ),
          );
        }
        continue;
      }

      final step = _extractStepText(map);
      if (step.isNotEmpty) flatSteps.add(step);
    }

    if (sections.isNotEmpty) return sections;
    return flatSteps.isEmpty
        ? const []
        : [ParsedInstructionSection(steps: flatSteps)];
  }

  static String _extractStepText(Map<String, dynamic> step) {
    final text = _cleanNullableText(step['text']) ?? '';
    final name = _cleanNullableText(step['name']);
    if (text.isEmpty) return name ?? '';
    if (name == null || text.toLowerCase().startsWith(name.toLowerCase())) {
      return _cleanStepText(text);
    }
    return _cleanStepText('$name - $text');
  }

  static List<String> _chooseSteps(List<ParsedInstructionSection> sections) {
    if (sections.isEmpty) return const [];
    final fullRecipe = sections.where((section) {
      final label = section.label?.toLowerCase() ?? '';
      return label.contains('full recipe') || label == 'method';
    }).toList();
    final source = fullRecipe.isNotEmpty ? fullRecipe : sections;
    return source.expand((section) => section.steps).toList(growable: false);
  }

  static String _cleanStepText(String text) =>
      _cleanRawText(text).replaceAll(RegExp(r'^\d+[\.)]\s*'), '').trim();

  static String? _cleanNullableText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : _cleanRawText(text);
  }

  static ParsedRecipe? _tryHeuristic(Document doc, String url) {
    final title =
        doc.querySelector('meta[property="og:title"]')?.attributes['content'] ??
        doc.querySelector('title')?.text ??
        '';
    final imageUrl = doc
        .querySelector('meta[property="og:image"]')
        ?.attributes['content'];

    Element? bestList;
    var bestScore = 0;
    for (final list in doc.querySelectorAll('ul, ol')) {
      final cls = list.className.toLowerCase();
      final id = list.id.toLowerCase();
      if (!cls.contains('ingredient') && !id.contains('ingredient')) continue;

      final items = list.querySelectorAll('li');
      if (items.length > bestScore) {
        bestScore = items.length;
        bestList = list;
      }
    }
    if (bestList == null) return null;

    final ingredientStrings = bestList
        .querySelectorAll('li')
        .map((li) => _cleanRawText(li.text))
        .where((s) => s.isNotEmpty)
        .toList();
    if (ingredientStrings.length < 2) return null;

    final ingredientSections = _parseIngredientSections(ingredientStrings);
    final ingredients = ingredientSections
        .expand((section) => section.ingredients)
        .toList(growable: false);

    var steps = <String>[];
    for (final list in doc.querySelectorAll('ol, ul')) {
      final cls = list.className.toLowerCase();
      final id = list.id.toLowerCase();
      if (cls.contains('instruction') ||
          cls.contains('method') ||
          cls.contains('step') ||
          id.contains('instruction') ||
          id.contains('method') ||
          id.contains('step')) {
        steps = list
            .querySelectorAll('li')
            .map((li) => _cleanStepText(li.text))
            .where((s) => s.isNotEmpty)
            .toList();
        if (steps.isNotEmpty) break;
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
      ingredientSections: ingredientSections,
      instructionSections: steps.isEmpty
          ? const []
          : [ParsedInstructionSection(steps: steps)],
    );
  }

  static ParsedIngredient _parseIngredientString(String raw) {
    final rawText = _cleanRawText(raw);
    final isOptional = RegExp(
      r'\boptional\b',
      caseSensitive: false,
    ).hasMatch(rawText);
    var text = _normalizeFractions(rawText);
    final notes = <String>[];

    text = text.replaceAllMapped(RegExp(r'\(([^()]*)\)'), (match) {
      final note = match.group(1)?.trim();
      if (note != null && note.isNotEmpty) notes.add(note);
      return ' ';
    });
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    double quantity = 1;
    final parsedQuantity = _parseLeadingQuantity(text);
    if (parsedQuantity != null) {
      quantity = parsedQuantity.$1;
      text = text.substring(parsedQuantity.$2).trim();
    }

    String? unit;
    final sortedUnits = [..._knownUnits]..sort((a, b) => b.length - a.length);
    for (final candidate in sortedUnits) {
      final pattern = RegExp(
        '^${RegExp.escape(candidate)}\\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(text)) {
        unit = _normalizeUnit(candidate.toLowerCase());
        text = text.replaceFirst(pattern, '').trim();
        break;
      }
    }

    if (unit == null && parsedQuantity != null) {
      final descriptorMatch = RegExp(r'^([a-zA-Z]+)\b').firstMatch(text);
      final descriptor = descriptorMatch?.group(1)?.toLowerCase();
      if (descriptor != null && _descriptors.contains(descriptor)) {
        text = text.substring(descriptorMatch!.end).trim();
        unit = 'pcs';
      }
    }

    final alternateUnit = RegExp(
      r'\s*/\s*((?:\d+(?:\.\d+)?|\d+\s+\d+/\d+|\d+/\d+)\s*(?:'
      '${_knownUnits.map(RegExp.escape).join('|')})\\b.*)\$',
      caseSensitive: false,
    ).firstMatch(text);
    if (alternateUnit != null) {
      notes.add(alternateUnit.group(1)!.trim());
      text = text.substring(0, alternateUnit.start).trim();
    }

    final orMatch = RegExp(
      r'\s+\bor\b\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (orMatch != null) {
      notes.add('or ${orMatch.group(1)!.trim()}');
      text = text.substring(0, orMatch.start).trim();
    }

    final commaMatch = RegExp(r',\s*(.+)$').firstMatch(text);
    if (commaMatch != null) {
      notes.add(commaMatch.group(1)!.trim());
      text = text.substring(0, commaMatch.start).trim();
    }

    text = text
        .replaceAll(RegExp(r'\boptional\b', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^[,;/\-\s]+'), '')
        .replaceFirst(RegExp(r'[,;/\-\s]+$'), '')
        .trim();

    final name = text.isEmpty ? rawText : _sentenceCase(text);
    final cleanNotes = notes
        .map(
          (note) => note
              .replaceAll(RegExp(r'\boptional\b', caseSensitive: false), '')
              .trim(),
        )
        .where((note) => note.isNotEmpty)
        .join('; ');

    return ParsedIngredient(
      name: name,
      quantity: quantity,
      unit: unit,
      isOptional: isOptional,
      notes: cleanNotes.isEmpty ? null : cleanNotes,
      rawText: rawText,
    );
  }

  static String _normalizeFractions(String input) {
    var text = input;
    for (final entry in _fractions.entries) {
      text = text.replaceAll(entry.key, ' ${entry.value} ');
    }
    text = text.replaceAllMapped(RegExp(r'(\d+)\s*/\s*(\d+)'), (m) {
      final numerator = int.parse(m.group(1)!);
      final denominator = int.parse(m.group(2)!);
      return denominator == 0 ? '$numerator' : '${numerator / denominator}';
    });
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static (double, int)? _parseLeadingQuantity(String text) {
    final mixed = RegExp(
      r'^(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)\b',
    ).firstMatch(text);
    if (mixed != null) {
      final whole = double.tryParse(mixed.group(1)!);
      final fraction = double.tryParse(mixed.group(2)!);
      if (whole != null && fraction != null && fraction < 1) {
        return (whole + fraction, mixed.end);
      }
    }

    final single = RegExp(r'^(\d+(?:\.\d+)?)\b').firstMatch(text);
    if (single == null) return null;
    return (double.tryParse(single.group(1)!) ?? 1, single.end);
  }

  static String _normalizeUnit(String unit) {
    return switch (unit) {
      'tablespoon' || 'tablespoons' || 'tbs' => 'tbsp',
      'teaspoon' || 'teaspoons' => 'tsp',
      'cup' => 'cups',
      'ounce' || 'ounces' => 'oz',
      'gram' || 'grams' => 'g',
      'kilogram' || 'kilograms' => 'kg',
      'milliliter' || 'milliliters' || 'millilitre' || 'millilitres' => 'ml',
      'litre' || 'litres' => 'l',
      'clove' => 'cloves',
      'slice' => 'slices',
      'pc' => 'pcs',
      'lb' => 'lbs',
      'fluid ounce' || 'fluid ounces' || 'fl_oz' => 'fl oz',
      _ => unit,
    };
  }

  static String _sentenceCase(String value) {
    final text = value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
    final converted = raw < 10
        ? double.parse(raw.toStringAsFixed(1))
        : raw.roundToDouble();

    return ingredient.copyWith(quantity: converted, unit: newUnit);
  }

  static List<ParsedIngredient> applyMetricConversion(
    List<ParsedIngredient> ingredients,
  ) => ingredients.map(convertToMetric).toList();
}
