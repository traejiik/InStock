import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';

class StepRow extends StatefulWidget {
  final int stepNumber;
  final String text;

  const StepRow({super.key, required this.stepNumber, required this.text});

  @override
  State<StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<StepRow> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return GestureDetector(
      onTap: () => setState(() => _done = !_done),
      child: Opacity(
        opacity: _done ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _done ? colors.green : colors.surface3,
                  border: Border.all(
                    color: _done ? colors.green : colors.border,
                  ),
                ),
                child: Center(
                  child: _done
                      ? Icon(Icons.check, color: onPrimary, size: 14)
                      : Text(
                          '${widget.stepNumber}',
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.text,
                    style: AppTextStyles.bodyMd.copyWith(
                      decoration: _done ? TextDecoration.lineThrough : null,
                      decorationColor: colors.textSecondary,
                      color: _done ? colors.textSecondary : colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
