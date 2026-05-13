import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';

class SortChipRow extends StatelessWidget {
  final List<String> chips;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SortChipRow({
    super.key,
    required this.chips,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.asMap().entries.map((e) {
          final isSelected = e.key == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.greenDim : colors.surface3,
                  border: Border.all(
                    color: isSelected ? colors.greenBorder : colors.border,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  e.value,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isSelected ? colors.green : colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
