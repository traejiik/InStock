import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/features/recipes/providers/recipe_import_provider.dart';
import 'package:instock/features/recipes/services/recipe_scraper.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/shared/widgets/segment_control.dart';
import 'package:instock/shared/widgets/toggle_row.dart';
import 'package:instock/shared/widgets/unit_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─── Tab index constants ──────────────────────────────────────────────────────

const _kTabWrite = 0;
const _kTabImport = 1;

const _kTabLabels = ['✍️ Write', '🔗 Import', '✨ AI'];

class AddRecipeScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const AddRecipeScreen({super.key, this.initialTab = _kTabImport});

  @override
  ConsumerState<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends ConsumerState<AddRecipeScreen> {
  late int _tabIndex;
  final _urlCtrl = TextEditingController();
  bool _aiReview = false;
  bool _convertMetric = false;
  String? _writePrefilledTitle;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipeImportProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _switchToWrite(String? prefillTitle) {
    setState(() {
      _tabIndex = _kTabWrite;
      _writePrefilledTitle = prefillTitle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textSecondary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Add Recipe', style: AppTextStyles.headingMd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentControl(
              labels: _kTabLabels,
              selectedIndex: _tabIndex,
              onChanged: (i) => setState(() {
                _tabIndex = i;
                if (i != _kTabImport) {
                  ref.read(recipeImportProvider.notifier).reset();
                }
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: [
                _WriteTabContent(
                  prefilledTitle: _writePrefilledTitle,
                ),
                _ImportTabContent(
                  urlCtrl: _urlCtrl,
                  aiReview: _aiReview,
                  convertMetric: _convertMetric,
                  onAiToggle: (v) => setState(() => _aiReview = v),
                  onMetricToggle: (v) => setState(() => _convertMetric = v),
                  onSwitchToWrite: _switchToWrite,
                ),
                const _AiTabContent(),
              ][_tabIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Write Tab ────────────────────────────────────────────────────────────────

class _WriteTabContent extends ConsumerStatefulWidget {
  final String? prefilledTitle;

  const _WriteTabContent({this.prefilledTitle});

  @override
  ConsumerState<_WriteTabContent> createState() => _WriteTabContentState();
}

class _WriteTabContentState extends ConsumerState<_WriteTabContent> {
  late final TextEditingController _titleCtrl;
  final _servingsCtrl = TextEditingController(text: '2');
  final _timeCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final List<TextEditingController> _ingNameCtrl = [TextEditingController()];
  final List<TextEditingController> _ingQtyCtrl = [TextEditingController(text: '1')];
  final List<String?> _ingUnits = [null];
  final List<TextEditingController> _stepCtrl = [TextEditingController()];

  String? _titleError;
  String? _servingsError;
  String? _ingredientsError;
  String? _stepsError;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.prefilledTitle ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _servingsCtrl.dispose();
    _timeCtrl.dispose();
    _sourceCtrl.dispose();
    for (final c in _ingNameCtrl) {
      c.dispose();
    }
    for (final c in _ingQtyCtrl) {
      c.dispose();
    }
    for (final c in _stepCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    final title = _titleCtrl.text.trim();
    final servings = int.tryParse(_servingsCtrl.text);
    final hasIng = _ingNameCtrl.any((c) => c.text.trim().isNotEmpty);
    final hasStep = _stepCtrl.any((c) => c.text.trim().isNotEmpty);

    setState(() {
      _titleError = title.length < 2 ? 'Required' : null;
      _servingsError = (servings == null || servings <= 0) ? 'Must be > 0' : null;
      _ingredientsError = !hasIng ? 'Add at least one ingredient' : null;
      _stepsError = !hasStep ? 'Add at least one step' : null;
    });

    return title.length >= 2 &&
        servings != null &&
        servings > 0 &&
        hasIng &&
        hasStep;
  }

  void _save() {
    if (!_validate()) return;

    final db = ref.read(appDatabaseProvider);
    final ingredients = <({String name, double quantity, String unit, bool isOptional})>[];

    for (var i = 0; i < _ingNameCtrl.length; i++) {
      final name = _ingNameCtrl[i].text.trim();
      if (name.isEmpty) continue;
      final qty = double.tryParse(_ingQtyCtrl[i].text) ?? 1;
      ingredients.add((
        name: name,
        quantity: qty,
        unit: _ingUnits[i] ?? 'pcs',
        isOptional: false,
      ));
    }

    final steps = _stepCtrl
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    db.saveRecipe(
      title: _titleCtrl.text.trim(),
      servings: int.tryParse(_servingsCtrl.text) ?? 2,
      cookMinutes: int.tryParse(_timeCtrl.text) ?? 0,
      difficulty: 'Medium',
      instructions: steps,
      ingredients: ingredients,
      sourceUrl: _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim(),
    );

    context.go('/recipes');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputField(_titleCtrl, 'Recipe Name', errorText: _titleError),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _InputField(_servingsCtrl, 'Servings',
              type: TextInputType.number, errorText: _servingsError)),
          const SizedBox(width: 10),
          Expanded(child: _InputField(_timeCtrl, 'Cook time (min)',
              type: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        _InputField(_sourceCtrl, 'Source URL (optional)',
            type: TextInputType.url),
        const SizedBox(height: 20),
        _SectionHeader(
          label: 'Ingredients',
          error: _ingredientsError,
        ),
        const SizedBox(height: 8),
        ..._ingNameCtrl.asMap().entries.map((e) {
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: _InputField(_ingNameCtrl[i], 'Ingredient ${i + 1}'),
                  ),
                  const SizedBox(width: 8),
                  _InputField(_ingQtyCtrl[i], 'Qty',
                      type: const TextInputType.numberWithOptions(decimal: true),
                      width: 64),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_ingNameCtrl.length > 1) {
                        _ingNameCtrl[i].dispose();
                        _ingQtyCtrl[i].dispose();
                        _ingNameCtrl.removeAt(i);
                        _ingQtyCtrl.removeAt(i);
                        _ingUnits.removeAt(i);
                      }
                    }),
                    child: const Icon(LucideIcons.minusCircle,
                        color: AppColors.textTertiary, size: 20),
                  ),
                ]),
                const SizedBox(height: 6),
                UnitPicker(
                  selectedUnit: _ingUnits[i],
                  onChanged: (u) => setState(() => _ingUnits[i] = u),
                  allowCustom: true,
                ),
              ],
            ),
          );
        }),
        _AddRow(
          label: '+ Add Ingredient',
          onTap: () => setState(() {
            _ingNameCtrl.add(TextEditingController());
            _ingQtyCtrl.add(TextEditingController(text: '1'));
            _ingUnits.add(null);
          }),
        ),
        const SizedBox(height: 20),
        _SectionHeader(label: 'Instructions', error: _stepsError),
        const SizedBox(height: 8),
        ..._stepCtrl.asMap().entries.map((e) {
          final i = e.key;
          return Padding(
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
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _stepCtrl[i],
                    maxLines: 3,
                    minLines: 2,
                    style: AppTextStyles.bodyMd,
                    decoration: InputDecoration(
                      hintText: 'Step ${i + 1}…',
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    if (_stepCtrl.length > 1) {
                      _stepCtrl[i].dispose();
                      _stepCtrl.removeAt(i);
                    }
                  }),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(LucideIcons.minusCircle,
                        color: AppColors.textTertiary, size: 20),
                  ),
                ),
              ],
            ),
          );
        }),
        _AddRow(
          label: '+ Add Step',
          onTap: () => setState(() => _stepCtrl.add(TextEditingController())),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(label: 'Save Recipe', onTap: _save),
      ],
    );
  }
}

// ─── Import Tab ───────────────────────────────────────────────────────────────

class _ImportTabContent extends ConsumerWidget {
  final TextEditingController urlCtrl;
  final bool aiReview;
  final bool convertMetric;
  final ValueChanged<bool> onAiToggle;
  final ValueChanged<bool> onMetricToggle;
  final void Function(String? pageTitle) onSwitchToWrite;

  const _ImportTabContent({
    required this.urlCtrl,
    required this.aiReview,
    required this.convertMetric,
    required this.onAiToggle,
    required this.onMetricToggle,
    required this.onSwitchToWrite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(recipeImportProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(children: [
            const Icon(LucideIcons.link, color: AppColors.textTertiary, size: 28),
            const SizedBox(height: 10),
            Text('Paste a recipe URL',
                style: AppTextStyles.headingSm),
            const SizedBox(height: 6),
            Text(
              'Works with most food blogs and sites',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: urlCtrl,
          enabled: !importState.isLoading,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://…',
            prefixIcon: Icon(LucideIcons.link, color: AppColors.textTertiary, size: 18),
          ),
        ),
        const SizedBox(height: 14),
        if (importState.isLoading)
          const _LoadingState()
        else
          _PrimaryButton(
            label: 'Import Recipe',
            onTap: urlCtrl.text.trim().isEmpty
                ? null
                : () => ref
                    .read(recipeImportProvider.notifier)
                    .scrape(urlCtrl.text.trim()),
          ),
        if (importState.hasError) ...[
          const SizedBox(height: 12),
          _ErrorBanner(
            onEditManually: () {
              final e = importState.error;
              final title = e is RecipeParseException ? e.pageTitle : null;
              onSwitchToWrite(title);
            },
          ),
        ],
        if (importState.hasValue && importState.value != null) ...[
          const SizedBox(height: 20),
          _PreviewSection(
            parsed: importState.value!,
            aiReview: aiReview,
            convertMetric: convertMetric,
            onAiToggle: onAiToggle,
            onMetricToggle: onMetricToggle,
          ),
        ],
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 24),
      const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppColors.green),
        strokeWidth: 2,
      ),
      const SizedBox(height: 12),
      Text(
        'Fetching recipe…',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  final VoidCallback onEditManually;

  const _ErrorBanner({required this.onEditManually});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.amberDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.2),
        ),
      ),
      child: Row(children: [
        const Icon(LucideIcons.alertTriangle, color: AppColors.amber, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Couldn't parse this URL automatically.",
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
          ),
        ),
        GestureDetector(
          onTap: onEditManually,
          child: Text(
            'Edit Manually →',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }
}

class _PreviewSection extends ConsumerWidget {
  final ParsedRecipe parsed;
  final bool aiReview;
  final bool convertMetric;
  final ValueChanged<bool> onAiToggle;
  final ValueChanged<bool> onMetricToggle;

  const _PreviewSection({
    required this.parsed,
    required this.aiReview,
    required this.convertMetric,
    required this.onAiToggle,
    required this.onMetricToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Preview', style: AppTextStyles.headingSm),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.greenDim,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.greenBorder),
            ),
            child: Text(
              '✓ Parsed',
              style: AppTextStyles.caption.copyWith(color: AppColors.green),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _RecipePreviewCard(parsed: parsed),
        const SizedBox(height: 16),
        ToggleRow(
          icon: Icons.auto_awesome,
          iconColor: AppColors.purple,
          iconBg: AppColors.purpleDim,
          title: 'AI Review ☁️',
          subtitle: 'Let AI check for improvements',
          value: aiReview,
          onChanged: (v) {
            if (v) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('AI Review coming soon',
                      style: AppTextStyles.bodySm),
                  backgroundColor: AppColors.purpleDim,
                ),
              );
            } else {
              onAiToggle(false);
            }
          },
        ),
        const SizedBox(height: 10),
        ToggleRow(
          icon: Icons.straighten,
          iconColor: AppColors.blue,
          iconBg: AppColors.blueDim,
          title: 'Convert to Metric',
          subtitle: 'cups/oz/tbsp → ml/g',
          value: convertMetric,
          onChanged: onMetricToggle,
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Save to Recipes',
          onTap: () {
            final effective = convertMetric
                ? parsed.copyWith(
                    ingredients: RecipeScraper.applyMetricConversion(
                      parsed.ingredients,
                    ),
                  )
                : parsed;
            context.push('/recipes/review', extra: effective);
          },
        ),
      ],
    );
  }
}

class _RecipePreviewCard extends StatelessWidget {
  final ParsedRecipe parsed;

  const _RecipePreviewCard({required this.parsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: parsed.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: parsed.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _ImageFallback(),
                    placeholder: (_, __) => Container(
                      color: AppColors.surface3,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.textTertiary),
                      ),
                    ),
                  )
                : const _ImageFallback(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsed.title,
                  style: AppTextStyles.headingSm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  if (parsed.cookTimeMinutes != null) ...[
                    const Icon(LucideIcons.clock,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${parsed.cookTimeMinutes} min',
                        style: AppTextStyles.caption),
                    const SizedBox(width: 12),
                  ],
                  const Icon(LucideIcons.users,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${parsed.baseServings} servings',
                      style: AppTextStyles.caption),
                  const SizedBox(width: 12),
                  Text('${parsed.ingredients.length} ingredients',
                      style: AppTextStyles.caption),
                ]),
              ],
            ),
          ),
        ],
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

// ─── AI Tab ───────────────────────────────────────────────────────────────────

class _AiTabContent extends StatelessWidget {
  const _AiTabContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        const Text('✨', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 16),
        Text('AI Generate', style: AppTextStyles.headingLg),
        const SizedBox(height: 8),
        Text(
          'Coming in a future update',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.purpleDim,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '☁️  Requires internet + active plan',
            style: AppTextStyles.caption.copyWith(color: AppColors.purple),
          ),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? error;

  const _SectionHeader({required this.label, this.error});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: AppTextStyles.headingSm),
      if (error != null) ...[
        const SizedBox(width: 10),
        Text(error!,
            style: AppTextStyles.caption.copyWith(color: AppColors.red)),
      ],
    ]);
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

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType? type;
  final String? errorText;
  final double? width;

  const _InputField(
    this.ctrl,
    this.hint, {
    this.type,
    this.errorText,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: ctrl,
      keyboardType: type,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        labelText: hint,
        errorText: errorText,
        isDense: true,
      ),
    );
    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            color:
                onTap == null ? AppColors.textTertiary : AppColors.background,
          ),
        ),
      ),
    );
  }
}
