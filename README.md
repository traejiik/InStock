# InStock

InStock is a Flutter app for pantry tracking, recipe management, and grocery shopping. The repository and package are named `instock`, while the current user-facing app title is `Fridge`.

The app is built around a practical loop: keep a pantry inventory, save or import recipes, see what you can make, and send missing ingredients to a shopping list.

## Current Features

- Shopping list grouped by category, source recipe, or a flat list
- Pantry inventory with search, category sorting, quantity sorting, and periodic check-in flow
- Recipe library with makeable-now filtering, tags, cook time, servings, ingredients, and steps
- Manual recipe creation
- Recipe import from URLs using JSON-LD first and heuristic HTML parsing as fallback
- Recipe review flow for imported recipes, including optional ingredients and metric conversion
- Recipe detail screen with missing-ingredient detection and add-to-shopping behavior
- Local persistence through `SharedPreferences`
- Dark Material 3 interface with app-specific color and typography tokens

Settings and AI recipe tools are currently placeholder surfaces. Treat them as product direction, not completed functionality. The app is useful, but let us not put a tuxedo on a TODO.

## Tech Stack

- Flutter
- Material 3
- Riverpod
- go_router with `StatefulShellRoute.indexedStack`
- shared_preferences
- google_fonts
- lucide_icons
- http and html for recipe import

`drift` dependencies are present in `pubspec.yaml`, but the current data layer does not use Drift or SQLite. State is stored as JSON under the `fridge_state_v1` key in `SharedPreferences`.

## Getting Started

Install Flutter, then fetch dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Common desktop/mobile targets:

```bash
flutter run -d macos
flutter run -d ios
```

## Verification

Run these before handing off code changes:

```bash
dart format <changed dart files>
flutter analyze
flutter test
```

For documentation-only changes, tests are usually unnecessary, but checking the diff still is not optional. Future you has enough problems.

## Project Structure

```text
lib/
  app.dart                         # MaterialApp.router root, theme, router
  main.dart                        # AppDatabase init and ProviderScope override
  core/
    router/app_router.dart         # go_router routes and tab shell
    theme/                         # AppColors, AppTextStyles, AppTheme
    utils/unit_converter.dart      # Quantity conversion and stock calculations
  data/
    database/app_database.dart     # ChangeNotifier-backed local data layer
    models/app_models.dart         # Ingredient, pantry, recipe, shopping models
    repositories/                  # Compatibility exports to AppDatabase
  features/
    pantry/                        # Inventory list and check-in flow
    recipes/                       # Recipe list, import, review, detail, editing
    shopping/                      # Shopping list and stock status UI
    settings/                      # Placeholder settings screen
    ai/                            # Placeholder AI tinker sheet
  shared/widgets/                  # App shell, bottom nav, controls, FAB menu
test/
  app_controller_test.dart
  data/repositories/pantry_repository_test.dart
  widget_test.dart
graphify-out/
  GRAPH_REPORT.md                  # Generated knowledge graph report
```

## Architecture Notes

`AppDatabase` is the central state holder. It extends `ChangeNotifier`, owns an `AppState`, serializes that state to JSON, and persists it locally. Widgets should mutate data through `AppDatabase` methods instead of editing lists directly.

Provider setup starts in `main.dart`, where the initialized `AppDatabase` is supplied through Riverpod. Feature provider files for pantry and recipes currently re-export the shopping provider, so do not assume each feature owns a separate provider graph.

Navigation lives in `lib/core/router/app_router.dart`. The bottom tabs are:

- `/` for Shopping
- `/pantry` for Pantry
- `/recipes` for Recipes
- `/settings` for Settings

Standalone routes outside the tab shell are:

- `/recipes/add`
- `/recipes/import`
- `/recipes/review`
- `/recipes/:id`
- `/pantry/checkin`

When adding a route, decide whether it belongs inside the bottom-tab shell. Guessing here is how apps invent navigation mazes.

## Data Model

Core models live in `lib/data/models/app_models.dart`:

- `Ingredient`
- `PantryItem`
- `Recipe`
- `RecipeIngredient`
- `ShoppingItem`
- `AppState`

Ingredient matching uses canonical ingredient IDs and aliases, not raw string equality. Unit conversion and stock calculations belong in `UnitConverter`, not screen widgets.

Checking off a shopping item currently increments pantry quantity. That coupling is intentional in the current workflow, so change it carefully.

## Design System

The canonical design reference is [`design_system.md`](design_system.md). In short:

- Use `AppColors`, `AppTextStyles`, and `AppTheme`
- Keep workflow screens compact, scannable, and dark
- Use status colors for meaning: green for enough, amber for low or partial, red for missing
- Prefer shared controls from `lib/shared/widgets/`
- Avoid one-off colors, oversized decorative layouts, and explanatory UI copy

This is a grocery workflow app, not a landing page for artisanal onions.

## Knowledge Graph

This repo includes a generated graph in `graphify-out/`. Before answering architecture questions or making larger code changes, read:

```text
graphify-out/GRAPH_REPORT.md
```

After modifying code files, update the graph:

```bash
graphify update .
```

Documentation-only edits do not need a graph update.
