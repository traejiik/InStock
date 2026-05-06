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

# [InStock] recent context, 2026-05-04 3:56am GMT+2

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (19,986t read) | 1,294,603t work | 98% savings

### Apr 27, 2026
S37 Flutter InStock app: fix duplicate shopping/pantry list rows + add UnitPicker chip widget with full integration (Apr 27 at 6:35 PM)
S38 Flutter InStock app — Fix B: Add persistent check-in trigger button to Pantry screen header, replacing amber notification pill (Apr 27 at 6:35 PM)
201 7:37p 🔴 Color.withOpacity Replaced with Color.withValues for Flutter Analyze Compliance
202 " 🔴 Pantry Title Long-Press Not Firing — Root Cause: Missing HitTestBehavior.opaque
203 " 🟣 UnitPicker Chips — Size-Aware Shape System (Circle/Pill) with AnimatedContainer
S39 Fix C: Pantry title long-press not firing (HitTestBehavior.opaque fix) + UnitPicker size-aware chip shapes (Apr 27 at 7:37 PM)
S40 Complete Phase 2 implementation of recipe creation functionality for Flutter Fridge app and verify code quality and compilation (Apr 27 at 8:15 PM)
204 8:15p 🔴 Long-press Debug Trigger Fixed with HitTestBehavior.opaque on Full Expanded Column
205 8:16p 🔄 _debugResetVerification() Method Removed — Dead Code After Inline Closure Migration
206 " 🟣 UnitPicker Rewritten with Size-Aware _buildChip() and _UnitChipSize Enum
### Apr 28, 2026
207 8:50p ⚖️ Fridge App Phase 2: Recipe Import Architecture Specified
208 8:52p 🔵 InStock/Fridge Uses SharedPreferences + ChangeNotifier, NOT Drift SQLite
209 " 🔵 ImportRecipeScreen Already Exists with Mock Behavior — Phase 2 Must Replace It
210 " ✅ Added HTTP scraping and image caching dependencies for recipe import
211 9:05p ✅ Extended Recipe model to support imageUrl field for scraped recipe images
212 " 🟣 Implemented recipe scraper with JSON-LD and DOM fallback parsing
213 9:06p 🟣 Created recipe import Riverpod provider for async scrape state management
214 " 🟣 Implemented recipe form state provider with full ingredient and step management
215 " 🟣 Created inline ingredient edit row widget with unit picker modal
S41 Complete Phase 2 recipe creation implementation for Flutter Fridge app with code quality verification, build testing, and final quality assurance checks (Apr 28 at 9:06 PM)
216 9:07p 🟣 Created step edit row widget for recipe instruction editing
S43 Fix C: Defer RecipeFormNotifier.loadFromParsed() to post-frame callback — bug fixed and verified; session now moving to new work (Apr 28 at 9:11 PM)
### Apr 29, 2026
217 12:29a 🔴 Riverpod Provider Mutation During Build Phase Fixed in Recipe Review Screen
218 " 🔵 Riverpod Violation Located: loadFromParsed Called Synchronously in initState
219 12:30a 🔴 RecipeReviewScreen initState Fixed: loadFromParsed Deferred to Post-Frame Callback
220 " 🔵 AddRecipeScreen Already Follows Post-Frame Pattern; flutter analyze Passes Clean
S42 Fix C: Defer RecipeFormNotifier.loadFromParsed() to post-frame callback in InStock (Fridge) Flutter app to resolve Riverpod "provider modified during widget build" exception (Apr 29 at 12:30 AM)
S44 Two bugs fixed in InStock Flutter app: (1) Riverpod provider-mutation-during-build in RecipeReviewScreen; (2) FloatingActionButton heroTag conflicts across all three FAB screens (Apr 29 at 12:30 AM)
221 12:31a 🔴 FloatingActionButton heroTag Conflicts Fixed — Unique Tags Added to Prevent Hero Animation Crash
S45 Fix D — Four bugs in Fridge Flutter app: ingredient name cleaner, isOptional detection, overflow layout, and hero image display (Apr 29 at 12:32 AM)
222 12:35a ⚖️ Fix B: Replace CachedNetworkImage with Image.network to Eliminate sqflite MissingPluginException
223 " 🔵 CachedNetworkImage Usage Mapped: Two Call Sites, Both Already Have _ImageFallback Widgets
224 " 🔴 CachedNetworkImage Replaced with Image.network in Both Recipe Screens to Fix MissingPluginException
225 12:36a 🔴 Fix B Complete: All CachedNetworkImage Usages Replaced with Image.network, flutter analyze Passes Clean
226 5:20a 🔴 Ingredient Name Cleaner Added to RecipeScraper
227 " 🔴 isOptional Flag Wired from Scraper Through to IngredientFormRow
228 " 🔴 IngredientRow Text Overflow Fixed with Expanded Widget
229 " 🔴 RecipeDetailScreen Hero Area Now Shows Scraped Network Image
230 " 🔴 ParsedIngredient Gains isOptional Field and Name Cleaner Applied in RecipeScraper
231 " 🔵 ingredient_row.dart and recipe_form_provider.dart Already Had isOptional Before Fixes Applied
232 5:21a 🔴 Three Remaining Fixes Applied: isOptional Propagation, Text Overflow, and Hero Image
233 " 🔴 Dart const Correctness Fix on Gradient Scrim in _HeroArea
234 " 🔵 flutter analyze Passes Clean After All Fix D Changes
235 " 🟣 New Feature Request: Recipe Deletion and Image on Recipe Cards
236 5:27a 🔵 Recipe Model Already Has deletedAt and imageUrl Fields — Soft-Delete Pattern Pre-Exists
237 5:28a 🔵 Recipe Model Has deletedAt But No deleteRecipe() Method or copyWith()
238 " 🟣 Implementation Plan: Recipe Delete + Card Images + Icon Placeholder
239 5:36a 🟣 Recipe.copyWith() Added to app_models.dart
240 " 🟣 deleteRecipe() Implemented in AppDatabase
241 " 🟣 Recipe Cards Now Show Network Images with Icon Placeholder
S46 Add delete recipe, render recipe card images, and show icon placeholder instead of emoji — InStock Flutter app (Apr 29 at 5:37 AM)
242 9:41p 🔵 InStock Git Author Identity Mismatch — AnoAtHive vs traejiik/Anotida
243 " 🔵 InStock Flutter App — Architecture and Feature Map
244 9:42p 🔵 InStock Full Commit Timeline and Measurable Contribution Stats
245 " 🔵 InStock Tech Stack and Dependency Profile
246 " 🔵 InStock Domain Model Design — Ingredient, PantryItem, Recipe
247 9:43p 🔵 AppDatabase Uses SharedPreferences JSON — Not SQLite Despite the Name
248 " 🟣 Recipe Web Scraper with JSON-LD + Heuristic Fallback and Metric Conversion
249 " 🔵 Smart Cross-Feature Business Logic: Pantry-Recipe Matching and Serving-Scaled Shopping
250 " 🔵 Uncommitted Changes and Active Work-in-Progress Fix

Access 1295k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>