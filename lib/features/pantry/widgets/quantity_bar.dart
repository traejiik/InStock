import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';

class QuantityBar extends StatelessWidget {
  final double fillLevel; // 0.0 – 1.0

  const QuantityBar({super.key, required this.fillLevel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = fillLevel > 0.5
        ? colors.green
        : fillLevel > 0.1
        ? colors.amber
        : colors.red;

    return SizedBox(
      width: 60,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: fillLevel.clamp(0.0, 1.0),
          backgroundColor: colors.surface3,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ),
    );
  }
}
