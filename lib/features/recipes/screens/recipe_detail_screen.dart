import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/core/utils/unit_converter.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import '../widgets/ingredient_row.dart';
import '../widgets/step_row.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late int _servings;
  bool _servingsInitialized = false;

  Future<void> _confirmDelete(String recipeId) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Delete recipe?', style: AppTextStyles.headingMd),
        content: Text(
          'This cannot be undone.',
          style: AppTextStyles.bodyMd.copyWith(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.label),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: AppTextStyles.label.copyWith(color: colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(appDatabaseProvider).deleteRecipe(recipeId);
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onWarning = Theme.of(context).brightness == Brightness.light
        ? colors.textPrimary
        : colors.background;
    final db = ref.watch(appDatabaseProvider);
    final recipe = db.recipeById(widget.recipeId);

    if (recipe == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(backgroundColor: colors.background, elevation: 0),
        body: Center(
          child: Text(
            'Recipe not found',
            style: AppTextStyles.bodyMd.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    if (!_servingsInitialized) {
      _servings = recipe.servings;
      _servingsInitialized = true;
    }

    final recipeIngredients = db.ingredientsForRecipe(recipe.id);
    final isMakeable = db.isRecipeMakeable(recipe.id);
    final missingCount = db.missingCountForRecipe(recipe.id);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroArea(
                    recipe: recipe,
                    isMakeable: isMakeable,
                    missingCount: missingCount,
                    servings: _servings,
                    onDelete: () => _confirmDelete(recipe.id),
                    onServingsDecrement: () => setState(
                      () => _servings = (_servings - 1).clamp(1, 99),
                    ),
                    onServingsIncrement: () => setState(
                      () => _servings = (_servings + 1).clamp(1, 99),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Ingredients',
                          count: recipeIngredients.length,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (recipeIngredients.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          'No ingredients added yet — tap ✎ to edit',
                          style: AppTextStyles.bodySm.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final ri = recipeIngredients[i];
                        final ing = db.ingredientById(ri.ingredientId);
                        if (ing == null) return const SizedBox.shrink();
                        final scaledQty = UnitConverter.scaleQuantity(
                          ri.quantity,
                          recipe.servings,
                          _servings,
                        );
                        return IngredientRow(
                          recipeIngredient: ri,
                          ingredient: ing,
                          matchStatus: db.matchStatus(
                            ri.ingredientId,
                            scaledQty,
                            ri.unit,
                          ),
                          scaledQuantity: scaledQty,
                        );
                      }, childCount: recipeIngredients.length),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Instructions',
                      count: recipe.instructions.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    recipe.notes?.trim().isNotEmpty == true ? 24 : 100,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => StepRow(
                        stepNumber: i + 1,
                        text: recipe.instructions[i],
                      ),
                      childCount: recipe.instructions.length,
                    ),
                  ),
                ),
                if (recipe.notes?.trim().isNotEmpty == true) ...[
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(title: 'Notes', count: 1),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverToBoxAdapter(
                      child: _NotesCard(notes: recipe.notes!.trim()),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _BottomBar(
            recipe: recipe,
            servings: _servings,
            missingCount: missingCount,
            onAddMissing: () {
              final count = ref
                  .read(appDatabaseProvider)
                  .addMissingToShopping(recipe.id, _servings);
              final msg = count == 0
                  ? 'You already have everything for this recipe'
                  : '$count item${count == 1 ? '' : 's'} added to your shopping list';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    msg,
                    style: AppTextStyles.bodySm.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  backgroundColor: colors.surface2,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            onCooked: () {
              final db = ref.read(appDatabaseProvider);
              final missing = db.firstMissingNonOptional(recipe.id);
              if (missing != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "You're missing $missing. Add it to your pantry first, or mark it as optional.",
                      style: AppTextStyles.bodySm.copyWith(color: onWarning),
                    ),
                    backgroundColor: colors.amber,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }
              db.decrementPantryForRecipe(recipe.id, _servings);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pantry updated — enjoy your meal! 🍳',
                    style: AppTextStyles.bodySm.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  backgroundColor: colors.surface2,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroArea extends StatelessWidget {
  final Recipe recipe;
  final bool isMakeable;
  final int missingCount;
  final int servings;
  final VoidCallback onDelete;
  final VoidCallback onServingsDecrement;
  final VoidCallback onServingsIncrement;

  const _HeroArea({
    required this.recipe,
    required this.isMakeable,
    required this.missingCount,
    required this.servings,
    required this.onDelete,
    required this.onServingsDecrement,
    required this.onServingsIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.48).clamp(360.0, 430.0);

    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          // Background / image
          Positioned.fill(
            child: recipe.imageUrl != null
                ? Image.network(
                    recipe.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const _RecipePlaceholder(),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const _RecipePlaceholder(),
                  )
                : const _RecipePlaceholder(),
          ),

          // Gradient scrim so the back button stays readable over photos
          if (recipe.imageUrl != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0x99000000),
                      const Color(0x22000000),
                      colors.background,
                    ],
                    stops: const [0.0, 0.46, 1.0],
                  ),
                ),
              ),
            ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _CircleButton(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back,
                color: colors.textPrimary,
                size: 20,
              ),
            ),
          ),

          // Delete button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 60,
            child: _CircleButton(
              onTap: onDelete,
              child: Icon(Icons.delete_outline, color: colors.red, size: 20),
            ),
          ),

          // Makeable badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isMakeable ? colors.greenDim : colors.amberDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMakeable ? colors.green : colors.amber,
                  width: 1,
                ),
              ),
              child: Text(
                isMakeable ? '✓ Makeable' : '$missingCount missing',
                style: AppTextStyles.caption.copyWith(
                  color: isMakeable ? colors.green : colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: AppTextStyles.displayLg.copyWith(
                    color: colors.textPrimary,
                    shadows: const [
                      Shadow(
                        blurRadius: 16,
                        color: Color(0xCC000000),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _MetaChips(recipe: recipe),
                const SizedBox(height: 16),
                _ServingsControl(
                  servings: servings,
                  onDecrement: onServingsDecrement,
                  onIncrement: onServingsIncrement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Text(notes, style: AppTextStyles.bodyMd),
    );
  }
}

class _RecipePlaceholder extends StatelessWidget {
  const _RecipePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surface2, colors.background],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_outlined,
          size: 72,
          color: colors.textTertiary,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _CircleButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: child,
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  final Recipe recipe;
  const _MetaChips({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _Chip(icon: Icons.schedule, label: '${recipe.cookMinutes} min'),
        _Chip(
          icon: Icons.local_fire_department_outlined,
          label: recipe.difficulty,
        ),
        if (recipe.sourceUrl != null)
          const _Chip(icon: Icons.link, label: 'Source'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ServingsControl extends StatelessWidget {
  final int servings;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _ServingsControl({
    required this.servings,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text('Servings', style: AppTextStyles.label),
          const Spacer(),
          _RoundButton(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$servings', style: AppTextStyles.headingMd),
          ),
          _RoundButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: 16, color: colors.textPrimary),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Text(title, style: AppTextStyles.headingMd),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colors.surface3,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count', style: AppTextStyles.caption),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Recipe recipe;
  final int servings;
  final int missingCount;
  final VoidCallback onAddMissing;
  final VoidCallback onCooked;

  const _BottomBar({
    required this.recipe,
    required this.servings,
    required this.missingCount,
    required this.onAddMissing,
    required this.onCooked,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          if (missingCount > 0)
            Expanded(
              flex: 2,
              child: _BarButton(
                label: '+ Add Missing',
                bg: colors.green,
                fg: onPrimary,
                onTap: onAddMissing,
              ),
            ),
          if (missingCount > 0) const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _BarButton(
              label: '🍳 Cooked',
              bg: colors.surface3,
              fg: colors.textPrimary,
              onTap: onCooked,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _BarButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(color: fg),
        ),
      ),
    );
  }
}
