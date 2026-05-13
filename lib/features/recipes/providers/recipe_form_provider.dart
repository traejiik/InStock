import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recipe_scraper.dart';
import '../../../features/shopping/providers/shopping_provider.dart';

class IngredientFormRow {
  final String name;
  final double quantity;
  final String? unit;
  final bool isOptional;
  final String? notes;
  final String? sectionLabel;

  const IngredientFormRow({
    required this.name,
    required this.quantity,
    this.unit,
    this.isOptional = false,
    this.notes,
    this.sectionLabel,
  });

  IngredientFormRow copyWith({
    String? name,
    double? quantity,
    String? unit,
    bool? isOptional,
    String? notes,
    String? sectionLabel,
  }) => IngredientFormRow(
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    isOptional: isOptional ?? this.isOptional,
    notes: notes ?? this.notes,
    sectionLabel: sectionLabel ?? this.sectionLabel,
  );
}

class RecipeFormState {
  final String title;
  final String? imageUrl;
  final int? cookTimeMinutes;
  final int baseServings;
  final List<IngredientFormRow> ingredients;
  final List<String> steps;
  final String? sourceUrl;
  final bool convertedToMetric;

  const RecipeFormState({
    this.title = '',
    this.imageUrl,
    this.cookTimeMinutes,
    this.baseServings = 2,
    this.ingredients = const [],
    this.steps = const [],
    this.sourceUrl,
    this.convertedToMetric = false,
  });

  RecipeFormState copyWith({
    String? title,
    String? imageUrl,
    int? cookTimeMinutes,
    int? baseServings,
    List<IngredientFormRow>? ingredients,
    List<String>? steps,
    String? sourceUrl,
    bool? convertedToMetric,
  }) => RecipeFormState(
    title: title ?? this.title,
    imageUrl: imageUrl ?? this.imageUrl,
    cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
    baseServings: baseServings ?? this.baseServings,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    convertedToMetric: convertedToMetric ?? this.convertedToMetric,
  );
}

class RecipeFormNotifier extends StateNotifier<RecipeFormState> {
  final Ref _ref;

  RecipeFormNotifier(this._ref) : super(const RecipeFormState());

  void loadFromParsed(ParsedRecipe parsed) {
    final parsedRows = parsed.ingredientSections.isEmpty
        ? parsed.ingredients
              .map(
                (i) => IngredientFormRow(
                  name: i.name,
                  quantity: i.quantity,
                  unit: i.unit,
                  isOptional: i.isOptional,
                  notes: i.notes,
                ),
              )
              .toList()
        : parsed.ingredientSections.expand((section) sync* {
            for (var i = 0; i < section.ingredients.length; i++) {
              final ingredient = section.ingredients[i];
              yield IngredientFormRow(
                name: ingredient.name,
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                isOptional: ingredient.isOptional,
                notes: ingredient.notes,
                sectionLabel: i == 0 ? section.label : null,
              );
            }
          }).toList();

    state = RecipeFormState(
      title: parsed.title,
      imageUrl: parsed.imageUrl,
      cookTimeMinutes: parsed.cookTimeMinutes,
      baseServings: parsed.baseServings,
      ingredients: parsedRows,
      steps: List<String>.from(parsed.steps),
      sourceUrl: parsed.sourceUrl,
      convertedToMetric: false,
    );
  }

  void updateTitle(String title) => state = state.copyWith(title: title);

  void updateServings(int servings) =>
      state = state.copyWith(baseServings: servings.clamp(1, 99));

  void updateCookTime(int? minutes) =>
      state = state.copyWith(cookTimeMinutes: minutes);

  void addIngredient() => state = state.copyWith(
    ingredients: [
      ...state.ingredients,
      const IngredientFormRow(name: '', quantity: 1),
    ],
  );

  void removeIngredient(int index) {
    final list = List<IngredientFormRow>.from(state.ingredients)
      ..removeAt(index);
    state = state.copyWith(ingredients: list);
  }

  void reorderIngredients(int oldIndex, int newIndex) {
    final list = List<IngredientFormRow>.from(state.ingredients);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(ingredients: list);
  }

  void updateIngredient(int index, IngredientFormRow row) {
    final list = List<IngredientFormRow>.from(state.ingredients)..[index] = row;
    state = state.copyWith(ingredients: list);
  }

  void addStep() => state = state.copyWith(steps: [...state.steps, '']);

  void removeStep(int index) {
    final list = List<String>.from(state.steps)..removeAt(index);
    state = state.copyWith(steps: list);
  }

  void reorderSteps(int oldIndex, int newIndex) {
    final list = List<String>.from(state.steps);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(steps: list);
  }

  void updateStep(int index, String text) {
    final list = List<String>.from(state.steps)..[index] = text;
    state = state.copyWith(steps: list);
  }

  void applyMetricConversion() {
    if (state.convertedToMetric) return;
    final converted = state.ingredients.map((row) {
      final result = RecipeScraper.convertToMetric(
        ParsedIngredient(
          name: row.name,
          quantity: row.quantity,
          unit: row.unit,
          notes: row.notes,
        ),
      );
      return row.copyWith(
        quantity: result.quantity,
        unit: result.unit,
        notes: result.notes,
      );
    }).toList();
    state = state.copyWith(ingredients: converted, convertedToMetric: true);
  }

  void undoMetricConversion(List<IngredientFormRow> original) {
    state = state.copyWith(ingredients: original, convertedToMetric: false);
  }

  String save() {
    final db = _ref.read(appDatabaseProvider);
    final ingredients = state.ingredients
        .where((i) => i.name.isNotEmpty)
        .map(
          (i) => (
            name: i.name,
            quantity: i.quantity,
            unit: i.unit ?? 'pcs',
            isOptional: i.isOptional,
            notes: i.notes,
          ),
        )
        .toList();

    return db.saveRecipe(
      title: state.title,
      servings: state.baseServings,
      cookMinutes: state.cookTimeMinutes ?? 0,
      difficulty: 'Medium',
      instructions: state.steps.where((s) => s.isNotEmpty).toList(),
      ingredients: ingredients,
      sourceUrl: state.sourceUrl,
      imageUrl: state.imageUrl,
    );
  }
}

final recipeFormProvider =
    StateNotifierProvider<RecipeFormNotifier, RecipeFormState>(
      (ref) => RecipeFormNotifier(ref),
    );
