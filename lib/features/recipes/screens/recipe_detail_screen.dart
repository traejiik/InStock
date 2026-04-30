import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/core/utils/unit_converter.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/features/ai/widgets/ai_tinker_sheet.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete recipe?', style: AppTextStyles.headingMd),
        content: Text(
          'This cannot be undone.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
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
              style: AppTextStyles.label.copyWith(color: AppColors.red),
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
    final db = ref.watch(appDatabaseProvider);
    final recipe = db.recipeById(widget.recipeId);

    if (recipe == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(
          child: Text(
            'Recipe not found',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
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
      backgroundColor: AppColors.background,
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'No ingredients added yet — tap ✎ to edit',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textSecondary,
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
                        return IngredientRow(
                          recipeIngredient: ri,
                          ingredient: ing,
                          matchStatus: db.matchStatus(
                            ri.ingredientId,
                            ri.quantity,
                            ri.unit,
                          ),
                          scaledQuantity: UnitConverter.scaleQuantity(
                            ri.quantity,
                            recipe.servings,
                            _servings,
                          ),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: AppColors.surface2,
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
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.background,
                      ),
                    ),
                    backgroundColor: AppColors.amber,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: AppColors.surface2,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            onAI: () => AiTinkerSheet.show(context, recipeName: recipe.title),
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
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Color(0x22000000),
                      AppColors.background,
                    ],
                    stops: [0.0, 0.46, 1.0],
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
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
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
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.red,
                size: 20,
              ),
            ),
          ),

          // Makeable badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isMakeable ? AppColors.greenDim : AppColors.amberDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMakeable ? AppColors.green : AppColors.amber,
                  width: 1,
                ),
              ),
              child: Text(
                isMakeable ? '✓ Makeable' : '$missingCount missing',
                style: AppTextStyles.caption.copyWith(
                  color: isMakeable ? AppColors.green : AppColors.amber,
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
                    color: AppColors.textPrimary,
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

class _RecipePlaceholder extends StatelessWidget {
  const _RecipePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface2, AppColors.background],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_outlined,
          size: 72,
          color: AppColors.textTertiary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
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
    return Row(
      children: [
        Text(title, style: AppTextStyles.headingMd),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surface3,
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
  final VoidCallback onAI;

  const _BottomBar({
    required this.recipe,
    required this.servings,
    required this.missingCount,
    required this.onAddMissing,
    required this.onCooked,
    required this.onAI,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (missingCount > 0)
            Expanded(
              flex: 2,
              child: _BarButton(
                label: '+ Add Missing',
                bg: AppColors.green,
                fg: AppColors.background,
                onTap: onAddMissing,
              ),
            ),
          if (missingCount > 0) const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _BarButton(
              label: '🍳 Cooked',
              bg: AppColors.surface3,
              fg: AppColors.textPrimary,
              onTap: onCooked,
            ),
          ),
          const SizedBox(width: 8),
          _BarButton(
            label: '✨ AI',
            bg: AppColors.purpleDim,
            fg: AppColors.purple,
            onTap: onAI,
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
