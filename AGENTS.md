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

# [InStock] recent context, 2026-05-15 11:52pm GMT+2

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (15,917t read) | 294,140t work | 95% savings

### May 12, 2026
S68 Group unstaged files into logical commits with conventional messages, push to remote, then create a global smart-commit skill for reuse (May 12 at 12:54 PM)
S69 Codebase health audit — "What do I need to fix in my code base?" for InStock Flutter app (May 12 at 12:55 PM)
### May 14, 2026
S70 Fix 6 bugs in InStock Flutter app: recipe form bleed, light mode contrast, shopping list UX, unit conversion display, version number confusion, and AI UI removal (May 14 at 10:25 PM)
711 10:36p 🔴 Fixed Light Mode Contrast in RecipeCardSm — Title and Meta Text Force White Over Images
712 " 🔴 _MetaRow Contrast Fixed — Icons and Text Now White70 Over Recipe Card Images
713 " 🔴 Shopping Add-Item Default Unit Changed from 'g' to 'pcs'
714 " 🔴 Match Status Now Uses Scaled Quantity — Pantry Check Respects Current Serving Count
715 " 🔴 Settings Version Display Simplified to "vX.Y.Z" — Build Number Removed
716 " ✅ AI Tab Removed from AddRecipeScreen — SegmentControl Now Has Two Tabs Only
717 10:37p ✅ AI Review State and Callbacks Fully Removed from AddRecipeScreen and _ImportTabContent
S71 Codebase audit: identify and fix issues — removed stub AI Generate UI from recipes screen (May 14 at 10:41 PM)
### May 15, 2026
718 10:31p 🔵 AI Recipe Generation Is a UI Stub in InStock
719 " 🔴 Removed Stub AI Generate Entry Points from Recipes Screen
S72 User asked whether Claude consistently uses the graphify graph when running tasks (May 15 at 10:31 PM)
720 10:42p 🟣 Smart Commit Skill Invoked on InStock Repository
721 " 🔵 InStock Dirty Worktree: Recipe UI Refactor + Docs Changes Pending Commit
722 10:43p 🟣 Recipe Card Text Contrast Fix: White Text Over Images
723 " 🟣 AI Features Removed from Recipe Screens
724 " 🔴 Recipe Form State Now Resets on AddRecipeScreen Open
725 " 🔴 Recipe Detail: Scaled Quantity Computed Once for matchStatus and Display
726 " ✅ Minor UX Tweaks: Version Display and Default Shopping Unit
727 " ✅ dart format Applied to Recipe and Settings Files Pre-Commit
728 10:44p 🔵 InStock flutter analyze Passes Clean; Test Suite Running (38+ passing)
729 " ✅ All 42 Tests Pass; Recipe/UI Files Staged for Commit (AGENTS.md Held Separately)
730 " ✅ Committed: "fix: clean up recipe and shopping UX issues" (b1c41ed)
731 " ✅ Committed: "docs: agent context" (67f3435)
732 10:45p ✅ InStock Smart Commit Session Complete — Working Tree Clean
S73 Can the graphify graph be used for code segments? — Investigation of graph.json node/edge granularity for InStock Flutter project (May 15 at 10:45 PM)
733 11:01p 🔵 Graphify Output Structure for InStock Project
734 " 🔵 InStock Graphify Graph Contains File-Level and Function-Level Nodes
735 " 🔵 Graphify Nodes Have No Type Field But Include Class and Method-Level Code Segments
736 11:02p 🔵 Graphify Graph Has No Code-to-Code Links and Minimal Source Location Data
S74 Validating that graphify graph.json can locate the database definition file by keyword query, replacing codebase exploration (May 15 at 11:02 PM)
737 11:07p 🔵 InStock Database Layer Fully Mapped in graphify Graph
S75 Evaluating graphify graph.json vs direct find command for database file discovery in InStock (May 15 at 11:07 PM)
738 11:08p 🔵 graphify graph.json is 862KB vs Instant find for File-Level Lookup
S76 InStock Flutter recipe app: add post-save recipe editing, fix light-mode title contrast over images, clarify "Add Missing" button label (May 15 at 11:08 PM)
739 11:26p 🟣 Recipe App: Edit, Contrast Fix, and Button Clarity Planned
740 " 🔵 RecipeDetailScreen Architecture: Flutter/Riverpod Recipe Detail View
741 " 🔵 InStock Database Has saveRecipe But No updateRecipe Method
742 11:27p 🔵 InStock Uses Soft-Delete Pattern for Recipes
743 " 🔵 RecipeReviewScreen Save Flow Uses recipeFormProvider Notifier
744 11:28p 🔵 RecipeReviewScreen Has Widget Tests; No updateRecipe Tests Exist
745 " 🔵 AddRecipeScreen Resets Form on Init and Pushes to Review With ParsedRecipe Extra
746 11:29p 🔵 ParsedRecipe.fromRecipe() Factory Constructor Already Exists for Edit Bridge
747 " 🔵 AppDatabase Persistence Uses insertOnConflictUpdate — updateRecipe Only Needs State Replacement
748 " 🔵 RecipeIngredients Table Has No Soft-Delete — Must Be Replaced on Recipe Update
749 11:31p ✅ Comprehensive Implementation Plan Written for Recipe Edit Feature + UI Fixes
750 11:33p 🔵 app_controller_test.dart Does Not Use InStockDriftDb.memory() — Test Setup Pattern Unknown
751 " 🔵 InStockDriftDb.memory() Exists; app_controller_test.dart Is a Placeholder
752 11:34p 🔴 Fixed Light Mode Title Contrast on Recipe Detail Hero Image
753 " 🔴 Clarified "Add Missing" Button Label to "🛒 Add to List"
754 " ✅ Task 1 Visual Fixes Committed to Main Branch (f492a6c)
755 " 🟣 TDD Test Written for updateRecipe Before Implementation
756 11:35p 🟣 Implemented AppDatabase.updateRecipe() Method
757 " 🟣 updateRecipe TDD Cycle Complete — All 43 Tests Pass, Committed
758 11:36p 🔵 RecipeFormProvider Current State: save() Is Synchronous, No editingId Field
759 " 🟣 RecipeFormProvider Extended with editingId, loadFromRecipe(), and Async save()
760 " ✅ Task 3 Committed — RecipeFormProvider Edit Mode Support Shipped
S77 InStock Flutter app: add recipe edit capability, fix title contrast in light mode, clarify "Add Missing" button text (May 15 at 11:39 PM)
**Completed**: All 6 tasks complete across 6 commits on main:

    1. f492a6c — recipe_detail_screen.dart: title color = white when imageUrl != null (contrast fix); button label changed from "+ Add Missing" to "🛒 Add to List"

    2. 69670e0 — app_database.dart: added updateRecipe() method that hard-deletes old RecipeIngredient rows then upserts updated recipe + new ingredients; test/app_controller_test.dart: added updateRecipe test group

    3. 87958ac — recipe_form_provider.dart: added editingId field to RecipeFormState, loadFromRecipe() method, copyWith support; save() made async Future<String>, branches on editingId to call updateRecipe vs saveRecipe

    4. ebdef35 — recipe_review_screen.dart: added editingId param, guards loadFromParsed with editingId == null check, async _save() with !mounted guard, navigates to /recipes/:id on edit save vs /recipes on create, AppBar title shows "Edit Recipe" when editing

    5. 4faaad3 — add_recipe_screen.dart: push extra changed from `effective` to `(parsed: effective, editingId: null as String?)`; app_router.dart: /recipes/review builder updated to cast extra as ({ParsedRecipe parsed, String? editingId}) and pass both fields to RecipeReviewScreen

    6. 115c8e3 — recipe_detail_screen.dart: added _recipeToParseRecipe() helper, added onEdit VoidCallback to _HeroArea, added pencil edit button at left:60, shifted delete to left:104, wired onEdit to loadFromRecipe + context.push with editingId

    All 43 tests pass throughout.

**Next Steps**: All tasks are complete. No further work is pending. The full edit recipe feature is shipped and working end-to-end.


Access 294k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>
