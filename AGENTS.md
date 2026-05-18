# AGENTS.md

## Collaboration Style

Act as a rigorous, honest mentor. Do not default to agreement. Identify weaknesses, blind spots, and flawed assumptions. Challenge ideas when needed. Be direct and clear, not harsh. Prioritize helping the maintainer improve over being agreeable. When critiquing something, explain why and suggest a better alternative. Use quick, clever humor when appropriate, but keep it relaxed and easygoing.

## Project Snapshot

InStock is a Flutter app for pantry tracking, recipe management, and grocery shopping. The user-facing app title is currently `Fridge`, so be careful when changing naming: the package/repository says InStock, while UI and persisted state still use Fridge naming.

The app uses:

- Flutter with Material 3
- Riverpod for dependency injection and reactive state
- go_router with a stateful shell for bottom-tab navigation
- Drift SQLite for persistence (ingredients, pantry, recipes, shopping, app flags, and preferences)
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
  main.dart                        # Entry point, delegates to InStockBootstrap
  bootstrap.dart                   # StatefulWidget that initializes AppDatabase and wraps app in ProviderScope
  core/
    router/app_router.dart         # go_router routes and StatefulShellRoute
    theme/                         # AppColors, AppTextStyles, AppTheme
    utils/unit_converter.dart      # Quantity conversion and stock calculations
  data/
    database/app_database.dart     # ChangeNotifier facade wrapping InStockDriftDb
    database/drift_database.dart   # Drift table definitions and InStockDriftDb class
    models/app_models.dart         # Ingredient, pantry, recipe, shopping models
    repositories/                  # Compatibility re-exports of AppDatabase
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

`AppDatabase` in `lib/data/database/app_database.dart` is the central state holder. It extends `ChangeNotifier` and owns an immutable `AppState` in memory. The backing store is Drift SQLite via `InStockDriftDb` (`drift_database.dart`). On first run, the app seeds default data if the ingredients table is empty. App-level flags and preferences live in the `AppFlags` singleton row.

Provider setup lives in `lib/features/shopping/providers/shopping_provider.dart`. `appDatabaseProvider` must be overridden in `main.dart` after `AppDatabase.init()`. Pantry and recipe provider files currently re-export the shopping provider file, so do not assume they contain separate feature-specific provider logic.

The main domain model file is `lib/data/models/app_models.dart`. It defines ingredient categories, stock statuses, pantry items, recipes, recipe ingredients, shopping items, and `AppState`. Ingredient matching depends on canonical ingredient IDs plus aliases, not free-form string equality.

Navigation is in `lib/core/router/app_router.dart`. The bottom tabs are a `StatefulShellRoute.indexedStack` with four branches:

- `/` for Shopping
- `/pantry`
- `/recipes`
- `/settings`

Standalone routes outside the tab shell are:

- `/recipes/import`
- `/recipes/add`
- `/recipes/review`
- `/recipes/:id`
- `/pantry/checkin`

If adding routes, decide explicitly whether the screen should keep the bottom nav. Defaulting blindly here creates weird navigation traps.

## Data and State Rules

- Use `AppDatabase` methods for mutations instead of editing lists from widgets.
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

# [InStock] recent context, 2026-05-18 3:36am GMT+2

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (17,953t read) | 247,398t work | 93% savings

### May 14, 2026
S70 Fix 6 bugs in InStock Flutter app: recipe form bleed, light mode contrast, shopping list UX, unit conversion display, version number confusion, and AI UI removal (May 14 at 10:25 PM)
S71 Codebase audit: identify and fix issues — removed stub AI Generate UI from recipes screen (May 14 at 10:41 PM)
### May 15, 2026
S72 User asked whether Claude consistently uses the graphify graph when running tasks (May 15 at 10:31 PM)
S73 Can the graphify graph be used for code segments? — Investigation of graph.json node/edge granularity for InStock Flutter project (May 15 at 10:45 PM)
S74 Validating that graphify graph.json can locate the database definition file by keyword query, replacing codebase exploration (May 15 at 11:02 PM)
S75 Evaluating graphify graph.json vs direct find command for database file discovery in InStock (May 15 at 11:07 PM)
S76 InStock Flutter recipe app: add post-save recipe editing, fix light-mode title contrast over images, clarify "Add Missing" button label (May 15 at 11:08 PM)
S77 InStock Flutter app: add recipe edit capability, fix title contrast in light mode, clarify "Add Missing" button text (May 15 at 11:31 PM)
S78 Determine possible next steps for InStock Flutter pantry-tracking app development (May 15 at 11:39 PM)
### May 17, 2026
S79 Quick state check to verify knowledge of InStock project is current (May 17 at 4:54 AM)
843 5:45a ✅ Batch 2 Fully Committed — Two Commits on Main, Only AGENTS.md Remains Unstaged
849 10:45a 🔵 Smart Commit Skill Workflow and Guidelines
850 " 🔵 InStock Repository Dirty Worktree State Before Smart Commit
851 " 🟣 Quick Adjust Bottom Sheets for Shopping and Pantry Items
852 " 🟣 New Database Mutation Methods: updateShoppingItem, updatePantryItem, updateIngredientCategory
853 " 🔴 PantryItem and ShoppingItem copyWith() Bugs Fixed
854 " 🟣 New Tests for Quick-Adjust Database and Widget Behavior
### May 18, 2026
855 2:28a 🔵 InStock Codebase Knowledge Graph Report Generated
856 " 🔵 InStock Recent Git History and Working Tree State
863 3:09a 🔵 InStock Flutter App — Knowledge Graph Structure
864 3:10a 🔵 InStock Provider Architecture — Single Source Pattern
865 " 🔵 Derived Riverpod Providers Largely Unused — Screens Bypass Them
866 " 🔵 InStock Bootstrap Pattern — Async DB Init Before ProviderScope
867 " 🟣 TDD Architecture Test Written for Provider Ownership Refactor
868 3:11a 🔄 Provider Ownership Refactor — appDatabaseProvider Moved to Core
869 " 🔄 Import Migration — All Files Switched to core/providers/app_database_provider.dart
870 " 🔄 Provider Ownership Refactor — Verification Complete, Ready for Test Run
871 3:12a 🟣 Architecture Test GREEN — Provider Ownership Refactor Complete
872 " 🔄 Batch 4 Provider Refactor — flutter analyze Clean After Full Migration
873 " 🔄 Batch 4 Provider Refactor — Full Test Suite Passes (58/58)
874 " ✅ Knowledge Graph Updated After Batch 4 Provider Refactor
875 3:13a 🔵 Smart-Commit Grouping Plan — Two Distinct Commit Groups Identified
876 " 🔄 Committed: "refactor: split feature provider ownership" (cdbcab6)
877 3:21a 🔵 InStock Flutter App — Codebase Graph Analysis
878 " 🔵 Recipe Import Subsystem Architecture — Batch 5 Focus Area
879 3:22a 🔵 RecipeScraper Full Implementation — Ingredient Parsing & Instruction Selection Logic
880 " 🔵 AddRecipeScreen Two-Tab Architecture and Provider Reset Behavior
881 3:23a 🔵 Test Infrastructure: No HTTP Mocking Library — RecipeScraper.scrape() Is Untestable Without Network
882 " 🟣 Batch 5 TDD — RED Phase: New Failing Tests for Recipe Import Improvements
883 3:24a 🔴 apply_patch Whitespace Sensitivity Caused Test File Patch Failure
884 " 🟣 Batch 5 RED Phase Complete — All Test Files Successfully Written
885 3:25a 🔵 Batch 5 RED Phase Verified — Exact Failure Modes Confirmed for All 5 New Tests
886 " 🟣 Batch 5 GREEN Phase — recipeScraperProvider Dependency Injection Added
887 " 🟣 Batch 5 GREEN Phase — URL Angle Bracket Stripping and Instruction Requirement in RecipeScraper
888 3:26a 🔵 Riverpod AsyncLoading Carries Previous Value — Stale Recipe Visible During Import
889 " 🟣 Batch 5 — Widget-Level RED Test for Stale Preview Hiding During Loading
890 " ✅ Widget Test Scaffolding — _WidgetFakeRecipeScraper and _widgetParsedRecipe Added to widget_test.dart
891 3:27a 🔵 Widget Test 'import tab hides stale preview' Fails at First Import Assertion
892 " 🔴 add_recipe_screen UI Fix — Preview Hidden During Loading by Checking AsyncData Concrete Type
893 " 🔴 Batch 5 GREEN Phase Complete — All Tests Pass After Provider Test Scope Correction
894 3:28a 🟣 Batch 5 Complete — All 28 Tests Pass Across All Three Test Files
895 " ✅ Batch 5 Git Status — 5 Modified Files + 1 New Untracked Test Directory
896 " ✅ Batch 5 Static Analysis Clean — No Issues Found
897 " 🟣 Batch 5 Full Suite Verification — 64 Tests Pass Across All 11 Test Files
898 3:29a ✅ Knowledge Graph Updated After Batch 5 — 9 New Nodes, 14 New Edges, 1 New Community
899 " ✅ Batch 5 Commit Diff Summary — 243 Insertions, 86 Deletions Across 6 Files
900 3:31a 🔵 InStock Git Commit Convention — Conventional Commits with feat/fix/refactor/docs/chore
901 " 🔵 AGENTS.md Memory Context Rotated — Older May 12-15 Observations Pruned for May 18 Context
902 " ✅ Batch 5 Staged for Commit — 6 Files Staged, AGENTS.md Held Separately
903 3:32a ✅ Batch 5 Committed — "fix: harden recipe import flow" (f7ecd5c)

Access 247k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>
