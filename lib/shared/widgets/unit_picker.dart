import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';

enum _UnitChipSize { short, medium, long }

_UnitChipSize _chipSize(String unit) {
  if (unit.length <= 2) return _UnitChipSize.short;
  if (unit.length <= 4) return _UnitChipSize.medium;
  return _UnitChipSize.long;
}

class UnitPicker extends StatefulWidget {
  final String? selectedUnit;
  final void Function(String unit) onChanged;
  final bool allowCustom;

  const UnitPicker({
    super.key,
    required this.onChanged,
    this.selectedUnit,
    this.allowCustom = true,
  });

  @override
  State<UnitPicker> createState() => _UnitPickerState();
}

class _UnitPickerState extends State<UnitPicker> {
  static const _weightUnits = ['g', 'kg', 'oz', 'lb'];
  static const _volumeUnits = ['ml', 'l', 'tsp', 'tbsp', 'cup', 'fl oz'];
  static const _countUnits = [
    'pcs',
    'cloves',
    'slices',
    'bags',
    'cans',
    'bottles',
    'bunches',
    'heads',
  ];

  static List<String> get _allStandardUnits => [
    ..._weightUnits,
    ..._volumeUnits,
    ..._countUnits,
  ];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _customCtrl = TextEditingController();
  final Map<String, GlobalKey> _chipKeys = {};
  bool _showCustomField = false;

  bool get _isCustomActive {
    final sel = widget.selectedUnit;
    return sel != null && !_allStandardUnits.contains(sel);
  }

  @override
  void initState() {
    super.initState();
    for (final u in _allStandardUnits) {
      _chipKeys[u] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    final selected = widget.selectedUnit;
    if (selected == null) return;
    final key = _chipKeys[selected];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 200),
      alignment: 0.5,
    );
  }

  void _selectUnit(String unit) {
    setState(() {
      _showCustomField = false;
      _customCtrl.clear();
    });
    widget.onChanged(unit);
  }

  void _confirmCustom() {
    final val = _customCtrl.text.trim();
    if (val.isEmpty) return;
    setState(() => _showCustomField = false);
    widget.onChanged(val);
  }

  Widget _buildChip(
    String label,
    bool isSelected,
    AppColors colors, {
    GlobalKey? chipKey,
    bool forceCustom = false,
  }) {
    final size = forceCustom ? _UnitChipSize.long : _chipSize(label);
    final isShort = size == _UnitChipSize.short;
    final fontSize = size == _UnitChipSize.long ? 11.0 : 12.0;
    final hPadding = size == _UnitChipSize.long ? 20.0 : 16.0;

    return AnimatedContainer(
      key: chipKey,
      duration: const Duration(milliseconds: 150),
      height: 32,
      width: isShort ? 40 : null,
      padding: isShort
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: hPadding),
      decoration: BoxDecoration(
        color: isSelected ? colors.greenDim : colors.surface3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? colors.green.withValues(alpha: 0.4)
              : colors.border,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: isSelected ? colors.green : colors.textSecondary,
        ),
      ),
    );
  }

  Widget _divider(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(width: 1, height: 20, color: colors.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ..._weightUnits.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _selectUnit(u),
                    child: _buildChip(
                      u,
                      widget.selectedUnit == u,
                      colors,
                      chipKey: _chipKeys[u],
                    ),
                  ),
                ),
              ),
              _divider(colors),
              ..._volumeUnits.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _selectUnit(u),
                    child: _buildChip(
                      u,
                      widget.selectedUnit == u,
                      colors,
                      chipKey: _chipKeys[u],
                    ),
                  ),
                ),
              ),
              _divider(colors),
              ..._countUnits.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _selectUnit(u),
                    child: _buildChip(
                      u,
                      widget.selectedUnit == u,
                      colors,
                      chipKey: _chipKeys[u],
                    ),
                  ),
                ),
              ),
              if (widget.allowCustom)
                GestureDetector(
                  onTap: () =>
                      setState(() => _showCustomField = !_showCustomField),
                  child: _buildChip(
                    _isCustomActive ? '${widget.selectedUnit} ✓' : 'Custom…',
                    _isCustomActive,
                    colors,
                    forceCustom: true,
                  ),
                ),
            ],
          ),
        ),
        if (_showCustomField) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCtrl,
                  autofocus: true,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Enter unit (e.g. sprigs, sheets…)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _confirmCustom(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _confirmCustom,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.greenDim,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.greenBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '✓',
                    style: TextStyle(color: colors.green, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
