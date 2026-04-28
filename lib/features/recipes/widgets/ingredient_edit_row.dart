import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/shared/widgets/unit_picker.dart';

class IngredientEditRow extends StatefulWidget {
  final String initialName;
  final double initialQuantity;
  final String? initialUnit;
  final void Function(String name, double quantity, String? unit) onChanged;

  const IngredientEditRow({
    super.key,
    required this.initialName,
    required this.initialQuantity,
    this.initialUnit,
    required this.onChanged,
  });

  @override
  State<IngredientEditRow> createState() => _IngredientEditRowState();
}

class _IngredientEditRowState extends State<IngredientEditRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late String? _unit;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _qtyCtrl = TextEditingController(
      text: widget.initialQuantity > 0 ? _formatQty(widget.initialQuantity) : '',
    );
    _unit = widget.initialUnit;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(1);
  }

  void _notify() {
    final qty = double.tryParse(_qtyCtrl.text) ?? 1;
    widget.onChanged(_nameCtrl.text, qty, _unit);
  }

  void _showUnitPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select unit', style: AppTextStyles.headingSm),
            const SizedBox(height: 12),
            UnitPicker(
              selectedUnit: _unit,
              onChanged: (u) {
                setState(() => _unit = u);
                Navigator.pop(ctx);
                _notify();
              },
              allowCustom: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: TextField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.bodyMd,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Qty',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            ),
            onChanged: (_) => _notify(),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _showUnitPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _unit ?? '—',
              style: AppTextStyles.caption.copyWith(
                color: _unit != null
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _nameCtrl,
            style: AppTextStyles.bodyMd,
            decoration: const InputDecoration(
              hintText: 'Ingredient name',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            onChanged: (_) => _notify(),
          ),
        ),
      ],
    );
  }
}
