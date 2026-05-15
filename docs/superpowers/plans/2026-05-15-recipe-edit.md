# Recipe Edit + UI Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add in-place recipe editing from the detail screen, fix title contrast over images in light mode, and clarify the "Add Missing" bottom-bar button.

**Architecture:** Reuse `RecipeReviewScreen` for editing by adding an optional `editingId` parameter. When set, the screen skips `loadFromParsed` (form state is pre-loaded via a new `loadFromRecipe` notifier method) and calls `AppDatabase.updateRecipe` instead of `saveRecipe` on submit. Navigation passes a Dart record `({ParsedRecipe parsed, String? editingId})` as route `extra` to distinguish create vs. edit flows.

**Tech Stack:** Flutter/Riverpod (`StateNotifierProvider`), go_router, Drift (`_db.delete` for old recipe-ingredient rows), `AppDatabase` in-memory state + Drift persistence.

---

## File Map

| File | Change |
|------|--------|
| `lib/data/database/app_database.dart` | Add `updateRecipe()` |
| `lib/features/recipes/providers/recipe_form_provider.dart` | Add `editingId` to `RecipeFormState`, add `loadFromRecipe()`, modify `save()` |
| `lib/features/recipes/screens/recipe_review_screen.dart` | Add `editingId` param, skip `loadFromParsed` when editing, update title + post-save nav |
| `lib/features/recipes/screens/recipe_detail_screen.dart` | Add edit button, fix title contrast, update "Add Missing" label |
| `lib/features/recipes/screens/add_recipe_screen.dart` | Update `extra` push format |
| `lib/core/router/app_router.dart` | Update review route to parse new `extra` record type |
| `test/widget_test.dart` | Add `editingId: null` to existing `RecipeReviewScreen` test calls |

---

## Task 1: Two quick visual fixes in recipe_detail_screen.dart

**Files:**
- Modify: `lib/features/recipes/screens/recipe_detail_screen.dart:406-418` (title contrast)
- Modify: `lib/features/recipes/screens/recipe_detail_screen.dart:677` (button label)

These are one-liner fixes — no test needed for visual/copy changes.

- [ ] **Step 1: Fix title contrast in `_HeroArea`**

In `recipe_detail_screen.dart`, the title at ~line 406 uses `colors.textPrimary` which is dark in light mode, making it invisible over the gradient scrim. Change the `color` to force white when an image is present:

```dart
// In _HeroArea.build(), find the Text(recipe.title, ...) widget:
Text(
  recipe.title,
  style: AppTextStyles.displayLg.copyWith(
    color: recipe.imageUrl != null ? Colors.white : colors.textPrimary,
    shadows: const [
      Shadow(
        blurRadius: 16,
        color: Color(0xCC000000),
        offset: Offset(0, 2),
      ),
    ],
  ),
),
```

- [ ] **Step 2: Clarify the "Add Missing" button label**

In `_BottomBar.build()` at ~line 677, change the label so it's clear this adds items to the shopping list:

```dart
// Change:
label: '+ Add Missing',
// To:
label: '🛒 Add to List',
```

- [ ] **Step 3: Run analyze and verify**

```bash
flutter analyze lib/features/recipes/screens/recipe_detail_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/recipes/screens/recipe_detail_screen.dart
git commit -m "fix: improve recipe detail title contrast and clarify add-to-list button"
```

---

## Task 2: Add `updateRecipe` to `AppDatabase`

**Files:**
- Modify: `lib/data/database/app_database.dart` (add method after `saveRecipe` at ~line 670)
- Test: `test/app_controller_test.dart` (add a new test group)

**Context:** `_persistFullState` only does `insertOnConflictUpdate` — it never deletes rows. When updating a recipe's ingredients we must explicitly `DELETE FROM recipeIngredients WHERE recipeId = id` via Drift before the new rows are upserted. `updateRecipe` is therefore `async` and calls `_db.delete` directly before calling `_update`.

- [ ] **Step 1: Write the failing test**

In `test/app_controller_test.dart`, add a new test group at the bottom (before the closing `}`):

```dart
group('updateRecipe', () {
  test('updates recipe fields and replaces ingredients', () async {
    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();

    // Create initial recipe
    final id = db.saveRecipe(
      title: 'Original',
      servings: 2,
      cookMinutes: 10,
      difficulty: 'Easy',
      instructions: ['Step 1'],
      ingredients: [
        (
          name: 'Flour',
          quantity: 200.0,
          unit: 'g',
          isOptional: false,
          notes: null,
        ),
      ],
    );

    // Update it
    await db.updateRecipe(
      id: id,
      title: 'Updated',
      servings: 4,
      cookMinutes: 20,
      difficulty: 'Medium',
      instructions: ['Step A', 'Step B'],
      ingredients: [
        (
          name: 'Sugar',
          quantity: 100.0,
          unit: 'g',
          isOptional: false,
          notes: null,
        ),
      ],
    );

    final recipe = db.recipeById(id);
    expect(recipe?.title, 'Updated');
    expect(recipe?.servings, 4);
    expect(recipe?.cookMinutes, 20);
    expect(recipe?.instructions, ['Step A', 'Step B']);

    final ris = db.ingredientsForRecipe(id);
    expect(ris.length, 1);
    final ing = db.ingredientById(ris.first.ingredientId);
    expect(ing?.canonicalName, 'Sugar');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/app_controller_test.dart --name "updates recipe fields and replaces ingredients"
```
Expected: FAIL — `The method 'updateRecipe' isn't defined`

- [ ] **Step 3: Implement `updateRecipe` in `app_database.dart`**

Add this method after `saveRecipe` (around line 670):

```dart
Future<void> updateRecipe({
  required String id,
  required String title,
  required int servings,
  required int cookMinutes,
  required String difficulty,
  required List<String> instructions,
  required List<
    ({
      String name,
      double quantity,
      String unit,
      bool isOptional,
      String? notes,
    })
  >
  ingredients,
  String? sourceUrl,
  String? imageUrl,
  String? notes,
}) async {
  final now = DateTime.now();

  // Hard-delete old recipe ingredients from Drift before upserting new ones.
  // _persistFullState only does insertOnConflictUpdate and would leave stale rows.
  await (_db.delete(_db.recipeIngredients)
        ..where((t) => t.recipeId.equals(id)))
      .go();

  var workingState = _state;

  // Update recipe fields in memory.
  final updatedRecipes = workingState.recipes.map((r) {
    if (r.id != id) return r;
    return r.copyWith(
      title: title,
      instructions: instructions,
      servings: servings,
      cookMinutes: cookMinutes,
      difficulty: difficulty,
      sourceUrl: sourceUrl,
      imageUrl: imageUrl,
      notes: notes,
      updatedAt: now,
    );
  }).toList();
  workingState = workingState.copyWith(recipes: updatedRecipes);

  // Remove old recipe ingredients from in-memory state.
  workingState = workingState.copyWith(
    recipeIngredients: workingState.recipeIngredients
        .where((ri) => ri.recipeId != id)
        .toList(),
  );

  // Re-create recipe ingredients (same lookup/create logic as saveRecipe).
  final newRis = <RecipeIngredient>[];
  for (final ing in ingredients) {
    final normalized = ing.name.trim().toLowerCase();
    var ingredient = workingState.ingredients
        .where(
          (i) =>
              i.canonicalName.toLowerCase() == normalized ||
              i.aliases.any((a) => a.toLowerCase() == normalized),
        )
        .firstOrNull;

    if (ingredient == null) {
      ingredient = Ingredient(
        id: 'ing-${normalized.replaceAll(' ', '-')}-${now.millisecondsSinceEpoch}',
        canonicalName: ing.name.trim(),
        category: IngredientCategory.custom,
        aliases: [],
        createdAt: now,
      );
      workingState = workingState.copyWith(
        ingredients: [...workingState.ingredients, ingredient],
      );
    }

    newRis.add(
      RecipeIngredient(
        id: _uuid.v4(),
        recipeId: id,
        ingredientId: ingredient.id,
        quantity: ing.quantity,
        unit: ing.unit,
        isOptional: ing.isOptional,
        notes: ing.notes,
      ),
    );
  }

  _update(
    workingState.copyWith(
      recipeIngredients: [...workingState.recipeIngredients, ...newRis],
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/app_controller_test.dart --name "updates recipe fields and replaces ingredients"
```
Expected: PASS

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/data/database/app_database.dart test/app_controller_test.dart
git commit -m "feat: add updateRecipe to AppDatabase"
```

---

## Task 3: Extend `RecipeFormState` / `RecipeFormNotifier` for edit mode

**Files:**
- Modify: `lib/features/recipes/providers/recipe_form_provider.dart`
- No separate test file — the `save()` path is tested via the DB test in Task 2; `loadFromRecipe` is pure state manipulation (unit-testable inline).

**Context:** `RecipeFormState` gains an `editingId` field (`null` = create, non-null = update). `loadFromRecipe` populates the form from a live `Recipe` + its `RecipeIngredient` list (needs the `AppDatabase` to resolve ingredient names). `save()` dispatches `updateRecipe` when `editingId != null`.

- [ ] **Step 1: Add `editingId` to `RecipeFormState`**

In `recipe_form_provider.dart`, modify `RecipeFormState`:

```dart
class RecipeFormState {
  final String? editingId; // null = creating new, non-null = editing existing
  final String title;
  final String? imageUrl;
  final int? cookTimeMinutes;
  final int baseServings;
  final List<IngredientFormRow> ingredients;
  final List<String> steps;
  final String notes;
  final String? sourceUrl;
  final bool convertedToMetric;

  const RecipeFormState({
    this.editingId,
    this.title = '',
    this.imageUrl,
    this.cookTimeMinutes,
    this.baseServings = 2,
    this.ingredients = const [],
    this.steps = const [],
    this.notes = '',
    this.sourceUrl,
    this.convertedToMetric = false,
  });

  RecipeFormState copyWith({
    String? editingId,
    bool clearEditingId = false,
    String? title,
    String? imageUrl,
    int? cookTimeMinutes,
    int? baseServings,
    List<IngredientFormRow>? ingredients,
    List<String>? steps,
    String? notes,
    String? sourceUrl,
    bool? convertedToMetric,
  }) => RecipeFormState(
    editingId: clearEditingId ? null : (editingId ?? this.editingId),
    title: title ?? this.title,
    imageUrl: imageUrl ?? this.imageUrl,
    cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
    baseServings: baseServings ?? this.baseServings,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    notes: notes ?? this.notes,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    convertedToMetric: convertedToMetric ?? this.convertedToMetric,
  );
}
```

Note: `reset()` does `state = const RecipeFormState()` which leaves `editingId` as null — correct.

- [ ] **Step 2: Add `loadFromRecipe` to `RecipeFormNotifier`**

Add this method to `RecipeFormNotifier` (after `loadFromParsed`):

```dart
void loadFromRecipe(
  Recipe recipe,
  List<RecipeIngredient> riList,
  AppDatabase db,
) {
  final rows = riList.map((ri) {
    final ing = db.ingredientById(ri.ingredientId);
    return IngredientFormRow(
      name: ing?.canonicalName ?? '',
      quantity: ri.quantity,
      unit: ri.unit,
      isOptional: ri.isOptional,
      notes: ri.notes,
    );
  }).toList();

  state = RecipeFormState(
    editingId: recipe.id,
    title: recipe.title,
    imageUrl: recipe.imageUrl,
    cookTimeMinutes: recipe.cookMinutes == 0 ? null : recipe.cookMinutes,
    baseServings: recipe.servings,
    ingredients: rows,
    steps: List<String>.from(recipe.instructions),
    notes: recipe.notes ?? '',
    sourceUrl: recipe.sourceUrl,
    convertedToMetric: false,
  );
}
```

You'll need to add the `Recipe`, `RecipeIngredient`, and `AppDatabase` imports. `AppDatabase` is already imported via `shopping_provider.dart`. Add at the top of `recipe_form_provider.dart`:

```dart
import '../../../data/database/app_database.dart';
import '../../../data/models/app_models.dart';
```

- [ ] **Step 3: Modify `save()` to call `updateRecipe` when editing**

Replace the `save()` method in `RecipeFormNotifier`:

```dart
Future<String> save() async {
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

  final editId = state.editingId;
  if (editId != null) {
    await db.updateRecipe(
      id: editId,
      title: state.title,
      servings: state.baseServings,
      cookMinutes: state.cookTimeMinutes ?? 0,
      difficulty: 'Medium',
      instructions: state.steps.where((s) => s.isNotEmpty).toList(),
      ingredients: ingredients,
      sourceUrl: state.sourceUrl,
      imageUrl: state.imageUrl,
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
    );
    return editId;
  }

  return db.saveRecipe(
    title: state.title,
    servings: state.baseServings,
    cookMinutes: state.cookTimeMinutes ?? 0,
    difficulty: 'Medium',
    instructions: state.steps.where((s) => s.isNotEmpty).toList(),
    ingredients: ingredients,
    sourceUrl: state.sourceUrl,
    imageUrl: state.imageUrl,
    notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
  );
}
```

- [ ] **Step 4: Run analyze**

```bash
flutter analyze lib/features/recipes/providers/recipe_form_provider.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/recipes/providers/recipe_form_provider.dart
git commit -m "feat: extend RecipeFormState with editingId and loadFromRecipe"
```

---

## Task 4: Update `RecipeReviewScreen` for edit mode

**Files:**
- Modify: `lib/features/recipes/screens/recipe_review_screen.dart`
- Modify: `test/widget_test.dart` (add `editingId: null` where `RecipeReviewScreen` is instantiated)

**Context:** `RecipeReviewScreen` currently always calls `loadFromParsed(widget.parsed)` in `addPostFrameCallback`. When `editingId != null`, form state was pre-loaded by `loadFromRecipe` before navigation — calling `loadFromParsed` again would overwrite the `editingId`. Skip `loadFromParsed` when editing. `_save()` now `await`s the `Future<String>` from `save()` and navigates back to the recipe detail page when editing.

- [ ] **Step 1: Add `editingId` parameter to `RecipeReviewScreen`**

```dart
class RecipeReviewScreen extends ConsumerStatefulWidget {
  final ParsedRecipe parsed;
  final String? editingId;

  const RecipeReviewScreen({
    super.key,
    required this.parsed,
    this.editingId,
  });

  @override
  ConsumerState<RecipeReviewScreen> createState() => _RecipeReviewScreenState();
}
```

- [ ] **Step 2: Update `initState` to skip `loadFromParsed` when editing**

```dart
@override
void initState() {
  super.initState();
  _titleCtrl = TextEditingController(text: widget.parsed.title);
  _cookTimeCtrl = TextEditingController(
    text: widget.parsed.cookTimeMinutes?.toString() ?? '',
  );
  _notesCtrl = TextEditingController(text: widget.parsed.notes ?? '');
  if (widget.editingId == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipeFormProvider.notifier).loadFromParsed(widget.parsed);
    });
  }
}
```

- [ ] **Step 3: Update `_save()` to await and navigate correctly**

```dart
void _save() async {
  final colors = AppColors.of(context);
  final state = ref.read(recipeFormProvider);
  final title = _titleCtrl.text.trim();

  if (title.isEmpty ||
      state.ingredients.where((i) => i.name.isNotEmpty).isEmpty ||
      state.steps.where((s) => s.isNotEmpty).isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Add a title, at least one ingredient, and one step.',
          style: AppTextStyles.bodySm,
        ),
        backgroundColor: colors.surface2,
      ),
    );
    return;
  }

  ref.read(recipeFormProvider.notifier).updateTitle(title);
  final cookMins = int.tryParse(_cookTimeCtrl.text);
  ref.read(recipeFormProvider.notifier).updateCookTime(cookMins);
  ref.read(recipeFormProvider.notifier).updateNotes(_notesCtrl.text);
  final savedId = await ref.read(recipeFormProvider.notifier).save();
  if (!mounted) return;
  if (widget.editingId != null) {
    context.go('/recipes/$savedId');
  } else {
    context.go('/recipes');
  }
}
```

- [ ] **Step 4: Update AppBar title to reflect edit mode**

In `build()`, change the AppBar title line from:

```dart
title: Text('Review Recipe', style: AppTextStyles.headingMd),
```

To:

```dart
title: Text(
  widget.editingId != null ? 'Edit Recipe' : 'Review Recipe',
  style: AppTextStyles.headingMd,
),
```

- [ ] **Step 5: Fix widget tests — `editingId` is optional so no code changes needed**

`RecipeReviewScreen(parsed: ...)` still compiles because `editingId` defaults to `null`. Run tests to confirm:

```bash
flutter test test/widget_test.dart
```
Expected: all tests pass.

- [ ] **Step 6: Run full test suite**

```bash
flutter test
```
Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/recipes/screens/recipe_review_screen.dart
git commit -m "feat: RecipeReviewScreen supports edit mode via editingId param"
```

---

## Task 5: Update `add_recipe_screen.dart` + router for new `extra` record type

**Files:**
- Modify: `lib/features/recipes/screens/add_recipe_screen.dart:677-678`
- Modify: `lib/core/router/app_router.dart:83-85`

**Context:** The `/recipes/review` route `extra` is changing from `ParsedRecipe` to a Dart record `({ParsedRecipe parsed, String? editingId})`. Both `AddRecipeScreen` (create mode) and `RecipeDetailScreen` (edit mode, Task 6) push this route.

- [ ] **Step 1: Update the push in `add_recipe_screen.dart`**

Find the push at ~line 677-678:

```dart
// Before:
ref.read(recipeFormProvider.notifier).loadFromParsed(effective);
context.push('/recipes/review', extra: effective);

// After:
ref.read(recipeFormProvider.notifier).loadFromParsed(effective);
context.push(
  '/recipes/review',
  extra: (parsed: effective, editingId: null as String?),
);
```

- [ ] **Step 2: Update the router to parse the record type**

In `app_router.dart`, update the `/recipes/review` route:

```dart
GoRoute(
  path: '/recipes/review',
  builder: (c, s) {
    final extra =
        s.extra as ({ParsedRecipe parsed, String? editingId});
    return RecipeReviewScreen(
      parsed: extra.parsed,
      editingId: extra.editingId,
    );
  },
),
```

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/features/recipes/screens/add_recipe_screen.dart lib/core/router/app_router.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Run full test suite**

```bash
flutter test
```
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/recipes/screens/add_recipe_screen.dart lib/core/router/app_router.dart
git commit -m "refactor: update /recipes/review extra to typed record supporting editingId"
```

---

## Task 6: Wire edit button in `RecipeDetailScreen`

**Files:**
- Modify: `lib/features/recipes/screens/recipe_detail_screen.dart`

**Context:** Add a `_CircleButton` with a pencil icon next to the delete button. On tap: call `loadFromRecipe` on the form provider, then push `/recipes/review` with the current recipe's data and its `id` as `editingId`. Add a `_recipeToParseRecipe` helper to satisfy `RecipeReviewScreen`'s `parsed` param (the text controllers need it for initialization).

- [ ] **Step 1: Add `_recipeToParseRecipe` helper to `recipe_detail_screen.dart`**

Add this top-level private function just above `class RecipeDetailScreen`:

```dart
ParsedRecipe _recipeToParseRecipe(
  Recipe recipe,
  List<RecipeIngredient> riList,
  AppDatabase db,
) {
  return ParsedRecipe(
    title: recipe.title,
    imageUrl: recipe.imageUrl,
    cookTimeMinutes: recipe.cookMinutes == 0 ? null : recipe.cookMinutes,
    baseServings: recipe.servings,
    ingredients: riList.map((ri) {
      final ing = db.ingredientById(ri.ingredientId);
      return ParsedIngredient(
        name: ing?.canonicalName ?? '',
        quantity: ri.quantity,
        unit: ri.unit,
        isOptional: ri.isOptional,
        notes: ri.notes,
      );
    }).toList(),
    steps: recipe.instructions,
    notes: recipe.notes,
    sourceUrl: recipe.sourceUrl,
  );
}
```

Add missing imports at the top of the file:

```dart
import 'package:go_router/go_router.dart';
import 'package:instock/features/recipes/providers/recipe_form_provider.dart';
import 'package:instock/features/recipes/services/recipe_scraper.dart';
```

- [ ] **Step 2: Add `onEdit` callback to `_HeroArea`**

In `_HeroArea`:

```dart
class _HeroArea extends StatelessWidget {
  final Recipe recipe;
  final bool isMakeable;
  final int missingCount;
  final int servings;
  final VoidCallback onDelete;
  final VoidCallback onEdit;      // ← add
  final VoidCallback onServingsDecrement;
  final VoidCallback onServingsIncrement;

  const _HeroArea({
    required this.recipe,
    required this.isMakeable,
    required this.missingCount,
    required this.servings,
    required this.onDelete,
    required this.onEdit,          // ← add
    required this.onServingsDecrement,
    required this.onServingsIncrement,
  });
```

- [ ] **Step 3: Add the edit `_CircleButton` in `_HeroArea.build()`**

Position it at `left: 60` (where delete currently is), shift delete to `left: 104`:

```dart
// Back button stays at left: 16
Positioned(
  top: MediaQuery.of(context).padding.top + 8,
  left: 16,
  child: _CircleButton(
    onTap: () => Navigator.pop(context),
    child: Icon(Icons.arrow_back, color: colors.textPrimary, size: 20),
  ),
),

// Edit button — new, at left: 60
Positioned(
  top: MediaQuery.of(context).padding.top + 8,
  left: 60,
  child: _CircleButton(
    onTap: onEdit,
    child: Icon(Icons.edit_outlined, color: colors.textPrimary, size: 20),
  ),
),

// Delete button — moved to left: 104
Positioned(
  top: MediaQuery.of(context).padding.top + 8,
  left: 104,
  child: _CircleButton(
    onTap: onDelete,
    child: Icon(Icons.delete_outline, color: colors.red, size: 20),
  ),
),
```

- [ ] **Step 4: Wire `onEdit` in `_RecipeDetailScreenState.build()`**

In the `_HeroArea(...)` call inside `build()`, add the `onEdit` callback:

```dart
_HeroArea(
  recipe: recipe,
  isMakeable: isMakeable,
  missingCount: missingCount,
  servings: _servings,
  onDelete: () => _confirmDelete(recipe.id),
  onEdit: () {
    final db = ref.read(appDatabaseProvider);
    final riList = db.ingredientsForRecipe(recipe.id);
    ref.read(recipeFormProvider.notifier).loadFromRecipe(recipe, riList, db);
    context.push(
      '/recipes/review',
      extra: (
        parsed: _recipeToParseRecipe(recipe, riList, db),
        editingId: recipe.id as String?,
      ),
    );
  },
  onServingsDecrement: () => setState(
    () => _servings = (_servings - 1).clamp(1, 99),
  ),
  onServingsIncrement: () => setState(
    () => _servings = (_servings + 1).clamp(1, 99),
  ),
),
```

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/features/recipes/screens/recipe_detail_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 6: Run full test suite**

```bash
flutter test
```
Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/recipes/screens/recipe_detail_screen.dart
git commit -m "feat: add edit recipe button to recipe detail screen"
```

---

## Self-Review

**Spec coverage:**
- ✅ Edit recipe name/ingredients/steps after saving — Tasks 2, 3, 4, 5, 6
- ✅ Light mode title contrast when there's an image — Task 1
- ✅ Clarify "add missing" button text — Task 1

**Placeholder scan:** No TBD/TODO/placeholder steps — all code is complete.

**Type consistency:**
- `save()` return type changed from `String` to `Future<String>` — `_save()` in `RecipeReviewScreen` uses `await`, consistent.
- `updateRecipe` signature in `app_database.dart` matches the call in `recipe_form_provider.dart` — same named parameters.
- `({ParsedRecipe parsed, String? editingId})` record type is used identically in `add_recipe_screen.dart`, `recipe_detail_screen.dart`, and `app_router.dart`.
- `loadFromRecipe` takes `(Recipe, List<RecipeIngredient>, AppDatabase)` — call site in `recipe_detail_screen.dart` matches.
- `_HeroArea` gets new `onEdit: VoidCallback` — required param, added at the one call site in `build()`.
