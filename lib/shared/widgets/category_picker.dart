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
    return DropdownButtonFormField<IngredientCategory>(
      initialValue: selectedCategory,
      isExpanded: true,
      dropdownColor: AppColors.surface2,
      borderRadius: BorderRadius.circular(10),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.textSecondary,
      ),
      style: AppTextStyles.label,
      decoration: const InputDecoration(labelText: 'Category'),
      selectedItemBuilder: (context) => IngredientCategory.values
          .map((category) => _CategoryMenuLabel(category: category))
          .toList(),
      items: IngredientCategory.values
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: _CategoryMenuLabel(category: category),
            ),
          )
          .toList(),
      onChanged: (category) {
        if (category == null) return;
        onChanged(category);
      },
    );
  }
}

class _CategoryMenuLabel extends StatelessWidget {
  final IngredientCategory category;

  const _CategoryMenuLabel({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${category.emoji} ${category.label}',
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
