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

## Color Tokens (Dark Mode)

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

## Color Tokens (Light Mode)

Light mode is an opt-in appearance (Settings → Appearance → Light). It mirrors the dark theme's hierarchy and intent — same hue families, same component shapes, same status semantics — only the surface stack is inverted and accents are tuned for AA contrast on light backgrounds. Do not introduce light-mode-only patterns; if a screen looks wrong in one mode, fix the structure, not the palette.

### Base Surfaces (light)

| Token | Hex | Usage |
| --- | --- | --- |
| `AppColors.background` | `#F6F7F8` | App scaffold (off-white, never pure `#FFFFFF`) |
| `AppColors.surface` | `#FFFFFF` | Bottom nav, primary surface, cards |
| `AppColors.surface2` | `#F1F2F4` | Inputs, raised rows, segmented track |
| `AppColors.surface3` | `#E6E8EC` | Secondary controls and chips |
| `AppColors.border` | `#E2E4E9` | Default borders and dividers |
| `AppColors.borderSubtle` | `rgba(14,15,17,0.06)` | Low-emphasis separators |

### Text (light)

| Token | Hex | Usage |
| --- | --- | --- |
| `AppColors.textPrimary` | `#0E0F11` | Primary labels and content |
| `AppColors.textSecondary` | `#5A5F6B` | Secondary copy and metadata |
| `AppColors.textTertiary` | `#9AA0A6` | Disabled, inactive, quiet hints |

### Status and Category Colors (light)

Status hues shift slightly deeper than their dark-mode counterparts so they hold contrast against white surfaces. `*Dim` tokens become pale tints (used for status pills, active nav pill, selected segments).

| Token | Hex | Usage |
| --- | --- | --- |
| `AppColors.green` | `#22C55E` | Primary action, in-stock, active nav |
| `AppColors.greenInk` | `#15803D` | Text/icon color on `greenDim` surfaces |
| `AppColors.greenDim` | `#DCFCE7` | Green tinted background |
| `AppColors.greenBorder` | `#BBF7D0` | Green focused/selected border |
| `AppColors.amber` | `#D97706` | Low stock or warning |
| `AppColors.amberInk` | `#92400E` | Text on `amberDim` |
| `AppColors.amberDim` | `#FEF3C7` | Amber tinted background |
| `AppColors.red` | `#DC2626` | Missing, destructive, error |
| `AppColors.redInk` | `#991B1B` | Text on `redDim` |
| `AppColors.redDim` | `#FEE2E2` | Red tinted background |
| `AppColors.blue` | `#2563EB` | Dairy/category accent |
| `AppColors.blueDim` | `#DBEAFE` | Blue tinted background |
| `AppColors.purple` | `#7C3AED` | Spice/secondary accent, AI affordances |
| `AppColors.purpleDim` | `#EDE9FE` | Purple tinted background |
| `AppColors.purpleBorder` | `#DDD6FE` | Purple focused/selected border |
| `AppColors.teal` | `#0D9488` | Custom/other accent |
| `AppColors.tealDim` | `#CCFBF1` | Teal tinted background |

### Light-Mode Rules

- The primary FAB stays vivid green (`#22C55E`) with dark ink (`#062014`) and the same green-tinted shadow — it's the one element that reads identically across modes.
- Status pills in light mode pair a `*Dim` background with the matching `*Ink` text token. Never put `AppColors.red` text on `AppColors.background` — it vibrates; use `redInk` on `redDim`.
- Cards and rows sit on `surface` (`#FFFFFF`) **with** a 1px `border` outline. Do not rely on shadows alone to separate cards from the scaffold; the contrast between `background` and `surface` is intentionally subtle.
- The active bottom-nav pill uses `greenDim` (not a solid green) with `green` icon + label, matching dark mode's structure.
- Floating labels on focused inputs use `greenInk` on `surface` — not `green` — so they remain readable when the label sits in front of the field.
- The destructive "Clear All Data" surface uses `redDim` background + `#FCA5A5` border + `red` icon/heading + `redInk` body copy. Apply the same recipe to any future destructive surfaces.
- Do not introduce new light-only tokens. If you find yourself needing one, the dark theme is probably missing a counterpart — add the pair together.

### Theming Rules (additions)

- `AppTheme.light` is exposed alongside `AppTheme.dark`; `MaterialApp` selects based on the user's `Appearance` setting (Light / Dark / System).
- `ColorScheme.primary` remains green in both modes; `onPrimary` is `#062014` in light, `#0E0F11` in dark.
- Inputs use `surface2` fill, `border` outline, and `green` focused border in both modes.
- Bottom navigation surface is `surface` (white) in light, dark surface in dark; selected color is `green` in both.

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

- `AppTheme.dark` and `AppTheme.light` are both registered; the active theme follows the user's Appearance setting
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
