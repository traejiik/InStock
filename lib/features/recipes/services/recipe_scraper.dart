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
  final String? notes;
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
    this.notes,
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
    String? notes,
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
      notes: notes ?? this.notes,
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

  static const _prepWords = {
    'roughly',
    'finely',
    'chopped',
    'minced',
    'diced',
    'sliced',
    'grated',
    'crushed',
    'fresh',
    'dry',
    'dried',
    'large',
    'small',
    'medium',
    'regular',
    'sweet',
    'plain',
    'all-purpose',
    'all',
    'purpose',
    'unsalted',
    'cooking',
    'whole',
    'skinless',
    'boneless',
  };

  static const _identityCompounds = {
    'onion powder',
    'garlic powder',
    'black pepper',
    'soy sauce',
    'miso paste',
    'tomato sauce',
    'chicken stock',
    'olive oil',
    'white wine',
    'chicken breast',
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
    if (value.startsWith('<') && value.endsWith('>')) {
      value = value.substring(1, value.length - 1).trim();
    }
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
    if (_isImportableRecipe(fromJsonLd)) {
      return fromJsonLd!;
    }

    final fromHtml = _tryHeuristic(doc, sourceUrl);
    if (_isImportableRecipe(fromHtml)) return fromHtml!;

    if (_hasIngredientCandidate(fromJsonLd) ||
        _hasIngredientCandidate(fromHtml)) {
      throw RecipeParseException(
        'Could not extract instructions from this URL',
        pageTitle: pageTitle,
      );
    }

    throw RecipeParseException(
      'Could not extract ingredients from this URL',
      pageTitle: pageTitle,
    );
  }

  static bool _isImportableRecipe(ParsedRecipe? recipe) =>
      recipe != null &&
      recipe.ingredients.length >= 2 &&
      recipe.steps.isNotEmpty;

  static bool _hasIngredientCandidate(ParsedRecipe? recipe) =>
      recipe != null && recipe.ingredients.length >= 2;

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
        final jsonInstructionSections = _extractInstructionSections(
          recipe['recipeInstructions'],
        );
        final visibleInstructionSections = _extractVisibleInstructionSections(
          doc,
        );
        final instructionSections = _chooseInstructionSections([
          ...jsonInstructionSections,
          ...visibleInstructionSections,
        ]);
        final steps = _chooseSteps(instructionSections);
        final notes =
            _extractRecipeNotesFromJson(recipe) ?? _extractVisibleNotes(doc);

        return ParsedRecipe(
          title: title,
          imageUrl: _extractImageUrl(recipe['image']),
          cookTimeMinutes: _parseDuration(
            recipe['totalTime']?.toString() ?? recipe['cookTime']?.toString(),
          ),
          baseServings: _parseServings(recipe['recipeYield']),
          ingredients: ingredients,
          steps: steps,
          notes: notes,
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

      final ingredient = _parseIngredientString(line);
      if (_isUsefulIngredient(ingredient)) {
        currentIngredients.add(ingredient);
      }
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

  static List<ParsedInstructionSection> _chooseInstructionSections(
    List<ParsedInstructionSection> sections,
  ) {
    if (sections.isEmpty) return const [];
    final useful = sections.where((section) => section.steps.isNotEmpty);
    if (useful.isEmpty) return const [];

    final best = useful.reduce((a, b) {
      return _instructionScore(b) > _instructionScore(a) ? b : a;
    });
    return _instructionScore(best) <= 0 ? const [] : [best];
  }

  static int _instructionScore(ParsedInstructionSection section) {
    final label = section.label?.toLowerCase() ?? '';
    if (RegExp(
      r'\b(abbreviated|summary|quick|overview|short)\b',
    ).hasMatch(label)) {
      return -100000;
    }

    var score = section.steps.length * 100;
    score += section.steps.fold<int>(0, (sum, step) => sum + step.length);
    if (label.contains('full recipe')) score += 1000;
    if (label == 'method' ||
        label.contains('method') ||
        label.contains('instruction')) {
      score += 500;
    }
    return score;
  }

  static List<String> _chooseSteps(List<ParsedInstructionSection> sections) =>
      sections.expand((section) => section.steps).toList(growable: false);

  static String _cleanStepText(String text) => _decodeHtmlEntities(
    _cleanRawText(text).replaceAll(RegExp(r'^\d+[\.)]\s*'), ''),
  ).trim();

  static String? _cleanNullableText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty
        ? null
        : _decodeHtmlEntities(_cleanRawText(text));
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

    final instructionSections = _chooseInstructionSections(
      _extractVisibleInstructionSections(doc),
    );
    final steps = _chooseSteps(instructionSections);

    return ParsedRecipe(
      title: title.trim(),
      imageUrl: imageUrl,
      cookTimeMinutes: null,
      baseServings: 2,
      ingredients: ingredients,
      steps: steps,
      notes: _extractVisibleNotes(doc),
      sourceUrl: url,
      ingredientSections: ingredientSections,
      instructionSections: instructionSections,
    );
  }

  static List<ParsedInstructionSection> _extractVisibleInstructionSections(
    Document doc,
  ) {
    final sections = <ParsedInstructionSection>[];
    final seen = <String>{};

    for (final element in doc.querySelectorAll('section, div, ol, ul')) {
      if (!_looksLikeInstructionElement(element)) continue;
      final steps = _extractVisibleStepTexts(element);
      if (steps.isEmpty) continue;

      final key = steps.join('\n').toLowerCase();
      if (!seen.add(key)) continue;
      sections.add(
        ParsedInstructionSection(
          label: _visibleSectionLabel(element),
          steps: steps,
        ),
      );
    }

    return sections;
  }

  static bool _looksLikeInstructionElement(Element element) {
    final token = '${element.id} ${element.className}'.toLowerCase();
    if (RegExp(
      r'\b(ingredient|nutrition|comment|review|note|notes)\b',
    ).hasMatch(token)) {
      return false;
    }
    return token.contains('instruction') ||
        token.contains('direction') ||
        token.contains('method') ||
        token.contains('step');
  }

  static List<String> _extractVisibleStepTexts(Element element) {
    final listItems = element.localName == 'ol' || element.localName == 'ul'
        ? element.children.where((child) => child.localName == 'li')
        : element.querySelectorAll('li');

    return listItems
        .map((li) => _cleanStepText(li.text))
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
  }

  static String? _visibleSectionLabel(Element element) {
    final heading = element.querySelector('h1,h2,h3,h4,h5,h6')?.text;
    final aria = element.attributes['aria-label'];
    final text = heading ?? aria;
    final cleaned = _cleanNullableText(text);
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static String? _extractRecipeNotesFromJson(Map<String, dynamic> recipe) {
    const keys = ['notes', 'recipeNotes', 'recipeNote'];
    final parts = <String>[];
    for (final key in keys) {
      final value = recipe[key];
      if (value == null) continue;
      if (value is List) {
        parts.addAll(
          value
              .map((item) => _cleanNoteText(item.toString()))
              .where((note) => note.isNotEmpty),
        );
      } else {
        final note = _cleanNoteText(value.toString());
        if (note.isNotEmpty) parts.add(note);
      }
    }
    return parts.isEmpty ? null : _dedupeLines(parts).join('\n');
  }

  static String? _extractVisibleNotes(Document doc) {
    final parts = <String>[];
    final seen = <String>{};
    for (final element in doc.querySelectorAll('section, div')) {
      final token = '${element.id} ${element.className}'.toLowerCase();
      final hasNotesToken =
          token.contains('recipe-notes') ||
          token.contains('recipe_notes') ||
          token.contains('recipe notes') ||
          token.contains('wprm-recipe-notes') ||
          token.contains('tasty-recipes-notes') ||
          RegExp(r'(^|\s)notes?($|\s)').hasMatch(token);
      if (!hasNotesToken) continue;
      if (RegExp(
        r'\b(ingredient|instruction|nutrition|comment|review)\b',
      ).hasMatch(token)) {
        continue;
      }

      final notes = _extractVisibleNoteLines(element);
      final key = notes.join('\n').toLowerCase();
      if (notes.isEmpty || !seen.add(key)) continue;
      parts.addAll(notes);
    }
    final deduped = _dedupeLines(parts);
    return deduped.isEmpty ? null : deduped.join('\n');
  }

  static List<String> _extractVisibleNoteLines(Element element) {
    final children = element.querySelectorAll('p, li');
    final source = children.isEmpty ? [element] : children;
    return source
        .map((node) => _cleanNoteText(node.text))
        .where((note) => note.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _dedupeLines(List<String> lines) {
    final seen = <String>{};
    final result = <String>[];
    for (final line in lines) {
      final key = line.toLowerCase();
      if (seen.add(key)) result.add(line);
    }
    return result;
  }

  static String _decodeHtmlEntities(String text) =>
      html_parser.parseFragment(text).text ?? text;

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
    text = _cleanIngredientFragment(text);

    double quantity = 1;
    final parsedQuantity = _parseLeadingQuantity(text);
    if (parsedQuantity != null) {
      quantity = parsedQuantity.$1;
      text = text.substring(parsedQuantity.$2).trim();
    }

    String? unit;
    final parsedUnit = _parseLeadingUnit(text);
    if (parsedUnit != null) {
      unit = parsedUnit.$1;
      text = text.substring(parsedUnit.$2).trim();
    }

    if (unit == null && parsedQuantity != null) {
      final descriptorMatch = RegExp(r'^([a-zA-Z]+)\b').firstMatch(text);
      final descriptor = descriptorMatch?.group(1)?.toLowerCase();
      if (descriptor != null && _descriptors.contains(descriptor)) {
        text = text.substring(descriptorMatch!.end).trim();
        unit = 'pcs';
      }
    }

    text = _extractLeadingAlternateMeasure(text, notes);
    text = _extractTrailingAlternateMeasure(text, notes);

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

    text = _cleanIngredientFragment(
      text.replaceAll(RegExp(r'\boptional\b', caseSensitive: false), ''),
    );

    final name = _canonicalIngredientName(text);
    final cleanNotes = notes
        .map(_cleanNoteText)
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
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static (double, int)? _parseLeadingQuantity(String text) {
    final mixedFraction = RegExp(
      r'^(\d+(?:\.\d+)?)\s+(\d+)\s*/\s*(\d+)(?=\D|$)',
    ).firstMatch(text);
    if (mixedFraction != null) {
      final whole = double.tryParse(mixedFraction.group(1)!);
      final numerator = int.tryParse(mixedFraction.group(2)!);
      final denominator = int.tryParse(mixedFraction.group(3)!);
      if (whole != null &&
          numerator != null &&
          denominator != null &&
          denominator != 0) {
        return (whole + (numerator / denominator), mixedFraction.end);
      }
    }

    final fraction = RegExp(r'^(\d+)\s*/\s*(\d+)(?=\D|$)').firstMatch(text);
    if (fraction != null) {
      final numerator = int.tryParse(fraction.group(1)!);
      final denominator = int.tryParse(fraction.group(2)!);
      if (numerator != null && denominator != null && denominator != 0) {
        return (numerator / denominator, fraction.end);
      }
    }

    final mixed = RegExp(
      r'^(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)(?=\D|$)',
    ).firstMatch(text);
    if (mixed != null) {
      final whole = double.tryParse(mixed.group(1)!);
      final fraction = double.tryParse(mixed.group(2)!);
      if (whole != null && fraction != null && fraction < 1) {
        return (whole + fraction, mixed.end);
      }
    }

    final single = RegExp(r'^(\d+(?:\.\d+)?)(?=\D|$)').firstMatch(text);
    if (single == null) return null;
    return (double.tryParse(single.group(1)!) ?? 1, single.end);
  }

  static (String, int)? _parseLeadingUnit(String text) {
    final sortedUnits = [..._knownUnits]..sort((a, b) => b.length - a.length);
    for (final candidate in sortedUnits) {
      final pattern = RegExp(
        '^${RegExp.escape(candidate)}(?=\\s|\$|[,;/)\\-])',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      if (match != null) {
        return (_normalizeUnit(candidate.toLowerCase()), match.end);
      }
    }
    return null;
  }

  static String _extractLeadingAlternateMeasure(
    String text,
    List<String> notes,
  ) {
    var remaining = text.trim();
    while (remaining.startsWith('/')) {
      final alternate = remaining.substring(1).trimLeft();
      final quantity = _parseLeadingQuantity(alternate);
      if (quantity == null) break;

      final afterQuantity = alternate.substring(quantity.$2).trimLeft();
      final unit = _parseLeadingUnit(afterQuantity);
      if (unit == null) break;

      final consumedLength =
          quantity.$2 +
          alternate.substring(quantity.$2).length -
          afterQuantity.substring(unit.$2).trimLeft().length;
      final note = alternate.substring(0, consumedLength).trim();
      if (note.isNotEmpty) notes.add(note);
      remaining = afterQuantity.substring(unit.$2).trimLeft();
    }
    return remaining;
  }

  static String _extractTrailingAlternateMeasure(
    String text,
    List<String> notes,
  ) {
    final slashIndex = text.lastIndexOf('/');
    if (slashIndex < 0) return text;

    final alternate = text.substring(slashIndex + 1).trimLeft();
    final quantity = _parseLeadingQuantity(alternate);
    if (quantity == null) return text;

    final afterQuantity = alternate.substring(quantity.$2).trimLeft();
    final unit = _parseLeadingUnit(afterQuantity);
    if (unit == null) return text;

    notes.add(alternate.trim());
    return text.substring(0, slashIndex).trimRight();
  }

  static String _cleanIngredientFragment(String text) => text
      .replaceAll(RegExp(r'\(\s*\)'), ' ')
      .replaceAll(RegExp(r'[()]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(RegExp(r'^[,;/\-\s]+'), '')
      .replaceFirst(RegExp(r'[,;/\-\s]+$'), '')
      .trim();

  static String _cleanNoteText(String text) => _cleanIngredientFragment(
    text.replaceAll(RegExp(r'\boptional\b', caseSensitive: false), ''),
  );

  static bool _isUsefulIngredient(ParsedIngredient ingredient) {
    final name = ingredient.name.trim();
    if (name.isEmpty) return false;
    if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(name)) return false;
    return true;
  }

  static String _canonicalIngredientName(String text) {
    var candidate = _cleanIngredientFragment(text).toLowerCase();
    if (candidate.isEmpty) return '';

    candidate = candidate
        .replaceAll(RegExp(r'\bsub(?:stitute)?\b.*$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (candidate.isEmpty) return '';

    final primary = candidate.split(RegExp(r'\s*/\s*')).first.trim();
    final tokens = primary
        .split(RegExp(r'[^a-zA-Z-]+'))
        .where((token) => token.isNotEmpty)
        .where((token) => !_prepWords.contains(token))
        .toList();
    if (tokens.isEmpty) return '';

    var reduced = _normalizeIngredientPlurals(tokens.join(' '));
    final compound = _findIdentityCompound(reduced);
    if (compound != null) return _sentenceCase(compound);

    if (reduced.split(' ').contains('salt')) {
      return 'Salt';
    }

    return _sentenceCase(reduced);
  }

  static String? _findIdentityCompound(String text) {
    for (final compound in _identityCompounds) {
      final pattern = RegExp(
        r'(^|\s)' + RegExp.escape(compound) + r'($|\s)',
        caseSensitive: false,
      );
      if (pattern.hasMatch(text)) return compound;
    }
    return null;
  }

  static String _normalizeIngredientPlurals(String text) {
    return text
        .replaceAll(RegExp(r'\bbreasts\b'), 'breast')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
