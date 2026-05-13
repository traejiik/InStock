import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/shared/widgets/category_picker.dart';
import 'package:instock/shared/widgets/segment_control.dart';
import 'package:instock/shared/widgets/unit_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/category_divider.dart';
import '../widgets/pantry_item_row.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  int _sortIndex = 0;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final db = ref.watch(appDatabaseProvider);
    final needsCheck = ref.watch(pantryVerificationStatusProvider);
    var items = db.pantryItems;

    if (_search.isNotEmpty) {
      items = items.where((p) {
        final ing = db.ingredientById(p.ingredientId);
        return ing?.canonicalName.toLowerCase().contains(
              _search.toLowerCase(),
            ) ??
            false;
      }).toList();
    }

    if (_sortIndex == 1) {
      items = [...items]
        ..sort((a, b) {
          final ia = db.ingredientById(a.ingredientId)?.canonicalName ?? '';
          final ib = db.ingredientById(b.ingredientId)?.canonicalName ?? '';
          return ia.compareTo(ib);
        });
    } else if (_sortIndex == 2) {
      items = [...items]..sort((a, b) => b.quantity.compareTo(a.quantity));
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Pantry', style: AppTextStyles.displayLg),
                            Text(
                              '${items.length} items',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _CheckInButton(
                      isOverdue: needsCheck,
                      onTap: () => context.push('/pantry/checkin'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _showSearch(),
                      icon: Icon(Icons.search, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            if (kDebugMode)
              SliverToBoxAdapter(
                child: GestureDetector(
                  onLongPress: _handleDebugLongPress,
                  behavior: HitTestBehavior.opaque,
                  child: Container(height: 4, color: Colors.transparent),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: SegmentControl(
                  labels: const ['By Category', 'A–Z', 'Quantity'],
                  selectedIndex: _sortIndex,
                  onChanged: (i) => setState(() => _sortIndex = i),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (items.isEmpty)
              SliverFillRemaining(
                child: _PantryEmptyState(onAdd: () => _showAddSheet(context)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: _sortIndex == 0
                    ? _buildByCategory(db, items)
                    : _buildFlat(db, items),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'pantry_fab',
        onPressed: () => _showAddSheet(context),
        backgroundColor: colors.green,
        foregroundColor: onPrimary,
        elevation: 0,
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }

  void _handleDebugLongPress() {
    if (!kDebugMode) return;
    final colors = AppColors.of(context);
    ref.read(appDatabaseProvider).debugResetVerification();
    ref.invalidate(pantryVerificationStatusProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debug: pantry marked as overdue'),
          backgroundColor: colors.surface3,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSearch() {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface2,
        title: Text('Search Pantry', style: AppTextStyles.headingMd),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: const InputDecoration(hintText: 'Item name...'),
          onChanged: (v) => setState(() => _search = v),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _search = '');
              Navigator.pop(ctx);
            },
            child: Text(
              'Clear',
              style: AppTextStyles.label.copyWith(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Done',
              style: AppTextStyles.label.copyWith(color: colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildByCategory(AppDatabase db, List<PantryItem> items) {
    final grouped = <IngredientCategory, List<PantryItem>>{};
    for (final item in items) {
      final ing = db.ingredientById(item.ingredientId);
      final cat = ing?.category ?? IngredientCategory.custom;
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    final sections = grouped.entries.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final section = sections[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryDivider(category: section.key),
            ...section.value.map((p) => _buildRow(db, p)),
          ],
        );
      }, childCount: sections.length),
    );
  }

  Widget _buildFlat(AppDatabase db, List<PantryItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _buildRow(db, items[i]),
        childCount: items.length,
      ),
    );
  }

  Widget _buildRow(AppDatabase db, PantryItem item) {
    final ing = db.ingredientById(item.ingredientId);
    if (ing == null) return const SizedBox.shrink();
    return PantryItemRow(
      item: item,
      ingredient: ing,
      onTap: () => _showEditSheet(context, item, ing),
      onLongPress: () => _showQuickActions(context, item, ing),
    );
  }

  void _showEditSheet(BuildContext context, PantryItem item, Ingredient ing) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ing.canonicalName, style: AppTextStyles.headingMd),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(labelText: 'Quantity (${item.unit})'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.green,
                  foregroundColor: onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final qty = double.tryParse(qtyCtrl.text) ?? item.quantity;
                  ref
                      .read(appDatabaseProvider)
                      .updatePantryQuantity(item.id, qty);
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Save',
                  style: AppTextStyles.label.copyWith(color: onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(
    BuildContext context,
    PantryItem item,
    Ingredient ing,
  ) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(ing.canonicalName, style: AppTextStyles.headingMd),
            ),
            ListTile(
              leading: Icon(Icons.remove_circle_outline, color: colors.amber),
              title: Text(
                'Quick decrement (−1 ${item.unit})',
                style: AppTextStyles.label,
              ),
              onTap: () {
                ref
                    .read(appDatabaseProvider)
                    .updatePantryQuantity(
                      item.id,
                      (item.quantity - 1).clamp(0.0, double.infinity),
                    );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: colors.red),
              title: Text(
                'Mark as out of stock',
                style: AppTextStyles.label.copyWith(color: colors.red),
              ),
              onTap: () {
                ref.read(appDatabaseProvider).markPantryItemOut(item.id);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    String selectedUnit = 'g';
    var selectedCategory = IngredientCategory.custom;
    String? nameError;
    String? qtyError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          void submit() {
            final name = nameCtrl.text.trim();
            final qty = double.tryParse(qtyCtrl.text);

            setLocal(() {
              nameError = name.length < 2
                  ? 'Name must be at least 2 characters'
                  : null;
              qtyError = (qtyCtrl.text.isEmpty || qty == null || qty <= 0)
                  ? 'Enter a valid quantity greater than 0'
                  : null;
            });

            if (name.length < 2 || qty == null || qty <= 0) return;

            final db = ref.read(appDatabaseProvider);
            final ing = db.findOrCreateIngredient(
              name,
              category: selectedCategory,
            );
            db.addOrIncrementPantry(ing.id, qty, selectedUnit);
            Navigator.pop(ctx);
          }

          void syncCategory(String value) {
            final name = value.trim().toLowerCase();
            if (name.length < 2) return;
            final ing = ref.read(appDatabaseProvider).ingredients.where((i) {
              return i.canonicalName.toLowerCase() == name ||
                  i.aliases.any((alias) => alias.toLowerCase() == name);
            }).firstOrNull;
            if (ing == null) return;
            setLocal(() => selectedCategory = ing.category);
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add to Pantry', style: AppTextStyles.headingMd),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Ingredient name',
                      errorText: nameError,
                    ),
                    onChanged: syncCategory,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      errorText: qtyError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CategoryPicker(
                    selectedCategory: selectedCategory,
                    onChanged: (category) =>
                        setLocal(() => selectedCategory = category),
                  ),
                  const SizedBox(height: 12),
                  UnitPicker(
                    selectedUnit: selectedUnit,
                    onChanged: (u) => setLocal(() => selectedUnit = u),
                    allowCustom: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.green,
                        foregroundColor: onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: submit,
                      child: Text(
                        'Add',
                        style: AppTextStyles.label.copyWith(color: onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PantryEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _PantryEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.package, size: 56, color: colors.textTertiary),
            const SizedBox(height: 20),
            Text('Your pantry is empty', style: AppTextStyles.headingMd),
            const SizedBox(height: 8),
            Text(
              'Add items as you stock up or check off your shopping list',
              style: AppTextStyles.bodyMd.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.green,
                  foregroundColor: onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onAdd,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(
                  'Add Item',
                  style: AppTextStyles.label.copyWith(color: onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInButton extends StatelessWidget {
  final bool isOverdue;
  final VoidCallback onTap;

  const _CheckInButton({required this.isOverdue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isOverdue ? colors.amberDim : colors.surface3,
              shape: BoxShape.circle,
              border: isOverdue
                  ? Border.all(color: colors.amber.withValues(alpha: 0.25))
                  : null,
            ),
            child: Icon(
              LucideIcons.clipboardCheck,
              size: 18,
              color: isOverdue ? colors.amber : colors.textSecondary,
            ),
          ),
          if (isOverdue)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
