import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';

class StepEditRow extends StatefulWidget {
  final int stepNumber;
  final String initialText;
  final void Function(String text) onChanged;

  const StepEditRow({
    super.key,
    required this.stepNumber,
    required this.initialText,
    required this.onChanged,
  });

  @override
  State<StepEditRow> createState() => _StepEditRowState();
}

class _StepEditRowState extends State<StepEditRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 12, right: 10),
          decoration: BoxDecoration(
            color: AppColors.surface3,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.stepNumber}',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _ctrl,
            maxLines: null,
            minLines: 2,
            style: AppTextStyles.bodyMd,
            decoration: const InputDecoration(
              hintText: 'Describe this step…',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}
