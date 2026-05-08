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

# [InStock] recent context, 2026-05-07 7:35pm GMT+2

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (19,189t read) | 386,469t work | 95% savings

### May 6, 2026
S51 Commit settings screen implementation in InStock Flutter app (May 6 at 11:51 PM)
S52 Commit and push settings screen implementation in InStock Flutter app (May 6 at 11:56 PM)
S55 InStock Flutter app: Migrate data persistence from SharedPreferences JSON blob to Drift SQLite database while preserving AppDatabase public API (May 6 at 11:56 PM)
### May 7, 2026
S56 InStock Drift migration Phase 1 complete — user asked if /memory was run to record the session work (May 7 at 2:54 AM)
S57 InStock Flutter app: SharedPreferences → Drift SQLite migration + Graphify knowledge graph generation (May 7 at 2:56 AM)
S58 InStock Flutter app: SharedPreferences → Drift SQLite migration + Graphify knowledge graph regeneration (in progress) (May 7 at 3:00 AM)
S59 InStock Flutter App — Bundle ID Migration (com.example → dev.traejiik) + iOS Privacy Manifest + Android Build Fix (May 7 at 3:01 AM)
416 3:02a 🔵 InStock Graph — 33 Communities Identified, Drift Migration Confirmed in Community 3
417 3:04a 🔵 InStock Graph Communities 15–32 — Drift Database and Repository Layer Confirmed
418 3:05a 🔵 Graphify report.py API Mismatch — generate_report Not Exported
419 " 🔵 Graphify report.generate() API Signature and Analysis File Structure Confirmed
420 " 🔵 graph.json Uses NetworkX Format — 666 Nodes, 853 Links After Filtering
421 " 🟣 GRAPH_REPORT.md Regenerated — 13,789 chars with 33 Labeled Communities
422 " 🔵 Graphify Export API — Full Function Inventory Including graph.html Regeneration
423 5:31p ⚖️ InStock Flutter App — Bundle ID Migration Plan
424 " 🟣 iOS Privacy Manifest (`PrivacyInfo.xcprivacy`) Added for App Store
425 5:32p 🔵 InStock Codebase Audit: Bundle ID Scope Confirmed
426 " ✅ iOS Bundle IDs Updated in project.pbxproj + PrivacyInfo PBXBuildFile Added
427 " ✅ PrivacyInfo.xcprivacy Fully Wired into Xcode project.pbxproj
428 " ✅ Android Bundle ID Updated and Package Directory Migrated
429 " 🟣 PrivacyInfo.xcprivacy File Created at ios/Runner/PrivacyInfo.xcprivacy
430 5:33p ✅ Bundle ID Migration Verified Complete — All Checks Passed
431 5:34p ✅ flutter build ios --no-codesign Succeeds with New Bundle ID
432 5:39p ✅ InStock Flutter App Bundle ID Migration: com.example → dev.traejiik
433 " 🟣 iOS Privacy Manifest (PrivacyInfo.xcprivacy) Created for App Store Submission
434 5:40p 🔵 Android APK Build Fails After Bundle ID Migration
435 5:41p ✅ Enabled Core Library Desugaring in Android build.gradle.kts
436 " ✅ Added coreLibraryDesugaring Dependency to Android Build
437 5:42p 🔴 Android APK Build Succeeds After Adding Core Library Desugaring
S60 InStock Flutter App — Bundle ID Migration + iOS Privacy Manifest + Android Build Fix + graphify graph update (May 7 at 5:42 PM)
438 5:45p 🔵 graphify CLI Available on InStock Dev Machine
S61 InStock Flutter App — Bundle ID Migration + iOS Privacy Manifest + Android Desugaring Fix — COMMITTED (May 7 at 5:45 PM)
439 " ✅ Bundle ID Migration + Privacy Manifest Changes Staged for Git Commit
440 6:21p 🔴 Android SQLite Crash Fixed After Drift Migration
441 " 🔴 Splash Screen Fixed to Use Correct Dark Brand Asset on Both Platforms
442 6:22p 🔵 Pre-Fix State Verified: drift_database.dart and launch_background.xml Already Correct
443 " ✅ Dark Splash Asset Copied to Tracked Assets Folder
444 " 🔴 pubspec.yaml Splash Config Updated to Dark Asset with Fullscreen Mode
445 " ✅ sqlite3_flutter_libs 0.5.42 Added as New Resolved Dependency
446 " 🔵 flutter_native_splash:create Overwrites launch_background.xml Color Element with Bitmap Fill
447 6:23p 🔵 flutter_native_splash Generates background.png as Solid Color Drawable for Fullscreen Mode
448 " ✅ Graphify Knowledge Graph Updated After SQLite and Splash Fixes
S62 InStock Flutter: Fix Android SQLite crash after Drift migration and fix splash screen on both platforms to use correct dark brand asset (May 7 at 6:23 PM)
449 6:38p 🔵 InStock Flutter Project Structure — Codebase Overview
450 " 🔵 InStock Has Extensive Uncommitted Changes Across Android/iOS/Dart Affecting Build
451 6:39p 🔵 Flutter Binary Broken — Permission Error on engine.stamp Blocks All Flutter Commands
452 " 🔵 Drift Database Migrated from drift_flutter to Manual sqlite3_flutter_libs Setup
453 " 🔵 Splash Screen and iOS Info.plist Changes May Cause iOS Build Issues
454 6:40p 🔵 flutter analyze Reveals Build-Blocking Error: openCipherOnAndroid Undefined in drift_database.dart
455 " 🔵 Android Gradle Uses Aggressive AGP 8.11.1 and Kotlin 2.2.20 — Potential Flutter Compatibility Risk
456 " 🔵 Android Build Confirms: openCipherOnAndroid Compile Error is the Primary Build Failure
457 " 🔵 Full Android Build Failure Chain Traced: Dart Compile Error → kernel_snapshot_program → assembleDebug FAILED
458 6:41p 🔵 iOS Device Build Has Two Distinct Failures: Dart Compile Error Plus Missing sqlite3.xcframework Binary
459 6:42p 🔵 openCipherOnAndroid Was Copied from a Drift Documentation Comment — Not a Real Function
460 " 🔵 @DriftDatabase Annotation Misplaced on _openDatabase() Function Instead of InStockDriftDb Class
461 " 🔵 iOS Podfile Missing Platform Declaration Causes CocoaPods Targets to Default to iOS 9.0
462 6:43p 🔵 Correct sqlite3_flutter_libs Pattern Confirmed — No Cipher Override Needed or Available
463 " 🔵 iOS Xcode Project Has Correct iOS 13.0 Deployment Target but No Development Team Configured
464 6:44p 🔵 Flutter Toolchain Fully Healthy — engine.stamp Error Is Sandbox Restriction, Not Real Flutter Issue
465 " 🔵 sqlite3 Source Explicitly Documents openCipherOnAndroid Comes from sqlcipher_flutter_libs Package

Access 386k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>