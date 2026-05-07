import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/models/app_models.dart';

class CategoryPicker extends StatelessWidget {
  final IngredientCategory selectedCategory;
  final ValueChanged<IngredientCategory> onChanged;

  const CategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Category',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IngredientCategory.values.map((category) {
            final isSelected = category == selectedCategory;
            return GestureDetector(
              onTap: () => onChanged(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface2 : AppColors.surface3,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? category.color : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${category.emoji} ${category.label}',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: isSelected
                        ? category.color
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
