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

# [InStock] recent context, 2026-05-11 11:28pm GMT+2

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (16,365t read) | 423,499t work | 96% savings

### May 7, 2026
S57 InStock Flutter app: SharedPreferences → Drift SQLite migration + Graphify knowledge graph generation (May 7 at 2:56 AM)
S58 InStock Flutter app: SharedPreferences → Drift SQLite migration + Graphify knowledge graph regeneration (in progress) (May 7 at 3:00 AM)
S59 InStock Flutter App — Bundle ID Migration (com.example → dev.traejiik) + iOS Privacy Manifest + Android Build Fix (May 7 at 3:01 AM)
S60 InStock Flutter App — Bundle ID Migration + iOS Privacy Manifest + Android Build Fix + graphify graph update (May 7 at 5:42 PM)
S61 InStock Flutter App — Bundle ID Migration + iOS Privacy Manifest + Android Desugaring Fix — COMMITTED (May 7 at 5:45 PM)
S62 InStock Flutter: Fix Android SQLite crash after Drift migration and fix splash screen on both platforms to use correct dark brand asset (May 7 at 5:46 PM)
S63 Audit GPT-introduced changes to InStock Flutter app and fix all issues found (May 7 at 6:23 PM)
### May 8, 2026
468 1:50a 🔵 Data Layer Fully Migrated from SharedPreferences JSON to Drift/SQLite
470 1:51a 🔵 Critical Bug: @DriftDatabase Annotation Applied to Function, Not Class
471 " 🔵 Audit Summary: 4 Issues Found Across Tests and Config
472 " 🔵 AGENTS.md Has 6 Stale Sections After Drift Migration
473 " 🔵 Two Undocumented Routes Added: /recipes/add and /recipes/review
474 1:54a 🔵 Audit Plan Created: 5 Issues Prioritized, AGENTS.md Has Committed claude-mem Block
475 1:55a 🔴 Fixed: @DriftDatabase Annotation Moved to Correct Class
476 " 🔴 Fixed: Machine-Specific Path Removed from splash_assets_test.dart
477 " ✅ AGENTS.md Updated: Persistence Stack Corrected in Project Snapshot
478 " ✅ AGENTS.md Folder Map Updated: main.dart and bootstrap.dart Corrected
479 " ✅ AGENTS.md Folder Map: Database Directory Updated with Drift Files
480 1:56a ✅ AGENTS.md Route List Updated: /recipes/add and /recipes/review Added
481 " 🔵 AGENTS.md Confirmed Clean: No claude-mem-context Block Present
482 " ✅ AGENTS.md Trailing Blank Lines Removed
483 1:57a ✅ AGENTS.md Architecture Notes Rewritten to Describe Drift Architecture
484 " ✅ AGENTS.md Data Rules: JSON Compatibility Rule Clarified for Migration Context
485 " 🔵 All 16 Tests Pass After Audit Fixes
486 " 🔵 build_runner Succeeds After @DriftDatabase Annotation Fix — Code Gen Verified
S64 Restore the claude-mem segment — fix documentation restoration, stale references, annotation placement, and machine-specific test failures in the InStock Flutter app (May 8 at 1:58 AM)
S65 Audit and fix GPT-introduced issues in InStock Flutter app — annotation placement, initialization pattern, splash assets, and documentation (May 8 at 2:00 AM)
487 2:01a ✅ Bootstrap pattern implemented for AppDatabase initialization
488 " ✅ Drift database annotation repositioned to class declaration
489 " ✅ Flutter native splash assets and configuration updated
490 " ✅ AGENTS.md updated with accurate architecture and migration information
491 2:09a 🔵 InStock iOS Podfile Missing Explicit Platform Version
492 2:11a 🔵 InStock Uses sqlite3_flutter_libs as Direct Dependency with objective_c Transitive
493 " 🔵 objective_c Package Version 9.3.0 Confirmed in Pub Cache
494 " 🔵 objective_c 9.3.0 Uses Native Build Hooks and Is Absent from iOS Pods
495 " 🔵 Exact Dependency Versions Confirmed: sqlite3 2.9.4, sqlite3_flutter_libs 0.5.42, objective_c 9.3.0
496 2:13a 🔴 Podfile iOS Platform Version Uncommented to Fix Build Issue
497 " 🔴 Podfile post_install Hook Added to Force IPHONEOS_DEPLOYMENT_TARGET on All Pod Targets
S66 Fix iOS build error in InStock Flutter app — likely caused by objective_c 9.3.0 deployment target conflict (May 8 at 2:13 AM)
### May 11, 2026
498 10:14p 🔵 InStock Flutter App — Codebase Architecture Graph
499 " 🔴 iOS Podfile — Deployment Target Uncommented and Enforced for All Pods
500 10:15p 🔵 Drift Database — Schema Version 1 with No Migration Handler
501 " 🔵 Bootstrap — Hard-coded Colors Outside Design Token System
502 " 🔵 Dependency Audit — 49 Packages Outdated, sqlite3_flutter_libs at EOL
503 " 🔵 Flutter Analyze — Zero Issues Found
504 " 🔵 Flutter Test Suite — All 16 Tests Passing
505 10:16p 🔵 Android Debug APK — Build Succeeds Clean
506 " 🔵 iOS pod install — CocoaPods Profile xcconfig Integration Warning
507 10:17p 🔵 iOS Debug.xcconfig — Correctly Includes Pods xcconfig; Release Likely Missing Profile Include
508 " 🔵 iOS Profile Build xcconfig Gap — Root Cause Confirmed
509 10:18p 🔵 iOS Release Build — Succeeds Despite Profile xcconfig Warning
510 " 🔵 Available Flutter Devices — macOS and Chrome Only; No Mobile Simulators Connected
511 10:19p 🔵 macOS Build — 192 Compiler Warnings from sqlite3 CocoaPod Amalgamation
512 10:20p 🔵 macOS Build — Succeeds with Two Warnings: Deployment Target Mismatch and Run Script Overhead
513 " 🔵 macOS Podfile — Missing Per-Pod Deployment Target Override (Unlike iOS Podfile)
514 10:21p 🔴 Runtime Bug — google_fonts Network Fetch Blocked by macOS Sandbox; Fonts Fail to Load
515 10:22p 🔵 macOS Entitlements Missing network.client — Root Cause of Font Load Failure Confirmed
516 " 🔵 iOS Simulator "Polar" Available — iOS 26.4, Currently Shutdown
517 10:25p 🔵 iOS Simulator Run — Clean Launch, No Font Errors (Unlike macOS)
518 " 🔵 iOS Simulator Screenshot — App Renders Correctly with Proper Fonts and Dark Theme

Access 423k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>