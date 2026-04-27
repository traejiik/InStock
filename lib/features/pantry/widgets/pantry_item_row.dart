import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/core/utils/unit_converter.dart';
import 'package:instock/data/models/app_models.dart';
import 'quantity_bar.dart';

class PantryItemRow extends StatelessWidget {
  final PantryItem item;
  final Ingredient ingredient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PantryItemRow({
    super.key,
    required this.item,
    required this.ingredient,
    this.onTap,
    this.onLongPress,
  });

  String _daysAgo() {
    final diff = DateTime.now().difference(item.addedAt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return '1 day ago';
    return '$diff days ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ingredient.category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingredient.canonicalName, style: AppTextStyles.label),
                  Text('Added ${_daysAgo()}',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  UnitConverter.formatQty(item.quantity, item.unit),
                  style: AppTextStyles.bodySm.copyWith(
                    color: item.quantity == 0 ? AppColors.red : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                QuantityBar(fillLevel: item.fillLevel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
