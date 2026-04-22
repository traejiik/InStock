import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/shared/widgets/segment_control.dart';
import '../widgets/shopping_list_item.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  int _sortIndex = 0;

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    final items = db.shoppingItems;
    final checkedCount = items.where((i) => i.checked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(total: items.length, inStock: checkedCount)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: SegmentControl(
                  labels: const ['By Category', 'By Recipe', 'All Items'],
                  selectedIndex: _sortIndex,
                  onChanged: (i) => setState(() => _sortIndex = i),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (items.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text('Your shopping list is empty 🛒',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: _buildList(db, items),
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

  Widget _buildList(AppDatabase db, List<ShoppingItem> items) {
    if (_sortIndex == 2) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _buildItem(db, items[i]),
          childCount: items.length,
        ),
      );
    }

    // Group by category or recipe
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final ing = db.ingredientById(item.ingredientId);
      final key = _sortIndex == 0
          ? (ing?.category.label ?? 'Other')
          : (item.sourceRecipeId != null
              ? (db.recipeById(item.sourceRecipeId!)?.title ?? 'Unknown')
              : 'Manual');
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final sections = grouped.entries.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final section = sections[i];
          final ing = db.ingredientById(section.value.first.ingredientId);
          final emoji = _sortIndex == 0
              ? (ing?.category.emoji ?? '📦')
              : '🍽️';
          return _Section(
            emoji: emoji,
            label: section.key,
            items: section.value,
            db: db,
            builder: (item) => _buildItem(db, item),
          );
        },
        childCount: sections.length,
      ),
    );
  }

  Widget _buildItem(AppDatabase db, ShoppingItem item) {
    final ing = db.ingredientById(item.ingredientId);
    if (ing == null) return const SizedBox.shrink();
    final sourceRecipeName = item.sourceRecipeId != null
        ? db.recipeById(item.sourceRecipeId!)?.title
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ShoppingListItem(
        item: item,
        ingredient: ing,
        stockStatus: db.stockStatusForIngredient(item.ingredientId),
        sourceRecipeName: sourceRecipeName,
        onToggle: () => ref.read(appDatabaseProvider).toggleShoppingItem(item.id),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final db = ref.read(appDatabaseProvider);
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    var unit = 'pcs';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Item', style: AppTextStyles.headingMd),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Item name'),
              autofocus: true,
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
                  // Find or create ingredient
                  var ing = db.ingredients.where(
                    (i) => i.canonicalName.toLowerCase() == name.toLowerCase(),
                  ).firstOrNull;
                  if (ing == null) {
                    ing = Ingredient(
                      id: 'ing-${name.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}',
                      canonicalName: name,
                      category: IngredientCategory.custom,
                      aliases: [],
                      createdAt: DateTime.now(),
                    );
                    // Add to state via direct update
                    db.state;
                  }
                  db.addShoppingItem(
                    ingredientId: ing.id,
                    quantity: qty,
                    unit: unit,
                  );
                  Navigator.pop(ctx);
                },
                child: Text('Add to List', style: AppTextStyles.label.copyWith(color: AppColors.background)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final int inStock;

  const _Header({required this.total, required this.inStock});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shopping', style: AppTextStyles.displayLg),
          const SizedBox(height: 4),
          Text(
            '$total items · $inStock checked off',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String emoji;
  final String label;
  final List<ShoppingItem> items;
  final AppDatabase db;
  final Widget Function(ShoppingItem) builder;

  const _Section({
    required this.emoji,
    required this.label,
    required this.items,
    required this.db,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text('$emoji ', style: const TextStyle(fontSize: 16)),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${items.length}', style: AppTextStyles.caption),
              ),
            ],
          ),
        ),
        ...items.map(builder),
      ],
    );
  }
}
