import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/core/utils/unit_converter.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/widgets/stock_badge.dart';

class IngredientRow extends StatelessWidget {
  final RecipeIngredient recipeIngredient;
  final Ingredient ingredient;
  final PantryMatchStatus matchStatus;
  final double scaledQuantity;

  const IngredientRow({
    super.key,
    required this.recipeIngredient,
    required this.ingredient,
    required this.matchStatus,
    required this.scaledQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (matchStatus) {
      PantryMatchStatus.enough => ('In pantry', AppColors.green),
      PantryMatchStatus.partial => ('Partial', AppColors.amber),
      PantryMatchStatus.missing => ('Missing', AppColors.red),
    };

    final stockStatus = switch (matchStatus) {
      PantryMatchStatus.enough => StockStatus.inStock,
      PantryMatchStatus.partial => StockStatus.low,
      PantryMatchStatus.missing => StockStatus.need,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ingredient.canonicalName,
                        style: AppTextStyles.label,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                    if (recipeIngredient.isOptional) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('optional', style: AppTextStyles.caption),
                      ),
                    ],
                  ],
                ),
                Text(statusLabel,
                    style: AppTextStyles.caption.copyWith(color: statusColor)),
              ],
            ),
          ),
          Text(
            UnitConverter.formatQty(scaledQuantity, recipeIngredient.unit),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          StockBadge(status: stockStatus),
        ],
      ),
    );
  }
}
