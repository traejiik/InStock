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

# [InStock] recent context, 2026-05-13 1:33pm GMT+2

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (17,567t read) | 246,162t work | 93% savings

### May 7, 2026
S59 InStock Flutter App — Bundle ID Migration (com.example → dev.traejiik) + iOS Privacy Manifest + Android Build Fix (May 7 at 3:01 AM)
S60 InStock Flutter App — Bundle ID Migration + iOS Privacy Manifest + Android Build Fix + graphify graph update (May 7 at 5:42 PM)
S61 InStock Flutter App — Bundle ID Migration + iOS Privacy Manifest + Android Desugaring Fix — COMMITTED (May 7 at 5:45 PM)
S62 InStock Flutter: Fix Android SQLite crash after Drift migration and fix splash screen on both platforms to use correct dark brand asset (May 7 at 5:46 PM)
S63 Audit GPT-introduced changes to InStock Flutter app and fix all issues found (May 7 at 6:23 PM)
### May 8, 2026
S64 Restore the claude-mem segment — fix documentation restoration, stale references, annotation placement, and machine-specific test failures in the InStock Flutter app (May 8 at 1:58 AM)
S65 Audit and fix GPT-introduced issues in InStock Flutter app — annotation placement, initialization pattern, splash assets, and documentation (May 8 at 2:00 AM)
S66 Fix iOS build error in InStock Flutter app — likely caused by objective_c 9.3.0 deployment target conflict (May 8 at 2:01 AM)
S67 Group unstaged files into logical commits with conventional messages, then create a global smart-commit skill for reuse (May 8 at 2:13 AM)
### May 12, 2026
S68 Group unstaged files into logical commits with conventional messages, push to remote, then create a global smart-commit skill for reuse (May 12 at 12:55 PM)
### May 13, 2026
642 12:42p 🔵 Recipe Scraper Implementation: JSON-LD First, Heuristic Fallback
643 " 🔵 RecipeScraper: Ingredient Parsing Pipeline and Name Simplification Gap
644 " 🟣 Branch Created: codex/canonical-ingredient-names
645 12:43p 🟣 Failing Tests Written for "Core Pantry Item" Name Canonicalization (TDD RED Step)
646 " 🔵 TDD RED Confirmed: 5 Specific Scraper Bugs Exposed by Failing Tests
647 12:45p 🟣 Ingredient Name Canonicalization Implemented in recipe_scraper.dart
648 12:46p 🔴 All 6 Recipe Scraper Tests Pass — TDD GREEN Step Complete
649 " ✅ dart format Applied: Only Test File Needed Reformatting
650 12:47p 🔴 Full Test Suite: 26/26 Pass Including Import Button Enable Test
651 " ✅ Codebase Graph Updated: 700 Nodes, 889 Edges After Recipe Scraper Changes
652 12:48p ✅ Branch codex/canonical-ingredient-names Ready for Integration: 305 Lines Added
653 12:57p 🔵 InStock Project Pending Changes Before Smart Commit
654 " 🔵 Recipe Scraper Overhaul — Large Diff Before Commit
655 " 🟣 Recipe Scraper Canonical Ingredient Name Normalization
656 " 🔵 InStock Codebase Graph: 700 Nodes, Core Abstractions Identified
657 12:58p 🟣 Recipe Scraper Normalization Passes All Tests — 26/26 Green
658 " ✅ Committed "fix: canonicalize imported ingredient names" on Branch codex/canonical-ingredient-names
659 1:12p 🟣 Recipe Instructions Enhancement: Detailed Steps + Notes Section
660 " 🔵 InStock Flutter App Codebase Structure via Graph Report
661 1:13p 🔵 Recipe Notes Field Exists in DB but Not Wired Through Form Save
662 " 🔵 Recipe Instruction Extraction Uses Short _chooseSteps(), Not Full Sections
663 1:14p 🔵 Recipe Model Has No Notes Field — Only RecipeIngredient Does
664 " 🔵 _chooseSteps() Selects Full Recipe Section Over Abbreviated via Name Matching
665 " 🔵 RecipeReviewScreen Instructions Section Has No Notes Section After Steps
666 " 🔵 Recipes Drift Table Has No Notes Column — Schema Migration Required
667 " 🔵 _StepRow Already Uses maxLines: null — Step Text Display Is Not Truncated
668 1:15p ⚖️ Recipe Import: Richest Instructions + Persist Notes Design Decisions
669 1:16p ✅ Created Feature Branch codex/rich-recipe-instructions-notes
670 " ✅ Implementation Plan Defined: 5-Step TDD Approach for Rich Instructions + Notes
671 " 🔵 Test Infrastructure Patterns for InStock Recipe Feature
672 " 🔵 add_recipe_screen.dart Write Tab Also Missing Notes Section
673 1:17p 🟣 Failing Tests Written for Rich Instructions and Recipe Notes Scraping
674 1:18p 🔴 Scraper Tests Finalized: Two HTML Fixtures for Rich Instruction Selection
675 " 🟣 Failing DB Tests Written for Recipe Notes Persistence and Serialization
676 " 🟣 Failing Widget Tests Written for Notes UI in Review and Detail Screens
677 1:19p 🔵 All Failing Tests Compile-Error as Expected — RED Phase Confirmed
678 1:20p 🟣 RecipeScraper Upgraded: Rich Instruction Scoring, Visible Notes Extraction, HTML Entity Decoding
679 " 🟣 Recipe Model Gains notes Field with Full Serialization Support
680 " 🟣 Drift Schema Updated to v2: notes Column Added to Recipes Table with Migration
681 " 🟣 app_database.dart Wired for Recipe Notes: saveRecipe, _mapRecipe, _recipeCompanion Updated
683 " 🟣 RecipeFormState and RecipeFormNotifier Updated with Notes Support
684 " 🟣 RecipeReviewScreen Gains Notes Section After Instructions
685 " 🟣 add_recipe_screen.dart Write Tab Gains Notes Section Before Save Button
686 1:22p 🔵 recipe_detail_screen _SectionHeader Requires count Param — Notes Section Needs Different Widget
687 " 🟣 Recipe Detail Screen Conditionally Shows Notes Section After Instructions
688 " 🟣 Step 4 UI Complete: All Three Screens Updated for Notes Display and Editing
689 " ✅ dart run build_runner build Started for Drift Codegen After Schema v2 Change
690 1:23p 🔵 build_runner Warning: SDK Language Version Mismatch (3.11.0 vs analyzer 3.9.0)
691 " ✅ Drift Codegen Completed Successfully: drift_database.g.dart Regenerated

Access 246k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>
