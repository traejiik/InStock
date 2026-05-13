import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/models/app_models.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isMakeable;
  final int missingCount;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isMakeable,
    required this.missingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.surface2, colors.surface3],
          ),
          border: Border.all(color: colors.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _CardHero(recipe: recipe, height: 180, iconSize: 56),
              ),
            ),
            if (recipe.imageUrl != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: _MakeableBadge(
                isMakeable: isMakeable,
                missingCount: missingCount,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: AppTextStyles.headingMd),
                  const SizedBox(height: 4),
                  _MetaRow(recipe: recipe, missingCount: missingCount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeCardSm extends StatelessWidget {
  final Recipe recipe;
  final bool isMakeable;
  final int missingCount;
  final VoidCallback onTap;

  const RecipeCardSm({
    super.key,
    required this.recipe,
    required this.isMakeable,
    required this.missingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.surface2, colors.surface3],
          ),
          border: Border.all(color: colors.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _CardHero(recipe: recipe, height: 130, iconSize: 44),
              ),
            ),
            if (recipe.imageUrl != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: _MakeableBadge(
                isMakeable: isMakeable,
                missingCount: missingCount,
                small: true,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: AppTextStyles.headingSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${recipe.cookMinutes}m · ${recipe.servings} servings',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MakeableBadge extends StatelessWidget {
  final bool isMakeable;
  final int missingCount;
  final bool small;

  const _MakeableBadge({
    required this.isMakeable,
    required this.missingCount,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (bg, fg, label) = isMakeable
        ? (colors.greenDim, colors.green, '✓ Makeable')
        : (colors.amberDim, colors.amber, '$missingCount missing');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: small ? 10 : 11,
        ),
      ),
    );
  }
}

class _CardHero extends StatelessWidget {
  final Recipe recipe;
  final double height;
  final double iconSize;

  const _CardHero({
    required this.recipe,
    required this.height,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: recipe.imageUrl != null
          ? Image.network(
              recipe.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) =>
                  _Placeholder(height: height, iconSize: iconSize),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : _Placeholder(height: height, iconSize: iconSize),
            )
          : _Placeholder(height: height, iconSize: iconSize),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double height;
  final double iconSize;

  const _Placeholder({required this.height, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: height,
      child: Center(
        child: Icon(
          Icons.restaurant_menu_outlined,
          size: iconSize,
          color: colors.textTertiary,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Recipe recipe;
  final int missingCount;

  const _MetaRow({required this.recipe, required this.missingCount});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Icon(Icons.schedule, size: 12, color: colors.textTertiary),
        const SizedBox(width: 4),
        Text('${recipe.cookMinutes}m', style: AppTextStyles.caption),
        const SizedBox(width: 10),
        Icon(Icons.people_outline, size: 12, color: colors.textTertiary),
        const SizedBox(width: 4),
        Text('${recipe.servings}', style: AppTextStyles.caption),
        if (missingCount > 0) ...[
          const SizedBox(width: 10),
          Icon(Icons.warning_amber_outlined, size: 12, color: colors.amber),
          const SizedBox(width: 4),
          Text(
            '$missingCount missing',
            style: AppTextStyles.caption.copyWith(color: colors.amber),
          ),
        ],
      ],
    );
  }
}
