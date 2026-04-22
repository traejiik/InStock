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
    return GestureDetector(
      onTap: () => setState(() => _done = !_done),
      child: Opacity(
        opacity: _done ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
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
                  color: _done ? AppColors.green : AppColors.surface3,
                  border: Border.all(
                    color: _done ? AppColors.green : AppColors.border,
                  ),
                ),
                child: Center(
                  child: _done
                      ? const Icon(Icons.check, color: AppColors.background, size: 14)
                      : Text(
                          '${widget.stepNumber}',
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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
                      decorationColor: AppColors.textSecondary,
                      color: _done ? AppColors.textSecondary : AppColors.textPrimary,
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
