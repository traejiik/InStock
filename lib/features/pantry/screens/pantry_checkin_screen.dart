import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';

class PantryCheckinScreen extends ConsumerStatefulWidget {
  const PantryCheckinScreen({super.key});

  @override
  ConsumerState<PantryCheckinScreen> createState() => _PantryCheckinScreenState();
}

class _PantryCheckinScreenState extends ConsumerState<PantryCheckinScreen>
    with SingleTickerProviderStateMixin {
  List<PantryItem> _items = [];
  List<Ingredient> _ingredients = [];
  int _currentIndex = 0;
  bool _showUpdate = false;
  bool _isDone = false;
  final _qtyCtrl = TextEditingController();
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = ref.read(appDatabaseProvider);
      setState(() {
        _items = db.unverifiedItems;
        _ingredients = _items
            .map((p) => db.ingredientById(p.ingredientId))
            .whereType<Ingredient>()
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Ingredient? get _currentIng =>
      _currentIndex < _ingredients.length ? _ingredients[_currentIndex] : null;

  PantryItem? get _currentItem =>
      _currentIndex < _items.length ? _items[_currentIndex] : null;

  void _advance() {
    if (_currentIndex + 1 >= _items.length) {
      setState(() => _isDone = true);
    } else {
      setState(() {
        _currentIndex++;
        _showUpdate = false;
        _slideCtrl.reset();
      });
    }
  }

  void _stillGood() {
    final item = _currentItem;
    if (item == null) return;
    ref.read(appDatabaseProvider).markPantryItemVerified(item.id);
    _advance();
  }

  void _saveUpdate() {
    final item = _currentItem;
    if (item == null) return;
    final qty = double.tryParse(_qtyCtrl.text) ?? item.quantity;
    ref.read(appDatabaseProvider).updatePantryQuantity(item.id, qty);
    _advance();
  }

  void _markOut() {
    final item = _currentItem;
    if (item == null) return;
    ref.read(appDatabaseProvider).markPantryItemOut(item.id);
    _advance();
  }

  void _showUpdatePanel() {
    setState(() {
      _showUpdate = true;
      _qtyCtrl.text = _currentItem?.quantity.toString() ?? '';
    });
    _slideCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return _EmptyState(onClose: () => Navigator.pop(context));
    }

    if (_isDone) {
      return _DoneState(onClose: () => Navigator.pop(context));
    }

    final item = _currentItem;
    final ing = _currentIng;
    if (item == null || ing == null) {
      return const SizedBox.shrink();
    }

    final daysAgo = item.lastVerifiedAt != null
        ? DateTime.now().difference(item.lastVerifiedAt!).inDays
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Check-in', style: AppTextStyles.headingMd),
            Text('${_items.length} items to review',
                style: AppTextStyles.caption),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _ProgressBar(total: _items.length, current: _currentIndex),
              const SizedBox(height: 28),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Text(ing.category.emoji,
                              style: const TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          Text(ing.canonicalName, style: AppTextStyles.headingLg, textAlign: TextAlign.center),
                          const SizedBox(height: 6),
                          if (daysAgo != null)
                            Text(
                              'Last verified: ${daysAgo == 0 ? 'today' : '$daysAgo days ago'}',
                              style: AppTextStyles.caption,
                            ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Recorded: ${item.quantity} ${item.unit}',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_showUpdate) ...[
                            Text('Still accurate?', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    label: '✓ Still good',
                                    color: AppColors.green,
                                    bg: AppColors.greenDim,
                                    onTap: _stillGood,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionButton(
                                    label: '✎ Update',
                                    color: AppColors.textPrimary,
                                    bg: AppColors.surface3,
                                    onTap: _showUpdatePanel,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('Swipe left to skip',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                          ],
                          if (_showUpdate) ...[
                            SlideTransition(
                              position: _slideAnim,
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _qtyCtrl,
                                    keyboardType: TextInputType.number,
                                    autofocus: true,
                                    style: const TextStyle(color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      labelText: 'New quantity (${item.unit})',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _ActionButton(
                                          label: 'Save & Next →',
                                          color: AppColors.green,
                                          bg: AppColors.greenDim,
                                          onTap: _saveUpdate,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _ActionButton(
                                          label: 'Out',
                                          color: AppColors.red,
                                          bg: AppColors.redDim,
                                          onTap: _markOut,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$_currentIndex of ${_items.length} reviewed · ~${_items.length - _currentIndex} min to finish',
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(color: color)),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int total;
  final int current;

  const _ProgressBar({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        Color color;
        if (i < current) {
          color = AppColors.green;
        } else if (i == current) {
          color = AppColors.greenDim;
        } else {
          color = AppColors.border;
        }
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClose;
  const _EmptyState({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✅', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('All caught up!', style: AppTextStyles.headingLg),
              const SizedBox(height: 8),
              Text('Everything looks verified 👌',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.background,
                ),
                onPressed: onClose,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneState extends StatelessWidget {
  final VoidCallback onClose;
  const _DoneState({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('Check-in complete!', style: AppTextStyles.headingLg),
              const SizedBox(height: 8),
              Text('Pantry is up to date.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.background,
                ),
                onPressed: onClose,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
