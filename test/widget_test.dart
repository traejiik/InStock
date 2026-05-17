import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/app.dart';
import 'package:instock/core/router/app_router.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/database/drift_database.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/data/repositories/app_flags_repository.dart';
import 'package:instock/features/onboarding/providers/onboarding_provider.dart';
import 'package:instock/features/pantry/screens/pantry_screen.dart';
import 'package:instock/features/pantry/widgets/pantry_item_row.dart';
import 'package:instock/features/recipes/providers/recipe_form_provider.dart';
import 'package:instock/features/recipes/screens/add_recipe_screen.dart';
import 'package:instock/features/recipes/screens/recipe_detail_screen.dart';
import 'package:instock/features/recipes/screens/recipe_review_screen.dart';
import 'package:instock/features/recipes/services/recipe_scraper.dart';
import 'package:instock/features/recipes/widgets/recipe_card.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/features/shopping/screens/shopping_screen.dart';
import 'package:instock/features/shopping/widgets/shopping_list_item.dart';
import 'package:instock/shared/widgets/category_picker.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('RecipeCardSm lays out inside a row with unbounded height', (
    tester,
  ) async {
    final recipe = Recipe(
      id: 'recipe-1',
      title: 'Test Recipe',
      emoji: '🍽️',
      instructions: const ['Cook it.'],
      servings: 2,
      cookMinutes: 15,
      difficulty: 'Easy',
      tags: const [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RecipeCardSm(
                        recipe: recipe,
                        isMakeable: true,
                        missingCount: 0,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'CategoryPicker uses a dropdown and emits the selected category',
    (tester) async {
      var selected = IngredientCategory.custom;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPicker(
              selectedCategory: selected,
              onChanged: (category) => selected = category,
            ),
          ),
        ),
      );

      expect(
        find.byType(DropdownButtonFormField<IngredientCategory>),
        findsOneWidget,
      );

      await tester.tap(
        find.byType(DropdownButtonFormField<IngredientCategory>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('🥦 Produce').last);
      await tester.pumpAndSettle();

      expect(selected, IngredientCategory.produce);
    },
  );

  testWidgets('Shopping empty state fits a landscape phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(812, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();
    await db.clearAllData();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: ShoppingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Your list is empty'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.text('Add from Recipe'), findsOneWidget);
  });

  testWidgets('Shopping checkoff undo reverses the pantry update', (
    tester,
  ) async {
    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();
    await db.clearAllData();
    final ingredient = db.findOrCreateIngredient('Sparkling water');
    db.addShoppingItem(ingredientId: ingredient.id, quantity: 6, unit: 'pcs');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const ShoppingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(ShoppingListItem));
    await tester.tapAt(Offset(itemRect.left + 28, itemRect.center.dy));
    await tester.pumpAndSettle();

    expect(db.shoppingItems.single.checked, isTrue);
    expect(db.pantryItemForIngredient(ingredient.id)?.quantity, 6);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(db.shoppingItems.single.checked, isFalse);
    expect(db.pantryItemForIngredient(ingredient.id)?.quantity, 0);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('Shopping checkoff undo prompt does not linger', (tester) async {
    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();
    await db.clearAllData();
    final ingredient = db.findOrCreateIngredient('Sparkling water');
    db.addShoppingItem(ingredientId: ingredient.id, quantity: 6, unit: 'pcs');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
            child: child!,
          ),
          home: const ShoppingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(ShoppingListItem));
    await tester.tapAt(Offset(itemRect.left + 28, itemRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsNothing);
  });

  testWidgets(
    'Shopping list item quick adjust edits quantity, unit, and category',
    (tester) async {
      final db = AppDatabase(db: InStockDriftDb.memory());
      await db.init();
      await db.clearAllData();
      final ingredient = db.findOrCreateIngredient('Soba noodles');
      db.addShoppingItem(
        ingredientId: ingredient.id,
        quantity: 1,
        unit: 'pack',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const ShoppingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(ShoppingListItem));
      await tester.pumpAndSettle();
      expect(find.text('Quick Adjust'), findsOneWidget);

      final quantityField = find.widgetWithText(TextField, 'Quantity');
      expect(quantityField, findsOneWidget);
      await tester.enterText(quantityField, '2.5');
      await tester.tap(find.text('kg'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('📦 Other'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🌾 Grains').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(db.shoppingItems.single.quantity, 2.5);
      expect(db.shoppingItems.single.unit, 'kg');
      expect(
        db.ingredientById(ingredient.id)?.category,
        IngredientCategory.grain,
      );
    },
  );

  testWidgets('Pantry quick adjust edits quantity and unit', (tester) async {
    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();
    await db.clearAllData();
    final ingredient = db.findOrCreateIngredient('Rice');
    db.addOrIncrementPantry(ingredient.id, 10, 'kg');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const PantryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(PantryItemRow));
    await tester.pumpAndSettle();

    final quantityField = find.widgetWithText(TextField, 'Quantity');
    expect(quantityField, findsOneWidget);

    await tester.enterText(quantityField, '750');
    await tester.tap(find.text('g'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final item = db.pantryItemForIngredient(ingredient.id);
    expect(item?.quantity, 750);
    expect(item?.unit, 'g');
  });

  testWidgets('Import Recipe button enables for a normalized recipe URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const AddRecipeScreen(),
        ),
      ),
    );
    await tester.pump();

    GestureDetector importButton() => tester.widget<GestureDetector>(
      find.ancestor(
        of: find.text('Import Recipe'),
        matching: find.byType(GestureDetector),
      ),
    );

    expect(importButton().onTap, isNull);

    await tester.enterText(
      find.byType(TextField).first,
      'recipetineats.com/chicken-breast-recipe/',
    );
    await tester.pump();

    expect(importButton().onTap, isNotNull);
  });

  testWidgets('legacy recipe import route opens the current add/import flow', (
    tester,
  ) async {
    final setup = await _pumpInStockApp(tester);

    setup.router.go('/recipes/import');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Add Recipe'), findsOneWidget);
    expect(find.text('✍️ Write'), findsOneWidget);
    expect(find.text('🔗 Import'), findsOneWidget);
    expect(find.text('AI'), findsNothing);
  });

  testWidgets(
    'recipe review route without extras falls back instead of crashing',
    (tester) async {
      final setup = await _pumpInStockApp(tester);

      setup.router.go('/recipes/review');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add Recipe'), findsOneWidget);
    },
  );

  testWidgets('Recipe review displays imported notes after instructions', (
    tester,
  ) async {
    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();
    await db.clearAllData();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: RecipeReviewScreen(parsed: _parsedRecipeWithNotes()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Instructions'), findsOneWidget);
    expect(find.text('Notes'), findsWidgets);
    expect(find.textContaining('Leftovers keep for 3 days'), findsOneWidget);
  });

  testWidgets('Recipe review saves edited notes', (tester) async {
    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();
    await db.clearAllData();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              RecipeReviewScreen(parsed: _parsedRecipeWithNotes()),
        ),
        GoRoute(
          path: '/recipes',
          builder: (context, state) => const Scaffold(body: Text('Recipes')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    final notesField = find.widgetWithText(TextField, 'Notes');
    expect(notesField, findsOneWidget);

    await tester.enterText(notesField, 'Rest sauce before serving.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(db.recipes.single.notes, 'Rest sauce before serving.');
  });

  testWidgets('Recipe detail shows notes only when present', (tester) async {
    final db = AppDatabase(db: InStockDriftDb.memory());
    await db.init();
    await db.clearAllData();

    final notedId = db.saveRecipe(
      title: 'Noted Chicken',
      servings: 2,
      cookMinutes: 15,
      difficulty: 'Easy',
      instructions: const ['Cook the chicken.'],
      notes: 'Leftovers keep for 3 days.',
      ingredients: const [
        (
          name: 'Chicken breast',
          quantity: 2,
          unit: 'pcs',
          isOptional: false,
          notes: null,
        ),
      ],
    );
    final plainId = db.saveRecipe(
      title: 'Plain Chicken',
      servings: 2,
      cookMinutes: 15,
      difficulty: 'Easy',
      instructions: const ['Cook the chicken.'],
      ingredients: const [
        (
          name: 'Chicken breast',
          quantity: 2,
          unit: 'pcs',
          isOptional: false,
          notes: null,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: RecipeDetailScreen(recipeId: notedId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Leftovers keep for 3 days.'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: RecipeDetailScreen(recipeId: plainId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsNothing);
  });

  testWidgets('Recipe detail edit preloads fields and saves back to detail', (
    tester,
  ) async {
    final setup = await _pumpInStockApp(tester);
    final id = setup.db.saveRecipe(
      title: 'Original Soup',
      servings: 2,
      cookMinutes: 15,
      difficulty: 'Easy',
      instructions: const ['Warm everything together.'],
      notes: 'Use the small pot.',
      ingredients: const [
        (
          name: 'Chicken breast',
          quantity: 2,
          unit: 'pcs',
          isOptional: false,
          notes: null,
        ),
      ],
    );

    setup.router.go('/recipes/$id');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    final formState = setup.container.read(recipeFormProvider);
    expect(find.text('Edit Recipe'), findsOneWidget);
    expect(formState.title, 'Original Soup');
    expect(formState.ingredients.single.name, 'Chicken Breast');
    expect(formState.steps.single, 'Warm everything together.');
    expect(formState.notes, 'Use the small pot.');

    await tester.enterText(find.byType(TextField).first, 'Updated Soup');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Soup'), findsOneWidget);
    expect(find.text('Edit Recipe'), findsNothing);
    expect(setup.db.recipeById(id)?.title, 'Updated Soup');
  });
}

Future<({AppDatabase db, GoRouter router, ProviderContainer container})>
_pumpInStockApp(WidgetTester tester) async {
  final driftDb = InStockDriftDb.memory();
  final db = AppDatabase(db: driftDb);
  await db.init();
  final appFlagsRepository = AppFlagsRepository(driftDb);
  await appFlagsRepository.markOnboardingComplete();
  addTearDown(driftDb.close);

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) => db),
      appFlagsRepositoryProvider.overrideWithValue(appFlagsRepository),
      onboardingInitialStateProvider.overrideWithValue(true),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(appRouterProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const InStockApp()),
  );
  await tester.pumpAndSettle();
  return (db: db, router: router, container: container);
}

ParsedRecipe _parsedRecipeWithNotes() => const ParsedRecipe(
  title: 'Noted Chicken',
  baseServings: 2,
  ingredients: [
    ParsedIngredient(name: 'Chicken breast', quantity: 2, unit: 'pcs'),
  ],
  steps: ['Cook the chicken until golden.'],
  notes: 'Leftovers keep for 3 days.',
);
