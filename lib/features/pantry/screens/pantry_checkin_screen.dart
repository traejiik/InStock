import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';

class PantryCheckinScreen extends ConsumerStatefulWidget {
  const PantryCheckinScreen({super.key});

  @override
  ConsumerState<PantryCheckinScreen> createState() =>
      _PantryCheckinScreenState();
}

class _PantryCheckinScreenState extends ConsumerState<PantryCheckinScreen>
    with SingleTickerProviderStateMixin {
  List<PantryItem> _items = [];
  List<Ingredient> _ingredients = [];
  int _currentIndex = 0;
  int _verifiedCount = 0;
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
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

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

  // Advance to next item after a verified action (stillGood / saveUpdate / markOut).
  void _advance() {
    if (_currentIndex + 1 >= _items.length) {
      setState(() {
        _verifiedCount++;
        _isDone = true;
      });
    } else {
      setState(() {
        _verifiedCount++;
        _currentIndex++;
        _showUpdate = false;
        _slideCtrl.reset();
      });
    }
  }

  // Skip current item without updating lastVerifiedAt; progress bar does not fill.
  void _skip() {
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
    final colors = AppColors.of(context);
    if (_items.isEmpty) {
      return _EmptyState(onClose: () => Navigator.pop(context));
    }

    if (_isDone) {
      return _DoneState(
        verifiedCount: _verifiedCount,
        totalCount: _items.length,
        onClose: () => Navigator.pop(context),
      );
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
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: colors.textSecondary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Check-in', style: AppTextStyles.headingMd),
            Text(
              '${_items.length} items to review',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _ProgressBar(total: _items.length, verified: _verifiedCount),
              const SizedBox(height: 28),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dismissible handles left-swipe-to-skip with built-in animation.
                    Dismissible(
                      key: ValueKey('checkin-$_currentIndex'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _skip(),
                      background: const SizedBox.shrink(),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: colors.surface3,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 28),
                        child: Icon(
                          Icons.skip_next_rounded,
                          color: colors.textSecondary,
                          size: 28,
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              ing.category.emoji,
                              style: const TextStyle(fontSize: 56),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ing.canonicalName,
                              style: AppTextStyles.headingLg,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            if (daysAgo != null)
                              Text(
                                'Last verified: ${daysAgo == 0 ? 'today' : '$daysAgo days ago'}',
                                style: AppTextStyles.caption,
                              ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface3,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Recorded: ${item.quantity} ${item.unit}',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!_showUpdate) ...[
                              Text(
                                'Still accurate?',
                                style: AppTextStyles.label.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      label: '✓ Still good',
                                      color: colors.green,
                                      bg: colors.greenDim,
                                      onTap: _stillGood,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ActionButton(
                                      label: '✎ Update',
                                      color: colors.textPrimary,
                                      bg: colors.surface3,
                                      onTap: _showUpdatePanel,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '← Swipe left to skip',
                                style: AppTextStyles.caption.copyWith(
                                  color: colors.textTertiary,
                                ),
                              ),
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
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        labelText:
                                            'New quantity (${item.unit})',
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _ActionButton(
                                            label: 'Save & Next →',
                                            color: colors.green,
                                            bg: colors.greenDim,
                                            onTap: _saveUpdate,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _ActionButton(
                                            label: 'Out',
                                            color: colors.red,
                                            bg: colors.redDim,
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$_verifiedCount of ${_items.length} verified · ~${_items.length - _currentIndex} remaining',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textTertiary,
                ),
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
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(color: color),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int total;
  final int verified;

  const _ProgressBar({required this.total, required this.verified});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: List.generate(total, (i) {
        final color = i < verified ? colors.green : colors.border;
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
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✅', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('All caught up!', style: AppTextStyles.headingLg),
              const SizedBox(height: 8),
              Text(
                'Everything looks verified 👌',
                style: AppTextStyles.bodyMd.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.green,
                  foregroundColor: onPrimary,
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
  final int verifiedCount;
  final int totalCount;
  final VoidCallback onClose;

  const _DoneState({
    required this.verifiedCount,
    required this.totalCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final isPartial = verifiedCount < totalCount;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isPartial ? '👍' : '🎉',
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 16),
              Text('Check-in complete!', style: AppTextStyles.headingLg),
              const SizedBox(height: 8),
              Text(
                isPartial
                    ? '$verifiedCount of $totalCount items verified'
                    : 'Pantry is up to date.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.green,
                  foregroundColor: onPrimary,
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
