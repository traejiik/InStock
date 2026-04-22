import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/models/app_models.dart';

class CategoryDivider extends StatelessWidget {
  final IngredientCategory category;

  const CategoryDivider({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Text(
            '${category.emoji} ${category.label}',
            style: AppTextStyles.caption.copyWith(
              color: category.color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: AppColors.border, height: 1, thickness: 1)),
        ],
      ),
    );
  }
}
