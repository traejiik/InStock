import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/shared/widgets/segment_control.dart';
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
    final db = ref.watch(appDatabaseProvider);
    final needsCheck = ref.watch(pantryVerificationStatusProvider);
    var items = db.pantryItems;

    if (_search.isNotEmpty) {
      items = items.where((p) {
        final ing = db.ingredientById(p.ingredientId);
        return ing?.canonicalName.toLowerCase().contains(_search.toLowerCase()) ?? false;
      }).toList();
    }

    if (_sortIndex == 1) {
      items = [...items]..sort((a, b) {
          final ia = db.ingredientById(a.ingredientId)?.canonicalName ?? '';
          final ib = db.ingredientById(b.ingredientId)?.canonicalName ?? '';
          return ia.compareTo(ib);
        });
    } else if (_sortIndex == 2) {
      items = [...items]..sort((a, b) => b.quantity.compareTo(a.quantity));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pantry', style: AppTextStyles.displayLg),
                          Text(
                            '${items.length} items',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showSearch(),
                      icon: const Icon(Icons.search, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            if (needsCheck)
              SliverToBoxAdapter(child: _VerificationBanner(onTap: () => context.push('/pantry/checkin'))),
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
                child: Center(
                  child: Text('No pantry items yet 🥦',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                ),
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
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.background,
        elevation: 0,
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }

  void _showSearch() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Search Pantry', style: AppTextStyles.headingMd),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Item name...'),
          onChanged: (v) => setState(() => _search = v),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _search = '');
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done', style: AppTextStyles.label.copyWith(color: AppColors.green)),
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
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final section = sections[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryDivider(category: section.key),
              ...section.value.map((p) => _buildRow(db, p)),
            ],
          );
        },
        childCount: sections.length,
      ),
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
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
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
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Quantity (${item.unit})',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final qty = double.tryParse(qtyCtrl.text) ?? item.quantity;
                  ref.read(appDatabaseProvider).updatePantryQuantity(item.id, qty);
                  Navigator.pop(ctx);
                },
                child: Text('Save', style: AppTextStyles.label.copyWith(color: AppColors.background)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, PantryItem item, Ingredient ing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(ing.canonicalName, style: AppTextStyles.headingMd),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: AppColors.amber),
              title: Text('Quick decrement (−1 ${item.unit})',
                  style: AppTextStyles.label),
              onTap: () {
                ref.read(appDatabaseProvider).updatePantryQuantity(
                    item.id, (item.quantity - 1).clamp(0.0, double.infinity));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.red),
              title: Text('Mark as out of stock',
                  style: AppTextStyles.label.copyWith(color: AppColors.red)),
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
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    var unit = 'pcs';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to Pantry', style: AppTextStyles.headingMd),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Ingredient name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (v) => unit = v,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(labelText: 'Unit', hintText: unit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
                  final db = ref.read(appDatabaseProvider);
                  var ing = db.ingredients.where(
                    (i) => i.canonicalName.toLowerCase() == name.toLowerCase(),
                  ).firstOrNull;
                  ing ??= Ingredient(
                    id: 'ing-${name.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}',
                    canonicalName: name,
                    category: IngredientCategory.custom,
                    aliases: [],
                    createdAt: DateTime.now(),
                  );
                  db.addOrIncrementPantry(ing.id, qty, unit);
                  Navigator.pop(ctx);
                },
                child: Text('Add', style: AppTextStyles.label.copyWith(color: AppColors.background)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _VerificationBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.amberDim,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.amber),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Some items haven\'t been verified in a while',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.amber),
                ),
              ),
              Text('Quick check-in →',
                  style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.amber, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
