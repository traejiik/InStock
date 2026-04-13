# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on a connected device or simulator
flutter run

# Run on a specific platform
flutter run -d macos
flutter run -d ios

# Build
flutter build macos
flutter build ios

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Get dependencies
flutter pub get
```

## Architecture

InStock is a Flutter app (Material 3, dark theme) for pantry tracking, recipe management, and grocery shopping with AI-assisted recipe generation.

### State Management

The app uses **Riverpod** (`flutter_riverpod`) with a single `AppController` class that acts as the entire backend:

- `AppController` (`lib/core/data/app_controller.dart`) extends `ChangeNotifier` and implements four repository interfaces: `RecipeRepository`, `PantryRepository`, `ShoppingListRepository`, and `AiRecipeService`.
- All state lives in `PersistedState` — an immutable value object serialized to JSON and stored via `shared_preferences` under the key `instock_state_v1`.
- Every mutation follows the same pattern: compute a new `PersistedState`, call `_replaceState(next)`, which calls `notifyListeners()` and persists asynchronously.
- `LocalStore` wraps `SharedPreferences` and seeds data on first launch via `SeedData.build()`.
- `appControllerProvider` is a `ChangeNotifierProvider`; `localStoreProvider` is overridden at app startup in `main.dart` with the already-initialized `LocalStore`.

### Navigation

**go_router** with a `ShellRoute` wrapping the five bottom-nav tabs (`/home`, `/list`, `/recipes`, `/pantry`, `/ai`). Detail screens (`/recipes/:recipeId`, `/ai/loading/:draftId`, `/ai/preview/:draftId`, `/ai/tweak/:draftId`) sit outside the shell and have no bottom nav.

### Feature Structure

```
lib/
  core/
    data/         # AppController + LocalStore + repository abstractions
    models/       # All data models (PersistedState, RecipeDetail, PantryItem, GroceryItem, AiRecipeDraft, ...)
    navigation/   # GoRouter config + _AppShell (bottom nav)
    theme/        # AppTheme — dark purple palette, all color constants
    widgets/      # AppScreen, GlassCard, SectionHeader — shared UI primitives
  features/
    home/         # Dashboard / overview screen
    pantry/       # Pantry inventory management
    recipes/      # Recipe library + detail view
    shopping_list/# Grocery list grouped by AisleCategory
    ai_recipe/    # AI import (URL/prompt), loading, preview, and tweak (chat) screens
```

### Key Domain Concepts

- **`normalizeName(String)`** — lowercase trim used as the identity key when merging pantry/shopping items; always use this when matching items by name.
- **`AisleCategory`** — enum used to group grocery items and categorize pantry/ingredients.
- **`IngredientUnit`** — unit enum shared across recipes, pantry, and shopping list; quantities of different units for the same ingredient are never merged.
- **`PantryMatchStatus`** — `enough` / `partial` / `missing`, computed per ingredient when viewing a recipe against the current pantry.
- **AI generation** is currently mocked inside `AppController.runGeneration()` with simulated status transitions (`queued → parsing → reasoning → composing → done`).

### UI Conventions

- All screens use `AppScreen` (from `lib/core/widgets/app_scaffold.dart`) which provides a `ListView`-based body with a top-to-bottom gradient, consistent padding (`EdgeInsets.fromLTRB(20, 12, 20, 100)`), and an optional FAB.
- Cards use `GlassCard` — rounded 28px corners, gradient fill, border from `AppTheme.border`.
- Colors are defined as `static const` on `AppTheme`; always reference `AppTheme.*` rather than hardcoding hex values.
