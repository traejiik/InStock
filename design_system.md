# InStock Design System

This document describes the current design system used by the Flutter app. Treat the Dart theme files as the source of truth:

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/shared/widgets/`

## Product Feel

InStock/Fridge is a dark, practical pantry and grocery workflow app. The interface should feel fast to scan, calm under repeated use, and lightly tactile. It is not a marketing site, recipe magazine, or decorative dashboard.

Prefer:

- Compact, organized lists
- Clear item status
- Direct actions close to the item they affect
- Muted surfaces with high-signal accent colors
- Simple motion for feedback and state changes

Avoid:

- Oversized hero layouts on workflow screens
- Decorative gradients that compete with food and inventory information
- New one-off colors
- Nested cards and heavy chrome
- Copy that explains the UI inside the UI

## Color Tokens

Use `AppColors` directly. Do not hardcode hex values in widgets unless adding a new token first.

### Base Surfaces

| Token | Hex | Usage |
| --- | --- | --- |
| `AppColors.background` | `#0E0F11` | App scaffold background |
| `AppColors.surface` | `#17181C` | Bottom nav and primary surface |
| `AppColors.surface2` | `#1F2026` | Inputs, cards, raised rows |
| `AppColors.surface3` | `#26272E` | Secondary controls and chips |
| `AppColors.border` | `#2E2F38` | Default borders and dividers |
| `AppColors.borderSubtle` | `#332E2F38` | Low-emphasis separators |

### Text

| Token | Hex | Usage |
| --- | --- | --- |
| `AppColors.textPrimary` | `#F0F0F2` | Primary labels and content |
| `AppColors.textSecondary` | `#8B8C99` | Secondary copy and metadata |
| `AppColors.textTertiary` | `#555663` | Disabled, inactive, quiet hints |

### Status and Category Colors

| Token | Hex | Usage |
| --- | --- | --- |
| `AppColors.green` | `#4ADE80` | Primary action, in-stock, active nav |
| `AppColors.greenDim` | `#1A3828` | Green tinted background |
| `AppColors.amber` | `#FBBF24` | Low stock or warning |
| `AppColors.amberDim` | `#2D2310` | Amber tinted background |
| `AppColors.red` | `#F87171` | Missing, destructive, error |
| `AppColors.redDim` | `#2D1515` | Red tinted background |
| `AppColors.blue` | `#60A5FA` | Dairy/category accent |
| `AppColors.blueDim` | `#0F1F35` | Blue tinted background |
| `AppColors.purple` | `#A78BFA` | Spice/secondary accent |
| `AppColors.purpleDim` | `#1E1530` | Purple tinted background |
| `AppColors.teal` | `#2DD4BF` | Custom/other accent |
| `AppColors.tealDim` | `#0D2825` | Teal tinted background |

Precomputed alpha variants exist for common borders/surfaces:

- `AppColors.greenBorder`
- `AppColors.greenSurface`
- `AppColors.purpleBorder`

## Typography

Use `AppTextStyles` for text in custom widgets.

Display and headings use Bricolage Grotesque. Body, labels, captions, and the app `TextTheme` use DM Sans.

| Token | Size | Weight | Line Height | Usage |
| --- | ---: | ---: | ---: | --- |
| `displayLg` | 32 | 800 | 1.1 | Screen-level expressive headings |
| `headingLg` | 22 | 800 | 1.2 | Main section titles |
| `headingMd` | 18 | 700 | 1.3 | Card or screen subsections |
| `headingSm` | 15 | 700 | 1.3 | Compact row titles |
| `bodyLg` | 16 | 400 | 1.5 | Main readable content |
| `bodyMd` | 14 | 400 | 1.5 | Default body text |
| `bodySm` | 12 | 400 | 1.4 | Dense metadata and small controls |
| `label` | 14 | 500 | 1.4 | Form labels and action labels |
| `caption` | 11 | 400 | 1.4 | Timestamps, nav labels, minor metadata |

## Shape and Spacing

Current components favor compact radii:

- Inputs: 10px radius
- Chips: 6px radius
- Segmented controls: 10px outer, 8px selected segment
- Toggle rows: 12px radius
- Floating action menu items: 12px radius
- Bottom nav active pill: 20px radius

Spacing patterns:

- Dense horizontal controls use 8px gaps.
- Row padding commonly uses 12-14px vertical and 14-16px horizontal.
- Bottom navigation height is 60px inside the safe area.
- Prefer stable row heights and predictable list rhythm over decorative whitespace.

## Core Components

### App Shell

`AppShell` wraps the stateful navigation shell and owns the bottom nav. New tab-level screens should be added through `app_router.dart` and `AppBottomNav` together so index order stays aligned.

### Bottom Navigation

`AppBottomNav` uses four destinations:

- Shopping
- Pantry
- Recipes
- Settings

Active state uses `AppColors.green` with a `greenDim` pill. Inactive icons and labels use `textTertiary`.

### Controls

Use these shared widgets before creating new ones:

- `SegmentControl` for mutually exclusive modes
- `SortChipRow` for horizontal filters and sorts
- `ToggleRow` for settings-style boolean rows
- `FabMenu` for clustered primary actions

### Lists and Inventory Rows

Inventory and shopping UI should make status obvious without requiring prose. Use:

- Green for enough/in stock
- Amber for low/partial
- Red for missing/need
- Category colors from `IngredientCategoryX.color`

Keep item names, quantities, and actions visually close together. A pantry app that makes the user hunt for the quantity has lost the plot.

## Theming Rules

- `AppTheme.dark` is the active app theme.
- `ColorScheme.primary` is green.
- `ColorScheme.secondary` is purple.
- Inputs use `surface2`, border `border`, and focused border `green`.
- Floating action buttons use green background and dark foreground.
- Bottom navigation is fixed type, dark surface, green selected items.

## Adding New UI

When adding a screen or component:

1. Start from existing tokens and shared widgets.
2. Pick the smallest surface hierarchy that makes the information readable.
3. Use status colors only when they communicate state.
4. Keep text concise and action-oriented.
5. Check mobile widths for label overflow.
6. Add a reusable widget only when at least two screens need the pattern or the component is complex enough to isolate.

## Accessibility

- Maintain strong contrast against the dark background.
- Do not communicate status by color alone; pair color with icon, label, position, or quantity text where practical.
- Keep tap targets comfortable even in dense lists.
- Avoid tiny text for critical quantities or destructive actions.
