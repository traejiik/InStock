import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';

class QuantityBar extends StatelessWidget {
  final double fillLevel; // 0.0 – 1.0

  const QuantityBar({super.key, required this.fillLevel});

  @override
  Widget build(BuildContext context) {
    final color = fillLevel > 0.5
        ? AppColors.green
        : fillLevel > 0.1
            ? AppColors.amber
            : AppColors.red;

    return SizedBox(
      width: 60,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: fillLevel.clamp(0.0, 1.0),
          backgroundColor: AppColors.surface3,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ),
    );
  }
}
