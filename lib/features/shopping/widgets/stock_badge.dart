import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/models/app_models.dart';

class StockBadge extends StatelessWidget {
  final StockStatus status;

  const StockBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (bg, fg, label) = switch (status) {
      StockStatus.inStock => (colors.greenDim, colors.greenInk, 'In stock'),
      StockStatus.low => (colors.amberDim, colors.amberInk, 'Low'),
      StockStatus.need => (colors.redDim, colors.redInk, 'Need'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
