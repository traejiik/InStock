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

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)


<claude-mem-context>
# Memory Context

# [InStock] recent context, 2026-05-07 3:45am GMT+2

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (21,657t read) | 396,285t work | 95% savings

### Apr 29, 2026
S47 Add app icons and splash screens to InStock Flutter app (iOS + Android) using flutter_launcher_icons and flutter_native_splash with existing dark brand assets (Apr 29 at 5:37 AM)
### May 6, 2026
S48 InStock Flutter App — Fix White Border on App Icon and Oversized Icon-Only Splash Screen (May 6 at 2:09 PM)
S49 Commit app icon and splash screen brand assets with an appropriate conventional commit message (May 6 at 9:39 PM)
S50 InStock Flutter App — Settings Screen Phase 1 Implementation (unit preference, theme preference, app version, clear-all-data) (May 6 at 10:15 PM)
353 11:43p ⚖️ InStock Settings Screen — Phased Architecture Plan
357 11:44p 🔵 Settings Screen Currently a Placeholder at Non-Standard Path
358 " 🔵 AppState Uses `AppState.empty` Static Const — Not Default Constructor
359 " 🔵 InStock Codebase Pre-Implementation State Survey
360 11:48p ✅ Added `package_info_plus: ^8.0.0` to pubspec.yaml
361 " ✅ `flutter pub get` Resolved `package_info_plus 8.3.1` Successfully
362 " 🟣 Settings Providers File Created with Unit, Theme, and PackageInfo Providers
363 11:49p 🟣 Settings Screen Replaced: Placeholder → Full Functional Implementation
364 " 🟣 `AppDatabase.clearAllData()` Added and `InStockApp` Upgraded to ConsumerWidget
365 " ✅ Settings Feature Passes `flutter analyze` Clean and Formatted
366 11:50p 🔴 Fixed Braceless `if` in `toggleShoppingItem()` After `dart format` Reformatted It
367 " 🟣 InStock Settings Feature — Phase 1 Complete: Analyze Clean, All Tests Pass
368 " ✅ Design System Compliance Verified: No Hardcoded Colors or `withOpacity` in Settings Feature
S51 Commit settings screen implementation in InStock Flutter app (May 6 at 11:51 PM)
369 11:56p 🔵 InStock Flutter App Has Large Uncommitted Changes Ready to Commit
S52 Commit and push settings screen implementation in InStock Flutter app (May 6 at 11:56 PM)
370 " ✅ InStock Settings Feature Pushed to GitHub Remote
S55 InStock Flutter app: Migrate data persistence from SharedPreferences JSON blob to Drift SQLite database while preserving AppDatabase public API (May 6 at 11:56 PM)
### May 7, 2026
388 2:41a ⚖️ InStock Data Layer: SharedPreferences → Drift SQLite Migration Architecture
389 " 🔵 Existing AppDatabase Implementation: SharedPreferences JSON Blob Architecture
390 2:42a 🔵 appDatabaseProvider Defined in shopping_provider.dart
391 " 🔵 Complete AppDatabase Method Call Surface Across Feature Screens
392 2:48a ⚖️ InStock: SharedPreferences → Drift SQLite Migration Architecture
393 " 🟣 Drift Database Schema: Five-Table SQLite Design for InStock
394 " 🟣 MigrationService: Atomic One-Time SharedPreferences → Drift Migration
395 " 🔄 AppDatabase Rewritten as Drift Facade with Preserved ChangeNotifier API
396 2:49a 🟣 Drift Code Generation Completed Successfully for InStock
397 " 🟣 MigrationService Implemented with Extra Legacy Key Handling
398 2:52a 🔄 app_database.dart Fully Rewritten: SharedPreferences JSON Replaced with Drift Persistence
399 " 🔄 pantry_repository_test.dart Updated to Use In-Memory Drift Database
400 " 🔴 Fixed Missing InsertMode Import in migration_service.dart
401 " 🔵 All 6 Tests Pass; Drift Warns About Multiple Database Instantiations Per Test
402 " 🔴 Suppressed Drift Multi-Instantiation Warning in Test File
403 2:53a 🟣 InStock Drift Migration Phase 1 Complete: Zero Analyzer Issues, All Tests Pass
404 " 🔵 Spec Grep Checks Reveal Two Partial Violations in app_database.dart
405 " 🔄 MigrationService Refactored: SharedPreferences Fetched Internally, Returns MigrationOutcome Enum
406 2:54a 🔄 AppDatabase.init() Simplified to 4 Lines Using MigrationOutcome Enum
407 " 🟣 InStock Drift Migration Phase 1 Fully Complete and Verified
S56 InStock Drift migration Phase 1 complete — user asked if /memory was run to record the session work (May 7 at 2:54 AM)
S57 InStock Flutter app: SharedPreferences → Drift SQLite migration + Graphify knowledge graph generation (May 7 at 2:56 AM)
408 2:58a 🔵 README.md and AGENTS.md Contain Stale Persistence References After Drift Migration
409 " ⚖️ InStock Flutter App: SharedPreferences → Drift SQLite Migration Plan
410 2:59a ⚖️ InStock: SharedPreferences → Drift SQLite Migration Architecture
411 " 🔵 InStock Graphify Knowledge Graph — Full Codebase Node/Edge Map
S58 InStock Flutter app: SharedPreferences → Drift SQLite migration + Graphify knowledge graph regeneration (in progress) (May 7 at 3:01 AM)
412 3:01a 🔵 Graphify Chunk Verification — All 3 Chunks Present and Valid
413 " 🟣 Graphify Knowledge Graph Merged and Cached — 93 Nodes, 171 Edges
414 " 🔵 InStock Full Graph — 833 Nodes, 857 Edges (AST + Semantic Combined)
415 3:02a 🔵 InStock AST Community Analysis — Drift Migration Already Implemented in Codebase
416 " 🔵 InStock Graph — 33 Communities Identified, Drift Migration Confirmed in Community 3
417 3:04a 🔵 InStock Graph Communities 15–32 — Drift Database and Repository Layer Confirmed
418 3:05a 🔵 Graphify report.py API Mismatch — generate_report Not Exported
419 " 🔵 Graphify report.generate() API Signature and Analysis File Structure Confirmed
420 " 🔵 graph.json Uses NetworkX Format — 666 Nodes, 853 Links After Filtering
421 " 🟣 GRAPH_REPORT.md Regenerated — 13,789 chars with 33 Labeled Communities
422 " 🔵 Graphify Export API — Full Function Inventory Including graph.html Regeneration

Access 396k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>