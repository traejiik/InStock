# AGENTS.md

## Collaboration Style

Act as a rigorous, honest mentor. Do not default to agreement. Identify weaknesses, blind spots, and flawed assumptions. Challenge ideas when needed. Be direct and clear, not harsh. Prioritize helping the maintainer improve over being agreeable. When critiquing something, explain why and suggest a better alternative. Use quick, clever humor when appropriate, but keep it relaxed and easygoing.

## Project Snapshot

InStock is a Flutter app for pantry tracking, recipe management, and grocery shopping. The user-facing app title is currently `Fridge`, so be careful when changing naming: the package/repository says InStock, while UI and persisted state still use Fridge naming.

The app uses:

- Flutter with Material 3
- Riverpod for dependency injection and reactive state
- go_router with a stateful shell for bottom-tab navigation
- Drift SQLite for core data persistence (ingredients, pantry, recipes, shopping)
- shared_preferences for user preferences only (unit system, theme)
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
    database/migration_service.dart # One-time SharedPreferences → Drift migration
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

`AppDatabase` in `lib/data/database/app_database.dart` is the central state holder. It extends `ChangeNotifier` and owns an immutable `AppState` in memory. The backing store is Drift SQLite via `InStockDriftDb` (`drift_database.dart`). On first run, `MigrationService` migrates any legacy `fridge_state_v1` data from SharedPreferences into the SQLite tables and sets a flag so migration only runs once. User preferences (unit system, theme) remain in SharedPreferences via the settings providers — this is intentional and separate from core data.

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
- Preserve JSON compatibility when changing models. `MigrationService` reads the legacy `fridge_state_v1` JSON blob from SharedPreferences once during first launch — deserialization must not regress for existing users.
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

# [InStock] recent context, 2026-05-13 12:15pm GMT+2

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (16,584t read) | 217,130t work | 92% savings

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
575 2:23a 🔴 SortChipRow Migrated to Theme-Aware AppColors.of(context)
576 " 🔴 ToggleRow API Fixed: Nullable Icon Colors with Runtime Theme Defaults
577 2:24a 🔴 FabMenu Migrated to Theme-Aware AppColors for FAB and Option Card Borders
578 " 🔴 CategoryPicker Dropdown Migrated to Theme-Aware Colors
579 " 🔴 UnitPicker Migrated with AppColors Threaded Through Helper Methods as Parameter
580 " 🔴 QuantityBar Progress Indicator Migrated to Theme-Aware Colors
581 2:25a 🔴 Pantry Feature Widgets CategoryDivider and PantryItemRow Migrated to Theme-Aware Colors
582 " 🔴 StockBadge Corrected to Use Ink Color Tokens for Badge Text
583 " 🔴 ShoppingListItem Fully Migrated with Checkmark Icon Color Fix
584 " 🔴 IngredientRow Migrated to Theme-Aware Colors in Recipes Feature
585 2:27a 🔵 Several Recipes Feature Widgets Still Use Static AppColors — Read Before Migration
586 2:28a 🔵 Large Remaining Scope: All Screen Files and AI Widget Still Use Static AppColors
587 " 🔵 Settings Screen Has Theme Toggle But Light Option Missing from UI Options List
588 2:30a 🔴 StepRow Migrated to Theme-Aware Colors with Checkmark Icon Fix
589 11:41a 🔵 InStock Project Plan Implementation Starting
590 " 🔵 InStock Implementation Starting on Main Branch
591 " 🔵 InStock Test Suite Structure Mapped
592 " 🔵 InStock Core Data Models Mapped
593 11:42a 🔵 add_recipe_screen.dart Uses GestureDetector Exclusively for Tappable Widgets
594 " 🔵 _PrimaryButton Implements Disabled State via Manual Color Logic
595 11:43a 🟣 RecipeScraper TDD Tests Written (Red Phase)
596 " 🟣 Widget Test Added for Import Recipe Button Enable/Disable State
597 " 🔵 RecipeScraper TDD Red Phase Confirmed — Class Does Not Exist Yet
598 11:44a 🔵 Import Recipe Widget Test Red Phase Confirmed — URL Input Not Wired to Button State
599 11:46a 🟣 RecipeScraper Service Implemented (Green Phase)
600 11:49a 🟣 RecipeScraper Rewritten with Full Production-Grade Implementation
601 " 🟣 IngredientFormRow Extended with Notes Field
602 " 🟣 AppDatabase.saveRecipe() Ingredient Record Type Extended with Notes
603 11:50a 🔵 Ingredient isOptional Call Sites Audited Across Codebase
604 " 🔴 add_recipe_screen.dart Manual Ingredient Submission Updated for notes Field
605 " 🟣 _ImportTabContent Converted to StatefulWidget with URL Validation
606 11:51a 🟣 IngredientFormRow Gains sectionLabel for Section-Aware Form Rendering
607 " 🟣 Recipe Review Screen Renders Ingredient Section Headers Inline
608 11:52a 🔴 Metric Toggle Subtitle Fixed in add_recipe_screen.dart
609 " 🔵 Two Test Failures Found: Section Label Casing and Anonymous Record Type Mismatch
610 " 🔴 add_recipe_screen.dart Ingredient List Type Declaration Fixed
611 " 🔴 RecipeScraper Section Labels Now Use Sentence Case Instead of Title Case
612 11:53a 🟣 Import Recipe Widget Test Now Passing (Green Phase Complete)
613 " 🔵 RecipeScraper Ingredient Name Casing Still Failing — title case vs sentence case
614 " 🔴 RecipeScraper Ingredient Names Now Use Sentence Case
615 11:54a 🔵 RecipeScraper Parsing 10 Ingredients Instead of 12 — Two Items Dropped
616 " 🔴 RecipeScraper Test Index Corrected — Flour Is at Index 8 Not 6
617 " 🟣 Full Test Suite Passes — All 25 Tests Green After RecipeScraper Implementation
618 " 🔵 _titleCase Deletion Patch Failed Due to dart format Reformatting
619 " 🔄 Dead _titleCase() Method Removed — RecipeScraper Clean
620 11:55a ✅ RecipeScraper Feature Changeset Summary — 5 Files Modified, 133 Net Insertions
621 " 🔵 Complete Pre-Commit Changeset: 7 Modified Files + 1 New Test Directory
622 " ✅ RecipeScraper.convertToMetric Removed tbsp→ml and tsp→ml Conversions (Intentional)
623 12:14p 🔵 Recipe Scraper: Two Bugs Identified by User
624 " 🔵 Recipe Scraper Architecture in InStock Project

Access 217k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>