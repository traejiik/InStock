import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/shared/widgets/segment_control.dart';
import 'package:instock/shared/widgets/toggle_row.dart';

class ImportRecipeScreen extends StatefulWidget {
  const ImportRecipeScreen({super.key});

  @override
  State<ImportRecipeScreen> createState() => _ImportRecipeScreenState();
}

class _ImportRecipeScreenState extends State<ImportRecipeScreen> {
  int _tabIndex = 1; // default: Import
  bool _aiReview = false;
  bool _convertMetric = true;
  bool _useWithPantry = false;
  bool _importing = false;
  bool _importDone = false;
  final _urlCtrl = TextEditingController();
  final _aiDescCtrl = TextEditingController();

  @override
  void dispose() {
    _urlCtrl.dispose();
    _aiDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Recipe', style: AppTextStyles.headingMd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentControl(
              labels: const ['Write', 'Import', 'AI'],
              selectedIndex: _tabIndex,
              onChanged: (i) => setState(() {
                _tabIndex = i;
                _importDone = false;
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: [
                _WriteTab(aiReview: _aiReview, onAiToggle: (v) => setState(() => _aiReview = v)),
                _ImportTab(
                  urlCtrl: _urlCtrl,
                  aiReview: _aiReview,
                  convertMetric: _convertMetric,
                  importing: _importing,
                  importDone: _importDone,
                  onAiToggle: (v) => setState(() => _aiReview = v),
                  onMetricToggle: (v) => setState(() => _convertMetric = v),
                  onImport: () async {
                    if (_urlCtrl.text.isEmpty) return;
                    setState(() => _importing = true);
                    await Future.delayed(const Duration(seconds: 2));
                    setState(() { _importing = false; _importDone = true; });
                  },
                  onSave: () => Navigator.pop(context),
                ),
                _AiTab(
                  descCtrl: _aiDescCtrl,
                  useWithPantry: _useWithPantry,
                  onPantryToggle: (v) => setState(() => _useWithPantry = v),
                  onGenerate: () async {
                    setState(() => _importing = true);
                    final messenger = ScaffoldMessenger.of(context);
                    await Future.delayed(const Duration(seconds: 2));
                    if (!mounted) return;
                    setState(() => _importing = false);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('☁️ AI generation requires an active plan',
                            style: AppTextStyles.bodySm),
                        backgroundColor: AppColors.purpleDim,
                      ),
                    );
                  },
                ),
              ][_tabIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Write Tab ───────────────────────────────────────────────────────────────

class _WriteTab extends StatefulWidget {
  final bool aiReview;
  final ValueChanged<bool> onAiToggle;

  const _WriteTab({required this.aiReview, required this.onAiToggle});

  @override
  State<_WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends State<_WriteTab> {
  final _titleCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController(text: '4');
  final _timeCtrl = TextEditingController(text: '30');
  final List<TextEditingController> _ingCtrl = [TextEditingController()];
  final List<TextEditingController> _stepCtrl = [TextEditingController()];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _servingsCtrl.dispose();
    _timeCtrl.dispose();
    for (final c in _ingCtrl) {
      c.dispose();
    }
    for (final c in _stepCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(_titleCtrl, 'Title'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _field(_servingsCtrl, 'Servings', type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(_timeCtrl, 'Time (min)', type: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 20),
        Text('Ingredients', style: AppTextStyles.headingSm),
        const SizedBox(height: 8),
        ..._ingCtrl.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: _field(e.value, 'Ingredient ${e.key + 1}')),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() { if (_ingCtrl.length > 1) _ingCtrl.removeAt(e.key); }),
                child: const Icon(Icons.remove_circle_outline, color: AppColors.textTertiary, size: 20),
              ),
            ],
          ),
        )),
        _AddRow(label: '+ Ingredient', onTap: () => setState(() => _ingCtrl.add(TextEditingController()))),
        const SizedBox(height: 20),
        Text('Steps', style: AppTextStyles.headingSm),
        const SizedBox(height: 8),
        ..._stepCtrl.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(top: 14, right: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(child: Text('${e.key + 1}', style: AppTextStyles.caption.copyWith(fontSize: 10))),
              ),
              Expanded(child: _field(e.value, 'Step ${e.key + 1}', maxLines: 3)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() { if (_stepCtrl.length > 1) _stepCtrl.removeAt(e.key); }),
                child: const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Icon(Icons.remove_circle_outline, color: AppColors.textTertiary, size: 20),
                ),
              ),
            ],
          ),
        )),
        _AddRow(label: '+ Step', onTap: () => setState(() => _stepCtrl.add(TextEditingController()))),
        const SizedBox(height: 20),
        ToggleRow(
          icon: Icons.auto_awesome,
          iconColor: AppColors.purple,
          iconBg: AppColors.purpleDim,
          title: 'AI Review ☁️',
          subtitle: 'Let AI check for improvements',
          value: widget.aiReview,
          onChanged: widget.onAiToggle,
        ),
        const SizedBox(height: 16),
        _PrimaryButton(label: 'Save Recipe', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

// ─── Import Tab ───────────────────────────────────────────────────────────────

class _ImportTab extends StatelessWidget {
  final TextEditingController urlCtrl;
  final bool aiReview;
  final bool convertMetric;
  final bool importing;
  final bool importDone;
  final ValueChanged<bool> onAiToggle;
  final ValueChanged<bool> onMetricToggle;
  final VoidCallback onImport;
  final VoidCallback onSave;

  const _ImportTab({
    required this.urlCtrl,
    required this.aiReview,
    required this.convertMetric,
    required this.importing,
    required this.importDone,
    required this.onAiToggle,
    required this.onMetricToggle,
    required this.onImport,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 1.5),
            color: AppColors.surface,
          ),
          child: Column(
            children: [
              const Icon(Icons.link, color: AppColors.textTertiary, size: 36),
              const SizedBox(height: 10),
              Text('Paste a recipe URL', style: AppTextStyles.headingSm),
              const SizedBox(height: 6),
              Text(
                'Supports most cooking websites and blogs',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: urlCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Recipe URL',
            prefixIcon: Icon(Icons.link, color: AppColors.textTertiary, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: importing ? 'Importing…' : 'Import Recipe',
          onTap: importing ? null : onImport,
        ),
        if (importDone) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greenDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greenBorder),
            ),
            child: Row(
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recipe imported!', style: AppTextStyles.label.copyWith(color: AppColors.green)),
                      Text('Review and save below', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ToggleRow(
            icon: Icons.auto_awesome,
            iconColor: AppColors.purple,
            iconBg: AppColors.purpleDim,
            title: 'AI Review ☁️',
            subtitle: 'AI quality check on the imported recipe',
            value: aiReview,
            onChanged: onAiToggle,
          ),
          const SizedBox(height: 10),
          ToggleRow(
            icon: Icons.straighten,
            iconColor: AppColors.blue,
            iconBg: AppColors.blueDim,
            title: 'Convert to Metric',
            subtitle: 'cups/oz → ml/g',
            value: convertMetric,
            onChanged: onMetricToggle,
          ),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Save to Recipes', onTap: onSave),
        ],
      ],
    );
  }
}

// ─── AI Tab ───────────────────────────────────────────────────────────────────

class _AiTab extends StatelessWidget {
  final TextEditingController descCtrl;
  final bool useWithPantry;
  final ValueChanged<bool> onPantryToggle;
  final VoidCallback onGenerate;

  const _AiTab({
    required this.descCtrl,
    required this.useWithPantry,
    required this.onPantryToggle,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Describe what you want to cook…', style: AppTextStyles.headingSm),
        const SizedBox(height: 10),
        TextField(
          controller: descCtrl,
          maxLines: 5,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. A quick weeknight pasta, creamy but not too heavy...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        ToggleRow(
          icon: Icons.home_outlined,
          iconColor: AppColors.green,
          iconBg: AppColors.greenDim,
          title: "What's in my pantry",
          subtitle: 'AI uses your current pantry items as context',
          value: useWithPantry,
          onChanged: onPantryToggle,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onGenerate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.purpleDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.purpleBorder),
            ),
            child: Text(
              'Generate Recipe ✨ ☁️',
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(color: AppColors.purple),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.purpleDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI features require internet connection and an active plan',
                  style: AppTextStyles.caption.copyWith(color: AppColors.purple),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _field(TextEditingController ctrl, String label,
    {TextInputType? type, int? maxLines}) {
  return TextField(
    controller: ctrl,
    keyboardType: type,
    maxLines: maxLines ?? 1,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(labelText: label),
  );
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
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.green, size: 18),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.green)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.surface3 : AppColors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            color: onTap == null ? AppColors.textTertiary : AppColors.background,
          ),
        ),
      ),
    );
  }
}
