# AGENTS.md

## Collaboration Style

Act as a rigorous, honest mentor. Do not default to agreement. Identify weaknesses, blind spots, and flawed assumptions. Challenge ideas when needed. Be direct and clear, not harsh. Prioritize helping the maintainer improve over being agreeable. When critiquing something, explain why and suggest a better alternative. Use quick, clever humor when appropriate, but keep it relaxed and easygoing.

## Project Snapshot

InStock is a Flutter app for pantry tracking, recipe management, and grocery shopping. The user-facing app title is currently `Fridge`, so be careful when changing naming: the package/repository says InStock, while UI and persisted state still use Fridge naming.

The app uses:

- Flutter with Material 3
- Riverpod for dependency injection and reactive state
- go_router with a stateful shell for bottom-tab navigation
- shared_preferences for local persistence
- google_fonts for typography
- lucide_icons is available, though much of the current UI still uses Material icons

## Common Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter run -d macos
flutter run -d ios
flutter build macos
flutter build ios
```

Run `dart format` on changed Dart files before handing off code changes.

## Folder Map

```text
lib/
  app.dart                         # MaterialApp.router root, theme, router
  main.dart                        # AppDatabase init and ProviderScope override
  core/
    router/app_router.dart         # go_router routes and StatefulShellRoute
    theme/                         # AppColors, AppTextStyles, AppTheme
    utils/unit_converter.dart      # Quantity conversion and stock calculations
  data/
    database/app_database.dart     # ChangeNotifier-backed local data layer
    models/app_models.dart         # Ingredient, pantry, recipe, shopping models
    repositories/                  # Compatibility exports to AppDatabase
  features/
    pantry/                        # Pantry inventory and check-in flow
    recipes/                       # Recipe list, import, detail, ingredients
    shopping/                      # Shopping list and stock status UI
    settings/                      # Settings screen
    ai/                            # AI tinker sheet placeholder UI
  shared/widgets/                  # App shell, bottom nav, controls, FAB menu
test/
  app_controller_test.dart
  data/repositories/pantry_repository_test.dart
  widget_test.dart
graphify-out/
  GRAPH_REPORT.md                  # Generated knowledge graph report
```

## Architecture Notes

`AppDatabase` in `lib/data/database/app_database.dart` is the central state holder. It extends `ChangeNotifier`, owns an immutable-ish `AppState`, serializes state to JSON, and persists it under `fridge_state_v1` in `SharedPreferences`.

Provider setup lives in `lib/features/shopping/providers/shopping_provider.dart`. `appDatabaseProvider` must be overridden in `main.dart` after `AppDatabase.init()`. Pantry and recipe provider files currently re-export the shopping provider file, so do not assume they contain separate feature-specific provider logic.

The main domain model file is `lib/data/models/app_models.dart`. It defines ingredient categories, stock statuses, pantry items, recipes, recipe ingredients, shopping items, and `AppState`. Ingredient matching depends on canonical ingredient IDs plus aliases, not free-form string equality.

Navigation is in `lib/core/router/app_router.dart`. The bottom tabs are a `StatefulShellRoute.indexedStack` with four branches:

- `/` for Shopping
- `/pantry`
- `/recipes`
- `/settings`

Standalone routes outside the tab shell are:

- `/recipes/import`
- `/recipes/:id`
- `/pantry/checkin`

If adding routes, decide explicitly whether the screen should keep the bottom nav. Defaulting blindly here creates weird navigation traps.

## Data and State Rules

- Use `AppDatabase` methods for mutations instead of editing lists from widgets.
- Preserve JSON compatibility when changing models. Existing saved state is loaded from `SharedPreferences`.
- `AppDatabase._applyMigrations()` is where persisted data upgrades currently live.
- `IngredientCategory` drives both grouping and category color.
- Unit logic belongs in `UnitConverter`, not directly in screens.
- Checked shopping items currently increment pantry quantities. Be cautious changing this flow because it couples shopping completion to pantry stock.

## UI and Design Rules

The canonical design reference is [design_system.md](design_system.md).

Short version:

- Use `AppColors`, `AppTextStyles`, and `AppTheme`; avoid hardcoded colors and ad hoc text styles.
- The app is a dark, utilitarian grocery tool. Keep screens scannable and task-focused.
- Existing surfaces use small radii, restrained borders, and status colors for meaning.
- Use shared widgets from `lib/shared/widgets/` before inventing new controls.
- Current UI uses compact controls and dense lists. Do not turn routine workflow screens into marketing pages. Nobody needs a hero section to buy onions.

## Testing and Verification

For code changes, run at least:

```bash
dart format <changed dart files>
flutter analyze
flutter test
```

For documentation-only changes, tests are usually unnecessary, but still inspect diffs before final response.

## graphify

This project has a graphify knowledge graph at `graphify-out/`.

Rules:

- Before answering architecture or codebase questions, read `graphify-out/GRAPH_REPORT.md` for god nodes and community structure.
- If `graphify-out/wiki/index.md` exists, navigate it instead of reading raw files.
- After modifying code files in this session, run `graphify update .` to keep the graph current. This is AST-only and has no API cost.
