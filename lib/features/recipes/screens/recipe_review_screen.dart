import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/features/recipes/providers/recipe_form_provider.dart';
import 'package:instock/features/recipes/services/recipe_scraper.dart';
import 'package:instock/shared/widgets/toggle_row.dart';
import 'package:instock/shared/widgets/unit_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RecipeReviewScreen extends ConsumerStatefulWidget {
  final ParsedRecipe parsed;

  const RecipeReviewScreen({super.key, required this.parsed});

  @override
  ConsumerState<RecipeReviewScreen> createState() => _RecipeReviewScreenState();
}

class _RecipeReviewScreenState extends ConsumerState<RecipeReviewScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _cookTimeCtrl;

  // Used to force IngredientEditRow reinit when metric conversion changes
  int _metricRevision = 0;
  List<IngredientFormRow>? _preMetricIngredients;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.parsed.title);
    _cookTimeCtrl = TextEditingController(
      text: widget.parsed.cookTimeMinutes?.toString() ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipeFormProvider.notifier).loadFromParsed(widget.parsed);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cookTimeCtrl.dispose();
    super.dispose();
  }

  void _onMetricToggle(bool on) {
    final notifier = ref.read(recipeFormProvider.notifier);
    if (on) {
      _preMetricIngredients =
          List<IngredientFormRow>.from(ref.read(recipeFormProvider).ingredients);
      notifier.applyMetricConversion();
    } else {
      if (_preMetricIngredients != null) {
        notifier.undoMetricConversion(_preMetricIngredients!);
        _preMetricIngredients = null;
      }
    }
    setState(() => _metricRevision++);
  }

  void _save() {
    final state = ref.read(recipeFormProvider);
    final title = _titleCtrl.text.trim();

    if (title.isEmpty ||
        state.ingredients.where((i) => i.name.isNotEmpty).isEmpty ||
        state.steps.where((s) => s.isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add a title, at least one ingredient, and one step.',
            style: AppTextStyles.bodySm,
          ),
          backgroundColor: AppColors.surface2,
        ),
      );
      return;
    }

    ref.read(recipeFormProvider.notifier).updateTitle(title);
    final cookMins = int.tryParse(_cookTimeCtrl.text);
    ref.read(recipeFormProvider.notifier).updateCookTime(cookMins);
    ref.read(recipeFormProvider.notifier).save();
    context.go('/recipes');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.textSecondary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Review Recipe', style: AppTextStyles.headingMd),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: AppTextStyles.label.copyWith(color: AppColors.green),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            SizedBox(
              height: 160,
              width: double.infinity,
              child: state.imageUrl != null
                  ? Image.network(
                      state.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const _ImageFallback(),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : const _ImageFallback(),
                    )
                  : const _ImageFallback(),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Editable title
                  TextField(
                    controller: _titleCtrl,
                    style: AppTextStyles.headingLg,
                    decoration: InputDecoration(
                      hintText: 'Recipe title',
                      hintStyle: AppTextStyles.headingLg.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.border),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meta row
                  Row(children: [
                    _MetaChip(
                      icon: LucideIcons.clock,
                      label: state.cookTimeMinutes != null
                          ? '${state.cookTimeMinutes} min'
                          : '⏱ — min',
                      onTap: () => _showCookTimePicker(context),
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: LucideIcons.users,
                      label: '${state.baseServings} servings',
                      onTap: () => _showServingsPicker(context, state.baseServings),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Servings stepper
                  _ServingsStepper(
                    count: state.baseServings,
                    onDecrement: () => ref
                        .read(recipeFormProvider.notifier)
                        .updateServings(state.baseServings - 1),
                    onIncrement: () => ref
                        .read(recipeFormProvider.notifier)
                        .updateServings(state.baseServings + 1),
                  ),
                  const SizedBox(height: 16),

                  // Metric toggle
                  ToggleRow(
                    icon: Icons.straighten,
                    iconColor: AppColors.blue,
                    iconBg: AppColors.blueDim,
                    title: 'Convert to Metric',
                    subtitle: 'cups/oz/tbsp → ml/g',
                    value: state.convertedToMetric,
                    onChanged: _onMetricToggle,
                  ),
                  const SizedBox(height: 24),

                  // Ingredients section
                  Row(children: [
                    Text('Ingredients', style: AppTextStyles.headingSm),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface3,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${state.ingredients.length}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  ..._buildIngredientRows(state),

                  _AddRow(
                    label: '+ Add Ingredient',
                    onTap: () =>
                        ref.read(recipeFormProvider.notifier).addIngredient(),
                  ),
                  const SizedBox(height: 24),

                  // Instructions section
                  Text('Instructions', style: AppTextStyles.headingSm),
                  const SizedBox(height: 8),

                  ..._buildStepRows(state),

                  _AddRow(
                    label: '+ Add Step',
                    onTap: () => ref.read(recipeFormProvider.notifier).addStep(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIngredientRows(RecipeFormState state) {
    return state.ingredients.asMap().entries.map((entry) {
      final i = entry.key;
      final row = entry.value;

      return Dismissible(
        key: ValueKey('ing-$i-rev$_metricRevision'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: AppColors.redDim,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(LucideIcons.trash2, color: AppColors.red, size: 18),
        ),
        onDismissed: (_) =>
            ref.read(recipeFormProvider.notifier).removeIngredient(i),
        child: Padding(
          key: ValueKey('ing-padding-$i-rev$_metricRevision'),
          padding: const EdgeInsets.only(bottom: 10),
          child: _IngredientRow(
            key: ValueKey('ing-row-$i-rev$_metricRevision'),
            initialName: row.name,
            initialQuantity: row.quantity,
            initialUnit: row.unit,
            onChanged: (name, qty, unit) {
              ref.read(recipeFormProvider.notifier).updateIngredient(
                    i,
                    row.copyWith(name: name, quantity: qty, unit: unit),
                  );
            },
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildStepRows(RecipeFormState state) {
    return state.steps.asMap().entries.map((entry) {
      final i = entry.key;
      final step = entry.value;

      return Dismissible(
        key: ValueKey('step-$i'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: AppColors.redDim,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(LucideIcons.trash2, color: AppColors.red, size: 18),
        ),
        onDismissed: (_) =>
            ref.read(recipeFormProvider.notifier).removeStep(i),
        child: Padding(
          key: ValueKey('step-padding-$i'),
          padding: const EdgeInsets.only(bottom: 10),
          child: _StepRow(
            key: ValueKey('step-row-$i'),
            stepNumber: i + 1,
            initialText: step,
            onChanged: (text) =>
                ref.read(recipeFormProvider.notifier).updateStep(i, text),
          ),
        ),
      );
    }).toList();
  }

  void _showCookTimePicker(BuildContext context) {
    final ctrl = TextEditingController(
      text: ref.read(recipeFormProvider).cookTimeMinutes?.toString() ?? '',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Cook time (minutes)', style: AppTextStyles.headingSm),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyMd,
              decoration: const InputDecoration(
                hintText: 'e.g. 30',
                suffixText: 'min',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.background,
                ),
                onPressed: () {
                  ref.read(recipeFormProvider.notifier).updateCookTime(
                        int.tryParse(ctrl.text),
                      );
                  _cookTimeCtrl.text = ctrl.text;
                  Navigator.pop(ctx);
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServingsPicker(BuildContext context, int current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          int value = current;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Base servings', style: AppTextStyles.headingSm),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _StepperButton(
                    icon: LucideIcons.minus,
                    onTap: () {
                      if (value > 1) setModalState(() => value--);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text('$value',
                        style: AppTextStyles.headingLg),
                  ),
                  _StepperButton(
                    icon: LucideIcons.plus,
                    onTap: () => setModalState(() => value++),
                  ),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.background,
                    ),
                    onPressed: () {
                      ref.read(recipeFormProvider.notifier).updateServings(value);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Inline widgets ───────────────────────────────────────────────────────────

class _IngredientRow extends StatefulWidget {
  final String initialName;
  final double initialQuantity;
  final String? initialUnit;
  final void Function(String name, double qty, String? unit) onChanged;

  const _IngredientRow({
    super.key,
    required this.initialName,
    required this.initialQuantity,
    this.initialUnit,
    required this.onChanged,
  });

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late String? _unit;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _qtyCtrl = TextEditingController(
      text: _fmt(widget.initialQuantity),
    );
    _unit = widget.initialUnit;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _fmt(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(1);
  }

  void _notify() {
    widget.onChanged(
      _nameCtrl.text,
      double.tryParse(_qtyCtrl.text) ?? 1,
      _unit,
    );
  }

  void _pickUnit() {
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
                width: 36, height: 4,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        SizedBox(
          width: 52,
          child: TextField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.bodyMd,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _notify(),
          ),
        ),
        GestureDetector(
          onTap: _pickUnit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(6),
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
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _notify(),
          ),
        ),
      ]),
    );
  }
}

class _StepRow extends StatefulWidget {
  final int stepNumber;
  final String initialText;
  final void Function(String text) onChanged;

  const _StepRow({
    super.key,
    required this.stepNumber,
    required this.initialText,
    required this.onChanged,
  });

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22, height: 22,
          margin: const EdgeInsets.only(top: 10, right: 10),
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
              hintText: 'Step description…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption),
        ]),
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  final int count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _ServingsStepper({
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Text('Base servings',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        _StepperButton(icon: LucideIcons.minus, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$count', style: AppTextStyles.headingSm),
        ),
        _StepperButton(icon: LucideIcons.plus, onTap: onIncrement),
      ]),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          const Icon(LucideIcons.plusCircle, color: AppColors.green, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.green)),
        ]),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface3,
      alignment: Alignment.center,
      child: const Text('🍽', style: TextStyle(fontSize: 48)),
    );
  }
}
