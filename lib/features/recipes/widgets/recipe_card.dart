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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface2, AppColors.surface3],
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(recipe.emoji, style: const TextStyle(fontSize: 64)),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _MakeableBadge(isMakeable: isMakeable, missingCount: missingCount),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface2, AppColors.surface3],
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: 130,
              child: Center(
                child: Text(recipe.emoji, style: const TextStyle(fontSize: 48)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _MakeableBadge(isMakeable: isMakeable, missingCount: missingCount, small: true),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: AppTextStyles.headingSm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
    final (bg, fg, label) = isMakeable
        ? (AppColors.greenDim, AppColors.green, '✓ Makeable')
        : (AppColors.amberDim, AppColors.amber, '$missingCount missing');

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 3 : 4),
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

class _MetaRow extends StatelessWidget {
  final Recipe recipe;
  final int missingCount;

  const _MetaRow({required this.recipe, required this.missingCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.schedule, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text('${recipe.cookMinutes}m',
            style: AppTextStyles.caption),
        const SizedBox(width: 10),
        const Icon(Icons.people_outline, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text('${recipe.servings}',
            style: AppTextStyles.caption),
        if (missingCount > 0) ...[
          const SizedBox(width: 10),
          const Icon(Icons.warning_amber_outlined, size: 12, color: AppColors.amber),
          const SizedBox(width: 4),
          Text('$missingCount missing',
              style: AppTextStyles.caption.copyWith(color: AppColors.amber)),
        ],
      ],
    );
  }
}
