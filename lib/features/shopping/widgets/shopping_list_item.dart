import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/core/utils/unit_converter.dart';
import 'package:instock/data/models/app_models.dart';
import 'stock_badge.dart';

class ShoppingListItem extends StatelessWidget {
  final ShoppingItem item;
  final Ingredient ingredient;
  final StockStatus stockStatus;
  final String? sourceRecipeName;
  final VoidCallback onToggle;

  const ShoppingListItem({
    super.key,
    required this.item,
    required this.ingredient,
    required this.stockStatus,
    this.sourceRecipeName,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.checked ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.checked ? AppColors.green : Colors.transparent,
                  border: Border.all(
                    color: item.checked ? AppColors.green : AppColors.border,
                    width: 2,
                  ),
                ),
                child: item.checked
                    ? const Icon(Icons.check, color: AppColors.background, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.canonicalName,
                    style: AppTextStyles.label.copyWith(
                      decoration: item.checked ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                  if (item.checked)
                    Text('Added to pantry ✓',
                        style: AppTextStyles.caption.copyWith(color: AppColors.green))
                  else if (sourceRecipeName != null)
                    Text(sourceRecipeName!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.purple)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                UnitConverter.formatQty(item.quantity, item.unit),
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(width: 6),
            StockBadge(status: stockStatus),
          ],
        ),
      ),
    );
  }
}
